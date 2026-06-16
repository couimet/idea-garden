#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage: spawn-repo.sh <repo-name> [--private] [--description <desc>]

Creates a new GitHub repo under couimet, clones it as a sibling directory,
copies the current issue's .claude-work/ docs into it, prepends a bootstrap
banner to its README, and posts a handoff comment on the parent issue.

Run from the idea-garden repo root, on an issues/<ID> branch.
EOF
  exit "${1:-1}"
}

banner() {
  local issue_url="$1"
  cat <<EOF
<!-- Remove this banner once the repo has real documentation. -->
> [!NOTE]
> Bootstrapped from [${issue_url}](${issue_url}).
> Active plan: \`.claude-work/issues/${ISSUE_ID}/active-plan\`
EOF
}

# --- args ------------------------------------------------------------------

REPO_NAME=""
VISIBILITY="--public"
DESCRIPTION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --private) VISIBILITY="--private"; shift ;;
    --description) [[ -z "${2:-}" ]] && { echo "Error: --description requires a value" >&2; exit 1; }; DESCRIPTION="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) [[ -n "$REPO_NAME" ]] && { echo "Error: unexpected argument '$1' (REPO_NAME already set)" >&2; exit 1; }; REPO_NAME="$1"; shift ;;
  esac
done

[[ -z "$REPO_NAME" ]] && usage

# --- detect issue context --------------------------------------------------

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" =~ ^issues/([0-9]+) ]]; then
  ISSUE_ID="${BASH_REMATCH[1]}"
else
  echo "Error: not on an issues/<ID> branch (current: $BRANCH)" >&2
  exit 1
fi

ISSUE_URL="https://github.com/couimet/idea-garden/issues/${ISSUE_ID}"
WORKDOCS=".claude-work/issues/${ISSUE_ID}"
[[ -d "$WORKDOCS" ]] || { echo "Error: $WORKDOCS not found" >&2; exit 1; }

# --- create repo (skip if exists) ------------------------------------------

echo "=== Creating repo: couimet/${REPO_NAME} (${VISIBILITY}) ==="
if gh repo view "couimet/${REPO_NAME}" &>/dev/null; then
  echo "Repo already exists, skipping creation."
else
  if [[ -n "$DESCRIPTION" ]]; then
    gh repo create "couimet/${REPO_NAME}" $VISIBILITY --description "$DESCRIPTION"
  else
    gh repo create "couimet/${REPO_NAME}" $VISIBILITY
  fi
fi

# --- clone as sibling ------------------------------------------------------

if [[ "$REPO_NAME" == "idea-garden" ]]; then
  echo "Error: refusing to spawn 'idea-garden' (this is the source repo)" >&2
  exit 1
fi

TARGET="../${REPO_NAME}"
if [[ -d "$TARGET" ]]; then
  echo "Local clone already exists at ${TARGET}, skipping clone."
else
  echo "=== Cloning into ${TARGET} ==="
  git clone "https://github.com/couimet/${REPO_NAME}.git" "$TARGET"
fi

# --- copy working docs -----------------------------------------------------

echo "=== Copying ${WORKDOCS} ==="
mkdir -p "${TARGET}/.claude-work/issues/${ISSUE_ID}"
cp -r "${WORKDOCS}/" "${TARGET}/.claude-work/issues/${ISSUE_ID}/"

# --- banner README ---------------------------------------------------------

README="${TARGET}/README.md"
BANNER=$(banner "$ISSUE_URL")
if grep -qF '<!-- Remove this banner' "$README" 2>/dev/null; then
  echo "Banner already present, skipping."
elif [[ -f "$README" ]]; then
  printf '%s\n\n%s\n' "$BANNER" "$(cat "$README")" > "$README"
else
  echo "$BANNER" > "$README"
fi

# --- comment on parent issue -----------------------------------------------

COMMENT="Repo created at https://github.com/couimet/${REPO_NAME}. Working docs copied to \`.claude-work/issues/${ISSUE_ID}/\`. Continue work from that repo."
echo "=== Posting handoff comment ==="
if gh api "repos/couimet/idea-garden/issues/${ISSUE_ID}/comments" --jq '.[].body' 2>/dev/null | grep -qF "Repo created at https://github.com/couimet/${REPO_NAME}"; then
  echo "Handoff comment already posted, skipping."
else
  gh issue comment "$ISSUE_ID" --repo couimet/idea-garden --body "$COMMENT"
fi

# --- done ------------------------------------------------------------------

echo
echo "=== Done ==="
echo "Repo:    https://github.com/couimet/${REPO_NAME}"
echo "Local:   ${TARGET}"
echo "Docs:    ${TARGET}/.claude-work/issues/${ISSUE_ID}/"
echo
echo "Open a new workspace at ${TARGET} to continue."
