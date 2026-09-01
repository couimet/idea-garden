#!/usr/bin/env bash
set -euo pipefail

# Install lychee at a pinned version by downloading the prebuilt binary from
# the lycheeverse/lychee release assets. Incubated in idea-garden; on migration
# to couimet/github-actions, version tracking moves to a package.json and this
# script reads it, matching the markdownlint and prettier actions.

if [[ -z "${LYCHEE_VERSION:-}" ]]; then
  echo "ERROR: LYCHEE_VERSION is required" >&2
  exit 1
fi

# Normalize to the release tag format (lychee tags are lychee-vX.Y.Z).
RAW_VERSION="${LYCHEE_VERSION#lychee-}"
RAW_VERSION="${RAW_VERSION#v}"
VERSION="lychee-v${RAW_VERSION}"

case "$(uname -s)" in
  Linux)
    OS_TARGET="unknown-linux-gnu"
    ;;
  Darwin)
    OS_TARGET="apple-darwin"
    ;;
  *)
    echo "ERROR: unsupported OS '$(uname -s)'" >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64 | amd64)
    ARCH="x86_64"
    ;;
  aarch64 | arm64)
    ARCH="aarch64"
    ;;
  *)
    echo "ERROR: unsupported architecture '$(uname -m)'" >&2
    exit 1
    ;;
esac

TARGET="${ARCH}-${OS_TARGET}"
TARBALL="lychee-${TARGET}.tar.gz"
URL="https://github.com/lycheeverse/lychee/releases/download/${VERSION}/${TARBALL}"

# Prefer the runner tool cache (GitHub Actions); fall back to /tmp when run
# outside CI, e.g. during local verification.
INSTALL_DIR="${LYCHEE_INSTALL_DIR:-"${RUNNER_TOOL_CACHE:-/tmp}/lychee/${VERSION}"}"
mkdir -p "${INSTALL_DIR}"

# Download into a unique temp dir so a pre-created /tmp path cannot be
# substituted, and remove it on every exit.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# macOS lacks sha256sum; shasum -a 256 is its portable equivalent.
verify_checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$1"
  else
    echo "ERROR: no sha256 checksum tool found (need sha256sum or shasum)" >&2
    return 1
  fi
}

curl -fsSL --connect-timeout 10 --max-time 60 "${URL}" -o "${TMP_DIR}/${TARBALL}"
curl -fsSL --connect-timeout 10 --max-time 60 "${URL}.sha256" -o "${TMP_DIR}/${TARBALL}.sha256"

# The .sha256 asset names the archive by basename, so verify from TMP_DIR.
(cd "${TMP_DIR}" && verify_checksum "${TARBALL}.sha256")

tar -xzf "${TMP_DIR}/${TARBALL}" -C "${INSTALL_DIR}"

# The release tarball nests the binary under a target-named directory.
BIN_DIR="${INSTALL_DIR}/lychee-${TARGET}"
if [[ ! -x "${BIN_DIR}/lychee" ]]; then
  echo "ERROR: lychee binary not found at ${BIN_DIR}/lychee" >&2
  exit 1
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${BIN_DIR}" >> "${GITHUB_PATH}"
fi
