# idea-garden

A low-friction inbox for rough ideas. When an idea matures into real work, it either moves to an existing repo or spawns a new one.

## Spawning new repos from issues

When an issue's implementation plan creates a new repo, invoke `/spawn-repo <name>`. The skill handles repo creation, cloning, working-doc copy, README banner, and the handoff comment. See `.claude/skills/spawn-repo/SKILL.md` for the full workflow.

## Standards

`docs/standards/` holds canonical cross-project policy for repositories maintained by `couimet` (see `docs/standards/README.md` for the index). Change standards through pull requests in this repo.

## GitHub Actions references

Rules governing how workflows and composite actions in this repository reference GitHub Actions, mirrored in full from `couimet/github-actions`'s CLAUDE.md. These rules are checked on every response; violations are unacceptable.

### CI001: Third-party actions pinned to commit SHA

Pin every third-party action (e.g. `actions/checkout`) to a full commit SHA WITHOUT a `# vX.Y.Z` version comment to prevent drift.

Never use floating version refs like `@v4` or `@main` for third-party actions.

Good:

```yaml
uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10
```

Bad:

```yaml
uses: actions/checkout@v4
```

### CI002: Internal actions always use @main, never a commit SHA

Reference all `couimet/github-actions/*` actions with `@main`: `uses: couimet/github-actions/typescript-ci@main`.

Never pin to a commit SHA or tag for `couimet/github-actions` actions.

`@main` is the intended rolling release channel for first-party actions. We control the repo, so breaking changes are intentional and versioned. SHAs add pin-update churn with no benefit for actions we own.

<!-- rule-id: couimet-actions-main -->

### CI003: Composite actions reference internal actions by full path, not ./

In composite action `action.yml` files, reference other `couimet/github-actions/*` actions with the full `couimet/github-actions/<name>@main` path.

Never use `./` relative paths or `${{ github.action_path }}` expressions in `uses:` — `./` resolves to the consumer's workspace, and expressions are forbidden in `uses:` fields.

GitHub Actions resolves `./` paths in composite actions relative to the consuming repository's workspace. The `${{ github.action_path }}` expression would point to the action's own repo, but GitHub Actions forbids expressions in `uses:` fields entirely. The only portable option is the full `owner/repo/path@main` reference.

Good:

```yaml
uses: couimet/github-actions/publish-pr-comment@main
```

Bad:

```yaml
uses: ./publish-pr-comment
```

Bad:

```yaml
# Also invalid: expressions are forbidden in uses:
uses: ${{ github.action_path }}/publish-pr-comment
```

## Docs CI

The CI workflow lints and formats Markdown via `couimet/github-actions/markdownlint` and `couimet/github-actions/prettier`, and checks links with the lychee action at `.github/actions/lychee-check`. The lychee action is an **incubated copy** pending migration to `couimet/github-actions`; once migrated, remove the local copy and reference `couimet/github-actions/lychee-check@main`.
