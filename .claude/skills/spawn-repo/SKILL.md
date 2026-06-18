# Spawn Repo

Create a new GitHub repo from an idea-garden issue, hand off a self-contained agent brief, and re-home tracking into the new repo while keeping the idea-garden seed.

**Trigger:** When an issue's implementation plan says to create a new repo. The user invokes `/spawn-repo <repo-name>`.

## Pre-conditions

- Must be on an `issues/<ID>` branch in idea-garden
- `.claude-work/issues/<ID>/HANDOFF.md` must exist — the self-contained brief a fresh agent reads cold in the new repo. Build it from `handoff-template.md` in this skill dir. See "The handoff brief" below.
- User must have `gh` CLI authenticated

## The handoff brief (HANDOFF.md)

The spawned repo only receives `.claude-work/issues/<ID>/`; it does NOT get the idea-garden notes or questions files, and links to idea-garden GitHub comments may not resolve from inside the new repo. So `HANDOFF.md` must be **self-contained**: inline the decisions, design, data model, constraints, open items, and any verbatim external facts the next agent needs. `handoff-template.md` is the reusable scaffold. The script refuses to spawn if `HANDOFF.md` is missing.

## Before the script

Before running the script, the agent must generate `.claude-work/issues/<ID>/HANDOFF.md` from `handoff-template.md` in this skill directory. Fill every `{{PLACEHOLDER}}`, delete every `<!--` guidance comment, and re-read the file cold to confirm no placeholders remain. The script refuses to spawn if HANDOFF.md is missing or still contains unreplaced placeholders.

## What it does

Runs `.claude/skills/spawn-repo/spawn-repo.sh` which:

1. Creates the repo on GitHub (skips if it already exists)
2. Clones it as a sibling directory (skips if `../<name>/` already exists)
3. Opens a fresh **tracking issue in the new repo**, titled from the seed issue and cross-linked back to the idea-garden seed (idempotent: a hidden `spawned-from` marker in the body lets re-runs reuse it)
4. Copies `.claude-work/issues/<seed-ID>/` into the new repo **re-keyed to the new repo's own issue number** (`.claude-work/issues/<dest-ID>/`), so destination branches and working dirs key to a number that is meaningful there
5. Prepends a bootstrap banner to the new repo's README pointing at the seed, the new tracking issue, and `.claude-work/issues/<dest-ID>/HANDOFF.md`
6. Commits and pushes the working docs and README in the new repo so the "self-contained repo" promise is actually true for anyone cloning from GitHub
7. Posts a handoff comment on the idea-garden seed issue pointing forward to the new repo and its tracking issue
8. Closes the idea-garden seed issue (`completed`), keeping it as a permanent, redirecting seed

The git operations (issue create, comment, close) are idempotent, but the copy step overwrites. The script is safe to re-run before the new-repo agent starts editing `.claude-work/`; do not re-run after downstream work begins.

## Issue organization

The idea-garden issue stays as the permanent **seed** (closed, pointing forward); the new repo gets its **own** fresh tracking issue, cross-linked both ways. The garden keeps the idea; implementation tracks where the code lives; branch names in the new repo stay sane because they key to that repo's own issue number.

## Input

The skill receives the repo name as its argument. Optional flags:

- `--private` — create a private repo (default is public)
- `--description <text>` — set the repo description

## After the skill

The script prints a "Done" message with paths (including the new tracking issue and the handoff brief) and tells the user to open a new workspace. **The skill always stops here.** Do not continue implementing in the same session. The new repo is self-contained: it has the code, its own tracking issue, the re-keyed `.claude-work/`, the `HANDOFF.md` brief, and a README bootstrap banner pointing to all of it.
