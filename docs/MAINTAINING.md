# Maintaining the template

Maintainer-only: `setup.sh` deletes `docs/`, so generated projects never see this file. Agents
maintaining the template also read [.claude/CLAUDE.md](../.claude/CLAUDE.md). The root
[AGENTS.md](../AGENTS.md) is for agents *using* the template; the generated project's guide is
[.template/project/AGENTS.md](../.template/project/AGENTS.md).

## What the template promises

A skeleton, not a sample app: Android, iOS and desktop (JVM) hosting one Compose Multiplatform
`App()`, with production build tooling and nothing a user has to delete. No DI, navigation,
networking or architecture; Kermit and `AppLogger` are the one deliberate exception. Optional
libraries live in the catalog, unreferenced, so adding one is a one-line change. The primary
reader of every generated doc is a coding agent: a generated project's `AGENTS.md` must be enough
to build, verify and extend it with no other context.

## How the generator works

`setup.sh` is the only program; everything it knows about the template is data in `.template/`,
which it deletes along with the other template-only files.

| File | Role |
|---|---|
| `.template/manifest.env` | The tokens it renames, `DESKTOP_PATHS` (deleted by `--no-desktop`) and `SKIP_DIR_NAMES` (build and tool directories it skips and deletes). Plain `KEY=value`, sourced by bash 3.2. |
| `.template/template-only.txt` | Paths it deletes. Each is also a forbidden path for the leftover check. |
| `.template/forbidden.txt`, `forbidden-desktop.txt` | Perl regexes a generated project must not match, in paths or contents (the second only with `--no-desktop`). |
| `.template/check-leftovers.sh` | Reports leftovers; `setup.sh` runs it before touching git. Usable on its own: `bash .template/check-leftovers.sh [--no-desktop] <dir>`. |
| `.template/rewrite.pl` | Token replacement and `region desktop` handling. |
| `.template/project/` | The generated `README.md`, `AGENTS.md` and `CLAUDE.md`, copied over the template's own. |

**Tokens.** One literal pass, longest token first, so replaced text is never re-replaced:

| Token | Becomes | Where it appears |
|---|---|---|
| `com.template.ios` | `--bundle-id` | `Config.xcconfig`, docs |
| `com.template.android`, `com/template/android` | `--package` | `androidApp` namespace, application ID, source path |
| `com.template`, `com/template` | `--package` | `<package>.shared`, `.desktop`, `.baselineprofile` and their source paths |
| `KMP Template` | `--display-name` | Android label, iOS display name, desktop window title |
| `KmpTemplate` | `--name` | `rootProject.name`, logger tag, desktop installer name |

Kotlin sources move by a generic `find` over `*/kotlin/com/template/**`. iOS renaming touches only
`Config.xcconfig`; `setup.sh` never edits Swift files or `project.pbxproj`.

**Desktop regions.** A line `// region desktop`, `# region desktop` or `<!-- region desktop -->`
opens a block and the matching `endregion desktop` line closes it. Markers are whole lines; text
after a marker on the same line is not a marker. `--no-desktop` deletes every block, markers
included, plus `DESKTOP_PATHS`, and renames the CI job to "Android". The default generation deletes
only the Markdown markers and keeps code and Gradle markers.

**Order of operations.** Validate every value (UTF-8; length limits: name 50, package 150, segment
63, longest moved path 900 bytes), compute and check the plan, region markers, the LICENSE line and
a copy of `.template/` (`--dry-run` stops here). Refuse a dirty tree. Back up to `$TMPDIR` when
there is no `.git`. Then change files, run the leftover check, and only then start the new history
on `main` with one commit. Nothing fails after the first change except I/O errors or a bug, and
those print a recovery command. Every path list is NUL-separated, and every deleted path must
resolve inside the repository. A user value that itself matches a forbidden pattern (author
`nkrebs13`) is masked before matching.

**The CLI contract** (flags, `--json` shapes, exit codes 2/3/4/5) is documented once, in the root
`AGENTS.md`. `tests/setup/run.sh` pins it; change both together. `setup.sh` must stay bash 3.2
compatible: macOS CI runs it on `/bin/bash`.

