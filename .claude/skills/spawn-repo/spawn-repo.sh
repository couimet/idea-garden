#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage: spawn-repo.sh <repo-name> [--private] [--description <desc>]

Creates a new GitHub repo under couimet, clones it as a sibling directory,
opens a fresh tracking issue in the new repo (cross-linked to the idea-garden
seed issue), copies the current issue's .claude-work/ docs into it RE-KEYED to
the new repo's own issue number, prepends a bootstrap banner pointing at the
handoff brief, posts a handoff comment on the idea-garden seed issue, and closes
that seed issue pointing forward.

Pre-conditions:
  - run from the idea-garden repo root, on an issues/<ID> branch
  - .claude-work/issues/<ID>/HANDOFF.md must exist (the agent handoff brief)
EOF
  exit "${1:-1}"
}

banner() {
  local seed_url="$1" dest_issue_url="$2" dest_id="$3"
  cat <<EOF
<!-- Remove this banner once the repo has real documentation. -->
> [!NOTE]
> Bootstrapped from ${seed_url}
> Tracking issue: ${dest_issue_url}
>
> **Copy-paste this into a Claude Code session in this repo:**
>
>     /start-issue ${dest_id}
>
>     Before writing any code, review \`.claude-work/issues/${dest_id}/HANDOFF.md\`
>     closely and integrate it into the implementation plan. It contains
>     all locked decisions, the target design, data model, constraints,
>     and verbatim external facts this project depends on.
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

if [[ "$REPO_NAME" == "idea-garden" ]]; then
  echo "Error: refusing to spawn 'idea-garden' (this is the source repo)" >&2
  exit 1
fi

# --- detect issue context --------------------------------------------------
# Guard: ensure we are running in the correct repository before mutating anything.
if ! git remote get-url origin | grep -qE 'github\.com[:/]couimet/idea-garden'; then
  echo "Error: this script must run from couimet/idea-garden" >&2
  exit 1
fi

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" =~ ^issues/([0-9]+)$ ]]; then
  SEED_ID="${BASH_REMATCH[1]}"
else
  echo "Error: not on an issues/<ID> branch (current: $BRANCH)" >&2
  exit 1
fi

SEED_URL="https://github.com/couimet/idea-garden/issues/${SEED_ID}"
WORKDOCS=".claude-work/issues/${SEED_ID}"
[[ -d "$WORKDOCS" ]] || { echo "Error: $WORKDOCS not found" >&2; exit 1; }
# Handoff brief is the required agent entry point (see handoff-template.md).
[[ -f "${WORKDOCS}/HANDOFF.md" ]] || { echo "Error: ${WORKDOCS}/HANDOFF.md not found (create it from handoff-template.md before spawning)" >&2; exit 1; }
if grep -qE '\{\{' "${WORKDOCS}/HANDOFF.md"; then
  echo "Error: ${WORKDOCS}/HANDOFF.md contains unreplaced {{...}} placeholders. Fill every placeholder before spawning." >&2
  exit 1
fi

SEED_TITLE=$(gh issue view "$SEED_ID" --repo couimet/idea-garden --json title -q .title)

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

TARGET="../${REPO_NAME}"
if [[ -d "$TARGET" ]]; then
  echo "Local clone already exists at ${TARGET}, skipping clone."
else
  echo "=== Cloning into ${TARGET} ==="
  git clone "https://github.com/couimet/${REPO_NAME}.git" "$TARGET"
fi

# --- create (or reuse) the fresh tracking issue in the new repo ------------
# Strategy C: idea-garden keeps the seed; the new repo gets its own native issue
# so branches and working dirs key to a number that is meaningful HERE. The body
# carries a hidden marker so re-runs reuse the same issue (idempotent).

SPAWN_MARKER="<!-- spawned-from: idea-garden#${SEED_ID} -->"
echo "=== Resolving tracking issue in couimet/${REPO_NAME} ==="
DEST_ID=$(gh issue list --repo "couimet/${REPO_NAME}" --state all --json number,body \
  --jq "map(select(.body | contains(\"${SPAWN_MARKER}\"))) | (.[0].number // empty)")

if [[ -n "$DEST_ID" ]]; then
  echo "Tracking issue already exists: #${DEST_ID}, reusing."
  DEST_ISSUE_URL="https://github.com/couimet/${REPO_NAME}/issues/${DEST_ID}"
else
  DEST_BODY=$(cat <<EOF
Spawned from an idea captured in idea-garden: ${SEED_URL}

**To the agent running /start-issue on this issue:** before creating an implementation plan, read \`.claude-work/issues/<this issue number>/HANDOFF.md\` closely. It is the authoritative source — all locked decisions, the target design, data model, constraints, and verbatim external facts (CodeRabbit Q&A, rate-limit comment format sample) live there. Integrate them into the plan.

${SPAWN_MARKER}
EOF
)
  DEST_ISSUE_URL=$(gh issue create --repo "couimet/${REPO_NAME}" --title "$SEED_TITLE" --body "$DEST_BODY")
  [[ -n "$DEST_ISSUE_URL" ]] || { echo "Error: failed to create the destination issue" >&2; exit 1; }
  DEST_ID=$(gh issue view "$DEST_ISSUE_URL" --repo "couimet/${REPO_NAME}" --json number -q .number)
  echo "Created tracking issue #${DEST_ID}."
fi

# --- copy working docs, RE-KEYED to the destination issue number -----------
# The git operations (issue create, comment, close) are idempotent, but this
# copy step overwrites, so re-running after the new-repo agent has started
# editing .claude-work/ will silently clobber the agent's changes. Only re-run
# before downstream work begins.

DEST_WORKDOCS="${TARGET}/.claude-work/issues/${DEST_ID}"
echo "=== Copying ${WORKDOCS} -> ${DEST_WORKDOCS} (re-keyed to #${DEST_ID}) ==="
mkdir -p "$DEST_WORKDOCS"
cp -r "${WORKDOCS}/." "$DEST_WORKDOCS/"

# --- banner README ---------------------------------------------------------

README="${TARGET}/README.md"
BANNER=$(banner "$SEED_URL" "$DEST_ISSUE_URL" "$DEST_ID")
if grep -qF '<!-- Remove this banner' "$README" 2>/dev/null; then
  echo "Banner already present, skipping."
elif [[ -f "$README" ]]; then
  printf '%s\n\n%s\n' "$BANNER" "$(cat "$README")" > "$README"
else
  echo "$BANNER" > "$README"
fi

# --- commit and push the working docs + README in the new repo --------------

echo "=== Committing and pushing working docs in ${TARGET} ==="
(
  cd "$TARGET"
  if ! git rev-parse --quiet --verify HEAD >/dev/null; then
    echo "No commits yet in destination repo; creating initial commit."
  fi
  git add .claude-work/ README.md
  if git diff --cached --quiet; then
    echo "No changes to commit (docs already committed), skipping push."
  else
    git commit -m "[chore] Bootstrap: handoff brief and issue docs from ${SEED_URL}"
    git push origin HEAD
  fi
)

# --- handoff comment on the idea-garden seed issue (forward pointer) --------

COMMENT="Spawned to https://github.com/couimet/${REPO_NAME}. Tracking continues in ${DEST_ISSUE_URL}. Agent handoff brief copied to that repo at \`.claude-work/issues/${DEST_ID}/HANDOFF.md\`."
echo "=== Posting handoff comment on seed issue ==="
if gh api "repos/couimet/idea-garden/issues/${SEED_ID}/comments" --paginate --jq '.[].body' 2>/dev/null | grep -qF "Spawned to https://github.com/couimet/${REPO_NAME}"; then
  echo "Handoff comment already posted, skipping."
else
  gh issue comment "$SEED_ID" --repo couimet/idea-garden --body "$COMMENT"
fi

# --- close the seed issue, pointing forward (idempotent) -------------------

SEED_STATE=$(gh issue view "$SEED_ID" --repo couimet/idea-garden --json state -q .state)
if [[ "$SEED_STATE" == "OPEN" ]]; then
  echo "=== Closing seed issue #${SEED_ID} (spawned) ==="
  gh issue close "$SEED_ID" --repo couimet/idea-garden --reason completed
else
  echo "Seed issue already closed, skipping."
fi

# --- done ------------------------------------------------------------------

echo
echo "=== Done ==="
echo "Repo:           https://github.com/couimet/${REPO_NAME}"
echo "Clone:          git clone https://github.com/couimet/${REPO_NAME}.git"
echo "Local:          ${TARGET}"
echo "Tracking issue: ${DEST_ISSUE_URL}"
echo "Handoff brief:  ${DEST_WORKDOCS}/HANDOFF.md"
echo
echo "Open a new workspace at ${TARGET} to continue. Start from the handoff brief."
