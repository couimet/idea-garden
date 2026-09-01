#!/usr/bin/env bash
# Shared test helper for bats test suites. Source via: load test_helper
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PROJECT_ROOT

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
}

teardown() {
  rm -rf "${TEST_TEMP_DIR:?}"
}
