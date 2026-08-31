#!/usr/bin/env bats

load test_helper

SCRIPT="$PROJECT_ROOT/.github/actions/lychee-check/run.sh"

# A mock lychee that records each argument on its own line, so tests can assert
# the exact flags and paths run.sh passes through.
setup_lychee_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/lychee" <<'LYCHEE'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "${TEST_TEMP_DIR}/lychee.log"
LYCHEE
  chmod +x "${TEST_TEMP_DIR}/bin/lychee"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

@test "run.sh passes the private-network exclusion flag to lychee" {
  setup_lychee_mock
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "--exclude-all-private" "${TEST_TEMP_DIR}/lychee.log"
}

@test "run.sh preserves the hidden and no-progress flags" {
  setup_lychee_mock
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "--hidden" "${TEST_TEMP_DIR}/lychee.log"
  grep -qxF -- "--no-progress" "${TEST_TEMP_DIR}/lychee.log"
}

@test "run.sh defaults to **/*.md when PATHS is unset" {
  setup_lychee_mock
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "**/*.md" "${TEST_TEMP_DIR}/lychee.log"
}

@test "run.sh passes each PATHS entry through to lychee" {
  setup_lychee_mock
  run env PATHS="README.md docs/standards/README.md" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "README.md" "${TEST_TEMP_DIR}/lychee.log"
  grep -qxF -- "docs/standards/README.md" "${TEST_TEMP_DIR}/lychee.log"
}
