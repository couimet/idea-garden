# lychee-check

A composite action that checks links in Markdown (or any text) files with [lychee](https://github.com/lycheeverse/lychee). It installs lychee at a pinned version from the official release assets, then runs it over the given paths.

## Usage

```yaml
- uses: ./.github/actions/lychee-check
  with:
    lychee-version: v0.24.2
    paths: '**/*.md'
    working-directory: .
```

| Input               | Required | Default   | Description                                                                           |
| ------------------- | -------- | --------- | ------------------------------------------------------------------------------------- |
| `lychee-version`    | no       | `v0.24.2` | Version of lychee to install, in `vX.Y.Z` or `X.Y.Z` form.                            |
| `paths`             | no       | `**/*.md` | Space-separated paths or globs to check. Globs are resolved by lychee, not the shell. |
| `working-directory` | no       | `.`       | Directory to run lychee in.                                                           |

Lychee exits non-zero when a link is broken, so a failed link fails the job.

## Incubation status

This action is an **incubated copy** living in `couimet/idea-garden`. After the lychee check passes green on three merged PRs, it migrates to `couimet/github-actions` and this copy is removed. Tracked by [couimet/idea-garden#18](https://github.com/couimet/idea-garden/issues/18).
