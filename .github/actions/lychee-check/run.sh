#!/usr/bin/env bash
set -euo pipefail

# Run lychee on the given paths.
#
# Inputs (env):
#   PATHS              space-separated paths or globs to check (default: **/*.md)
#   WORKING_DIRECTORY  directory to run in (default: .)

cd "${WORKING_DIRECTORY:-.}"

# Keep globs unexpanded: quoted array expansion prevents shell globbing, and
# lychee resolves ** globs itself.
IFS=' ' read -r -a PATH_ARGS <<< "${PATHS:-**/*.md}"

# --hidden: lychee skips hidden directories by default; include them so
# markdown under .github/ and .claude/ is covered by ** globs.
lychee --hidden --no-progress "${PATH_ARGS[@]}"
