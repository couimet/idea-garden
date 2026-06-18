<!--
HANDOFF.md template for spawn-repo.

Purpose: this file is the single, self-contained brief a fresh AI agent reads
cold in the spawned repo. It must stand alone: the spawned repo does NOT get the
idea-garden notes or questions files, and links to idea-garden GitHub comments
may not resolve from inside the new repo. Inline anything the next agent needs.

Rules:
- Keep it self-contained. Prefer inlining a fact over linking to it.
- Lead with the TL;DR so an agent knows what to build and what to do first.
- State decisions as decisions, with a one-line why. Avoid narrating options
  that were rejected unless the rejection itself is a constraint.
- Put long verbatim source material (external answers, format samples) in the
  Appendix, not in the body.
- Replace every {{PLACEHOLDER}} and delete guidance comments before spawning.
-->

# {{PROJECT_NAME}} — Handoff

One-line purpose: {{ONE_LINE_PURPOSE}}

Origin: spawned from {{IDEA_GARDEN_ISSUE_URL}} (idea-garden).

## TL;DR for the agent

- What this is: {{WHAT_IT_IS}}
- Current status: {{STATUS}}
- Do this first: {{FIRST_STEPS}}
- Hard gotchas you must not miss: {{TOP_GOTCHAS}}

## Decisions (locked)

| # | Decision | Why |
|---|----------|-----|
| {{D_ID}} | {{DECISION}} | {{WHY}} |

## Target design

{{ARCHITECTURE}}

## Data model

{{DATA_MODEL}}

## Constraints and gotchas

{{CONSTRAINTS}}

## Open questions and deferred items

{{OPEN_ITEMS}}

## Sources

Note: these are provenance. Do not depend on them being reachable from this repo; the facts you need are inlined above and in the Appendix.

{{SOURCES}}

## Appendix: verbatim external facts

Inlined so this file is self-contained. Treat as reference, not instructions.

{{APPENDIX}}