**"Use this template".** `template-cleanup.yml` runs on the new repository's first push to `main`:
`setup.sh --derive-from-github owner/repo` (name: PascalCase repo; package
`io.github.<owner>.<repo>`, sanitized; bundle ID sanitized separately, since it allows `-` but not
`_`), then commits and pushes. Every template-only workflow is guarded on the repository name, so
leftovers stay inert.

### Changing the generator

- **A file that mentions a token** needs no generator change: it is renamed automatically.
- **A new template-only file:** add its path to `.template/template-only.txt` and to the deleted
  paths `tests/setup/run.sh` asserts.
- **A desktop-only line or file:** wrap the lines in `region desktop` markers, or add the path to
  `DESKTOP_PATHS`.
- **A new token:** add it to `manifest.env`, map it to a value in `setup.sh`'s `rewrite()` (the
  `R_FROM_n`/`R_TO_n` list), add its pattern to `forbidden.txt`, and add a case to
  `tests/setup/run.sh`.
- **A new flag or rule:** add a case to `tests/setup/run.sh`, update `--help` and the root
  `AGENTS.md`.
- **Generated docs** live in `.template/project/`. Write them with the template's tokens
  (`com.template.shared`, `KmpTemplate`) so they come out with the user's values, never mention
  `setup.sh` or `.template/` (both are forbidden leftovers), and verify every command they name in
  a generated project.

### Verifying generator changes

```bash
shellcheck setup.sh .template/*.sh scripts/*.sh tests/setup/*.sh
bash tests/setup/run.sh && /bin/bash tests/setup/run.sh    # the second on macOS: bash 3.2
```

End to end, from the committed `HEAD`, as `template.yml` does (never run `setup.sh` in your
checkout; it rewrites it):

```bash
git clone -q . /tmp/e2e && cp -R .template /tmp/e2e-template
cp local.properties /tmp/e2e/          # gitignored, so the clone lacks it; or export ANDROID_HOME
cd /tmp/e2e
/bin/bash setup.sh --name WeatherApp --package com.acme.weather --author Test --yes --json
bash /tmp/e2e-template/check-leftovers.sh .                # must print nothing
./gradlew check :desktopApp:createDistributable
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
```

`template.yml` runs the matrix {ubuntu-latest, macos-26} × {`default`, `no-desktop`,
`edge`}; `edge` is `--name MyApp2 --package io.my_company.app_core --bundle-id
io.my-company.app-core --display-name "My App"`. For `--no-desktop`, pass `--no-desktop` to both
`setup.sh` and `check-leftovers.sh`.

## Updating dependencies by hand

Dependabot covers most updates (below). For a manual one: edit `gradle/libs.versions.toml`, then
`./gradlew verifyCatalog check`, the harness, and the end-to-end generation above. An update that
changes a plugin's API usually means a convention-plugin change in `build-logic/`.

## Decisions not to undo

Each looks like something to clean up; each is deliberate.

- **detekt stays on 1.23.8 until 2.x is stable, and compose-rules on 0.4.x** (0.5+ needs detekt 2).
  Dependabot ignores `io.nlopez.compose.rules:detekt` 0.5+ and cannot see detekt 2's plugin-id
  change, so check by hand monthly: `gh api repos/detekt/detekt/releases --jq '.[0:5][] |
  {tag_name, prerelease}'`. Moving to 2.x also retires the accepted `ReportingExtension.file`
  deprecation. ([HB-1580][1])
- **detekt does not catch `println`.** `ForbiddenMethodCall` is configured, but it needs type
  resolution and `check` runs the plain `detekt` tasks, so it never fires. The generated
  `AGENTS.md` says so instead of promising enforcement.
