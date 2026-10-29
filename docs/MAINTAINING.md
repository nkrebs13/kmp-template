# Maintaining the template

Maintainer-only. `setup.sh` deletes this file, so generated projects never see it.

## One-time repository setup

Run once, as the repository admin. Nothing in the repository applies these settings.

Allow auto-merge and delete merged branches:

```bash
gh api -X PATCH repos/nkrebs13/kmp-template -F allow_auto_merge=true -F delete_branch_on_merge=true
```

Protect `main`. The required contexts are the job names in `ci.yml` and `template.yml`, which
neither workflow path-filters, so every PR reports all of them. Matrix jobs report one context
per combination.

```bash
gh api -X PUT repos/nkrebs13/kmp-template/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "Static analysis",
      "Android & Desktop",
      "iOS",
      "Generator lint and tests (ubuntu-latest)",
      "Generator lint and tests (macos-26)",
      "Generate (ubuntu-latest, default)",
      "Generate (ubuntu-latest, no-desktop)",
      "Generate (ubuntu-latest, edge)",
      "Generate (macos-26, default)",
      "Generate (macos-26, no-desktop)",
      "Generate (macos-26, edge)"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
JSON
```

`Verify catalog` (`verify-catalog` in `ci.yml`) runs on every PR too, but it is deliberately not
required: it resolves every catalog coordinate over the network, and a registry outage should not
block merges. It still shows on each PR; look at it before merging catalog changes.

When a job `name:` or a matrix axis changes in `ci.yml` or `template.yml`, update this list and
re-run the command, or auto-merge will wait for a context that never reports.

Verify:

```bash
gh api repos/nkrebs13/kmp-template --jq '{allow_auto_merge, delete_branch_on_merge}'
gh api repos/nkrebs13/kmp-template/branches/main/protection/required_status_checks --jq '.contexts'
```

## Releasing

```bash
scripts/release.sh --dry-run X.Y.Z   # prints the CHANGELOG diff and the commands, changes nothing
scripts/release.sh X.Y.Z
```

It requires `main`, a clean tree, `main` equal to `origin/main`, a version greater than the latest
tag, and a non-empty `[Unreleased]` section. It then moves `[Unreleased]` under
`## [X.Y.Z] - <today>`, updates the compare links, commits `chore(release): vX.Y.Z`, creates the
annotated tag and pushes the commit and the tag together. The tag triggers `release.yml`, which
creates the GitHub Release from that CHANGELOG section and fails if the section is missing or
empty.

The release commit is pushed straight to `main`. It changes only `CHANGELOG.md`, and
`enforce_admins=false` lets an administrator push without the required checks. A non-admin
cannot release. If the push fails (rejected, offline), the script deletes the local tag and resets
`main` to `origin/main`, provided `HEAD` is still its release commit, then says so; fix the cause
and run it again. The very first release (no `vX.Y.Z` tag yet) links `[X.Y.Z]` to
`releases/tag/vX.Y.Z` instead of a compare range.

## Dependabot

`.github/dependabot.yml` (kept in generated projects, so it contains nothing template-specific)
checks `gradle` and `github-actions` weekly and labels PRs `dependencies`.

- Minor and patch updates are grouped: `build-tooling`, `optional-catalog`, `kotlin-compose`,
  `android` and, for Actions, `actions`. A dependency that matches several groups goes to the
  first one listed, which is why the narrow groups come first. Major updates open one PR each.
- `io.nlopez.compose.rules:detekt` is ignored from 0.5: it needs detekt 2.x, and the template
  stays on detekt 1.23.x until 2.x is stable. Dependabot cannot see the detekt plugin-id change
  in 2.x, so check by hand when 2.0 ships stable.
- Dependabot proposes a pre-release only when the current version is one, and the config has no
  option to forbid it, so none is set.

`dependabot-automerge.yml` (template-only) runs on Dependabot PRs in this repository and
queues `gh pr merge --auto --squash` for every update that is not a major one. GitHub then merges
once the required checks above pass. Majors are reviewed and merged by hand. A grouped PR reports the highest update type in the
group, so one major in a group keeps the whole PR manual.

Merges made with `GITHUB_TOKEN` (auto-merge) do not trigger `push: main` workflows. The PR-time
checks are therefore the gate, and the weekly `ci.yml` schedule catches drift afterwards.
