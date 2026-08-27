# README Badge Policy

A canonical standard for the badges shown in the public `README.md` files of repositories maintained by `couimet`. The policy lives at `docs/standards/readme-badges.md` in `couimet/idea-garden`; that repository is the canonical home for this policy and for the other standards listed in [`docs/standards/README.md`](./README.md).

## Purpose and Scope

Badges tell a reader at a glance where a project ships, how healthy it is, how well it is tested, and under what terms it is licensed. This policy keeps those signals honest: a badge is only shown when its image renders, its destination link is correct, and its metric means what the label claims.

The policy applies to **public, non-fork, non-archived repositories maintained by `couimet` that ship a README**.

It does not apply to:

- **Archived repositories.** Their badges describe a frozen state and are not maintained.
- **Experimental repositories.** Purpose-built to be scrappy; badge churn here is noise.
- **Personal or throwaway repositories.** Not meant for public consumption.

When in doubt, treat a repository as in scope: the cost of an extra, truthful badge is lower than the cost of a stale or misleading one.

## Badge Rules

Add a badge only when the rule for that badge is satisfied. A badge that no longer satisfies its rule is removed in the same change that made it obsolete.

### CodeRabbit

Add a CodeRabbit badge **only when CodeRabbit is enabled** for the repository. When CodeRabbit is turned off or removed, delete the badge.

Canonical form: the shields.io `coderabbit/prs` badge for the repository, linking to CodeRabbit.

```text
[![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/couimet/<repo>?label=CodeRabbit+Reviews)](https://coderabbit.ai)
```

### Codecov

Add a Codecov badge **only when CI successfully uploads coverage**. A repository with no tests, or tests that never upload coverage, does not get a Codecov badge.

Canonical form: the Codecov status badge for the default branch, linking to the repository's Codecov report.

### npm packages

For **published packages**, add npm version and download badges. The badge must identify the exact package on npm.

```text
[![npm version](https://img.shields.io/npm/v/<package>)](https://www.npmjs.com/package/<package>)
[![npm downloads](https://img.shields.io/npm/dw/<package>)](https://www.npmjs.com/package/<package>)
```

### VS Code extensions

For **published extensions**, add VS Code Marketplace and Open VSX badges, each linking to its own marketplace listing.

```text
[![VS Code Marketplace version](https://vsmarketplacebadges.dev/version/<publisher>.<name>.svg)](https://marketplace.visualstudio.com/items?itemName=<publisher>.<name>)
[![Open VSX version](https://img.shields.io/open-vsx/v/<publisher>/<extension>)](https://open-vsx.org/extension/<publisher>/<extension>)
```

Use install or download badges in the same way when the README reports adoption.

### License

Add a license badge **when the repository has a public license**, linking to the license file in the repository.

```text
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
```

## Monorepo Rules

In a monorepo, metrics can describe the whole repository or one package. The README's placement must match the metric's scope:

- **Root README** uses aggregate repository metrics: repository-level coverage, total download counts, overall build status.
- **Package READMEs** use package-specific metrics, flags, or components.
- **Do not display a metric when the badge cannot identify its scope.** A badge that cannot be pointed at a specific package or at the repository has nothing honest to show and is omitted.

## Placement and Ordering

Place badges in a **single row directly under the title**, before the description. When a README has several badges, order them left to right as:

1. **Distribution** — where the software ships: npm, VS Code Marketplace, Open VSX, releases.
2. **Quality** — how the project is kept honest: CodeRabbit, CI build status.
3. **Coverage** — how well it is tested: Codecov.
4. **License** — the terms it is distributed under.

A README shows only the badges its rules require; there is no need to fill the row.

## Exceptions

Two exceptions are built in because the badge rule is conditional by nature:

- **No Codecov badge** in a repository without tests or coverage uploads.
- **No CodeRabbit badge** in a repository without CodeRabbit.

Any other deviation from this policy requires a **short documented reason**, written next to the badge or in the repository's README. A documented reason is one or two sentences explaining why the badge is present or absent despite the rule, for example a link that only makes sense to a contributor audience.

## Verification

Before merging any README change, and during periodic sweeps:

1. **Each badge image renders.** Fetch the badge URL; it must return an image, not an error.
2. **Each badge destination link is correct.** The link must lead to the repository, package, marketplace listing, or license file the badge claims.
3. **Each metric represents its intended repository or package.** The number in the badge must be the number the label describes.
4. **Treat transient upstream failures separately from broken configuration.** A badge that fails because shields.io or npm is down is an upstream outage, not a policy violation; a badge that renders the wrong value or points at the wrong target is a configuration defect and must be fixed.

The CI workflow for this repository lints and formats the standards and checks their links, but a link check cannot see a badge that renders "provider or repo not found"; that check is the audit's job.

## Policy Change Process

Change this policy **through a pull request in `couimet/idea-garden`**. Every change describes:

- **Affected repository types** — which kinds of repositories the change touches, for example "all published npm packages" or "VS Code extension repos".
- **Migration impact** — what repositories must do to comply, and whether the change is retroactive.

Small clarifications and typo fixes follow the same process so every revision stays reviewable and version-controlled.

## Follow-up Automation

After this policy exists, the `couimet/my-claude-skills` repository will grow a skill that reads this policy and audits repositories against it. The policy defines the requirements; the skill defines the audit procedure. The skill is an implementation aid — it is never the source of truth for what a badge must do.
