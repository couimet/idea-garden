# idea-garden

A low-friction inbox for rough ideas. When an idea matures into real work, it either moves to an existing repo or spawns a new one.

## Spawning new repos from issues

When an issue's implementation plan creates a new repo, invoke `/spawn-repo <name>`. The skill handles repo creation, cloning, working-doc copy, README banner, and the handoff comment. See `.claude/skills/spawn-repo/SKILL.md` for the full workflow.
