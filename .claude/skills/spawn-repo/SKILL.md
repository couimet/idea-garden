# Spawn Repo

Create a new GitHub repo from an idea-garden issue, copy working docs, and hand off.

**Trigger:** When an issue's implementation plan says to create a new repo. The user invokes `/spawn-repo <repo-name>`.

## Pre-conditions

- Must be on an `issues/<ID>` branch in idea-garden
- `.claude-work/issues/<ID>/` must exist (populated by /start-issue or /note)
- User must have `gh` CLI authenticated

## What it does

Runs `.claude/skills/spawn-repo/spawn-repo.sh` which:

1. Creates the repo on GitHub (`gh repo create couimet/<name>`)
2. Clones it as a sibling directory (`../<name>/`)
3. Copies `.claude-work/issues/<ID>/` into the new repo
4. Prepends a bootstrap banner to the new repo's README
5. Posts a handoff comment on the idea-garden issue

## Input

The skill receives the repo name as its argument. Optional flags:

- `--private` — create a private repo (default is public)
- `--description <text>` — set the repo description

## After the skill

The script prints a "Done" message with paths and tells the user to open a new workspace. **The skill always stops here.** Do not continue implementing in the same session. The new repo is self-contained: it has the code, the plan (via `.claude-work/`), and a README bootstrap banner pointing to the active plan.