- **Spotless's `clean` hook is removed** (`applySpotlessWithoutCleanHook` in `Spotless.kt`). The
  hook closes every formatter classloader in the daemon, which fails parallel `spotless*` tasks and
  leaked Metaspace until the daemon died (diffplug/spotless#3067). Its `check()` fails the build if
  Spotless's hook changes shape, which is the signal to delete the workaround. ([HB-1582][2])
- **Isolated Projects is `org.gradle.unsafe.isolated-projects=true`.** Gradle silently ignores the
  name without `unsafe.`, so a "cleanup" turns it off with no error. Every build script and
  convention plugin must stay isolated: no `subprojects`/`allprojects`, no cross-project reads.
- **`desktopApp` packages with JetBrains Runtime** (toolchain vendor pinned, `javaHome` set from
  it). Compose packaging rejects some JDK builds, Homebrew's among them
  (JetBrains/compose-multiplatform#3107), and Hot Reload works best on JBR. ([HB-1583][3])
- **iOS deployment target 16.0.** Don't raise it to silence the `ld: warning` about Skiko's
  `libicu.icudtl_dat.o` being built for iOS 18.5: that is Skiko's prebuilt, harmless, and raising
  the minimum would drop every device on iOS 16 and 17. ([HB-1584][4])
- **No screenshot tests (Roborazzi) in `check`.** Font rendering differs between macOS and Linux,
  and `check` must be green on both. ([HB-1585][5])
- **`com.template` stays the sentinel package.** The leftover check and validation (packages inside
  `com.template` are rejected) give the safety a unique sentinel would, without moving every source
  file. ([HB-1586][6])
- **The MCP server was removed.** `setup.sh --yes --json` already gives agents a non-interactive,
  machine-readable interface; the npm server duplicated it and was one more thing to keep working.
  ([HB-1579][7])
- **The first-push cleanup cannot delete workflows.** `GITHUB_TOKEN` has no `workflows`
  permission, so GitHub refuses a push that changes `.github/workflows`. `template-cleanup.yml`
  restores the template-only workflows, pushes everything else and opens an issue with the one
  `git rm` command. They stay inert because each is guarded on the repository name. ([HB-1586][6])
- **No `docs/adr/`.** Reasoning lives where its reader looks: agent rules in the generated
  `AGENTS.md`, maintainer facts here, history on the homeboard cards.

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
      "Verify catalog",
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

`Verify catalog` (`verify-catalog` in `ci.yml`) runs on every PR and is required: without it an
`optional-catalog` minor or patch PR would auto-merge without its coordinates being resolved. It
retries and tells a network failure from a missing coordinate, so it should not flake. A real
registry outage blocks merges, which is acceptable.

Restrict who can create release tags. Only admins may create, move or delete `v*` tags, so a
tag cannot be pushed to trigger `release.yml` by anyone else (the workflow also refuses tags not
on `main`). Role id 5 is the built-in repository admin role.

```bash
gh api -X POST repos/nkrebs13/kmp-template/rulesets --input - <<'JSON'
{
  "name": "Release tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/tags/v*"], "exclude": [] } },
  "rules": [{ "type": "creation" }, { "type": "update" }, { "type": "deletion" }],
  "bypass_actors": [{ "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" }]
}
JSON
```

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
and run it again. If the push reached the remote but the client saw an error (a failing
server-side hook), the script checks with `git ls-remote`, reports the release as done and does
not roll back; if it cannot read the remote it keeps the local commit and tag and prints the
recovery steps. The very first release (no `vX.Y.Z` tag yet) links `[X.Y.Z]` to
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

## References

[1]: http://127.0.0.1:8777/c/1580 "HB-1580: build-logic convention plugins + quality tooling"
[2]: http://127.0.0.1:8777/c/1582 "HB-1582: Android correctness + baseline profile producer"
[3]: http://127.0.0.1:8777/c/1583 "HB-1583: Desktop target + desktopApp + hot reload"
[4]: http://127.0.0.1:8777/c/1584 "HB-1584: iOS xcconfig, synchronized folders, privacy manifest"
[5]: http://127.0.0.1:8777/c/1585 "HB-1585: tests + compose resources"
[6]: http://127.0.0.1:8777/c/1586 "HB-1586: generator rewrite"
[7]: http://127.0.0.1:8777/c/1579 "HB-1579: clear backlog (Dependabot, MCP removal)"
