# idea-garden

A low-friction inbox for rough ideas. When an idea matures into real work, it either moves to an existing repo or spawns a new one.

## Spawning new repos from issues

When an issue's implementation plan creates a new repo:

1. Run `gh repo create` and clone the new repo as a sibling directory
2. Copy the working docs into the new repo:
   `cp -r .claude-work/issues/<ID>/ ../<new-repo>/.claude-work/issues/<ID>/`
3. Prepend the bootstrap banner (see template below) to the new repo's README.md; create the file if it doesn't exist yet
4. Post a comment on the idea-garden issue: "Repo created at https://github.com/couimet/<repo>. Working docs copied to `.claude-work/issues/<ID>/`. Continue work from that repo."

The new repo is now self-sufficient. Open a fresh session there to continue. No commit is required at this stage — the repo can remain empty until real work begins from the new session.

### Bootstrap banner template

```markdown
<!-- Remove this banner once the repo has real documentation. -->
> [!NOTE]
> Bootstrapped from [idea-garden#2](https://github.com/couimet/idea-garden/issues/2).
> Active plan: `.claude-work/issues/2/active-plan`
```

Replace the issue number and repo name as appropriate.
