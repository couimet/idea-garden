#!/usr/bin/env bats

load test_helper

SCRIPT="$PROJECT_ROOT/.github/actions/lychee-check/install.sh"
TARGET="x86_64-unknown-linux-gnu"
TARBALL="lychee-${TARGET}.tar.gz"
EXPECTED_URL="https://github.com/lycheeverse/lychee/releases/download/lychee-v0.24.2/${TARBALL}"

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  export LYCHEE_VERSION="v0.24.2"
  export LYCHEE_INSTALL_DIR="${TEST_TEMP_DIR}/install"
  export GITHUB_PATH="${TEST_TEMP_DIR}/github_path"
  # Point mktemp at a known dir so the EXIT-trap cleanup is assertable.
  export TMPDIR="${TEST_TEMP_DIR}/tmp"
  mkdir -p "${TMPDIR}"

  setup_uname_mock "Linux" "x86_64"
  setup_fixture
  setup_curl_mock
}

teardown() {
  rm -rf "${TEST_TEMP_DIR:?}"
}

# Forces a deterministic target so the tests pass on any runner.
setup_uname_mock() {
  local os="$1" arch="$2"
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/uname" <<EOF
#!/usr/bin/env bash
case "\$1" in
  -s) echo "${os}" ;;
  -m) echo "${arch}" ;;
  *) /usr/bin/uname "\$@" ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/uname"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Builds a real fixture tarball plus a matching sha256 file that the curl mock
# serves, so the script's checksum verification runs against real hashes.
setup_fixture() {
  local src="${TEST_TEMP_DIR}/fixture-src"
  local bin_dir="${src}/lychee-${TARGET}"
  mkdir -p "${bin_dir}"
  printf '#!/usr/bin/env bash\necho "lychee mock"\n' > "${bin_dir}/lychee"
  chmod +x "${bin_dir}/lychee"
  tar -czf "${TEST_TEMP_DIR}/fixture.tar.gz" -C "${src}" "lychee-${TARGET}"

  local hash
  if command -v sha256sum >/dev/null 2>&1; then
    hash="$(sha256sum "${TEST_TEMP_DIR}/fixture.tar.gz" | awk '{print $1}')"
  else
    hash="$(shasum -a 256 "${TEST_TEMP_DIR}/fixture.tar.gz" | awk '{print $1}')"
  fi
  printf '%s  %s\n' "${hash}" "${TARBALL}" > "${TEST_TEMP_DIR}/fixture.sha256"
}

# Logs each requested URL and -o target, then serves the fixture files.
setup_curl_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/curl" <<'CURL'
#!/usr/bin/env bash
url=""
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    --connect-timeout | --max-time) shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
[ -n "$url" ] || exit 2
echo "$url -> $out" >> "${TEST_TEMP_DIR}/curl.log"
case "$url" in
  *.sha256) cp "${TEST_TEMP_DIR}/fixture.sha256" "$out" ;;
  *)        cp "${TEST_TEMP_DIR}/fixture.tar.gz" "$out" ;;
esac
CURL
  chmod +x "${TEST_TEMP_DIR}/bin/curl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

@test "LYCHEE_VERSION unset: exits with an error" {
  run env -u LYCHEE_VERSION bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"LYCHEE_VERSION"* ]]
}

@test "LYCHEE_VERSION empty: exits with an error" {
  run env LYCHEE_VERSION="" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"LYCHEE_VERSION"* ]]
}

@test "unsupported OS: exits with an error" {
  setup_uname_mock "Plan9" "x86_64"
  run env LYCHEE_VERSION=v0.24.2 bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported OS"* ]]
}

@test "unsupported architecture: exits with an error" {
  setup_uname_mock "Linux" "mips"
  run env LYCHEE_VERSION=v0.24.2 bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported architecture"* ]]
}

@test "happy path: downloads tarball and checksum, verifies, installs, appends GITHUB_PATH" {
  run env LYCHEE_VERSION=v0.24.2 bash "$SCRIPT"
  [ "$status" -eq 0 ]

  grep -qF "${EXPECTED_URL}" "${TEST_TEMP_DIR}/curl.log"
  grep -qF "${EXPECTED_URL}.sha256" "${TEST_TEMP_DIR}/curl.log"

  [ -x "${LYCHEE_INSTALL_DIR}/lychee-${TARGET}/lychee" ]
  [ "$(cat "${GITHUB_PATH}")" = "${LYCHEE_INSTALL_DIR}/lychee-${TARGET}" ]
  [ -z "$(find "${TMPDIR}" -mindepth 1 2>/dev/null)" ]
}

@test "version normalization: strips v and lychee- prefixes from LYCHEE_VERSION" {
  run env LYCHEE_VERSION=lychee-v0.24.2 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "${EXPECTED_URL}" "${TEST_TEMP_DIR}/curl.log"
}

@test "checksum mismatch: aborts, installs nothing, and cleans up the temp dir" {
  printf '0000000000000000000000000000000000000000000000000000000000000000  %s\n' "$TARBALL" > "${TEST_TEMP_DIR}/fixture.sha256"
  run env LYCHEE_VERSION=v0.24.2 bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [ ! -e "${LYCHEE_INSTALL_DIR}/lychee-${TARGET}/lychee" ]
  [ -z "$(find "${TMPDIR}" -mindepth 1 2>/dev/null)" ]
}
