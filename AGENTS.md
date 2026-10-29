# KMP Template: guide for coding agents

This repository is an **uninitialized template**. Do not edit, build or add code yet: every
package, name and doc here is a placeholder. First turn it into the user's project with
`setup.sh`, which replaces this file with the project's own `AGENTS.md`.

Improving the template itself instead? Skip the rest of this file and read
[docs/MAINTAINING.md](docs/MAINTAINING.md) and [.claude/CLAUDE.md](.claude/CLAUDE.md).

## 1. Choose the values

Derive them from the user's request. Ask only when the request gives no basis for `--package`.

| Flag | Rule | "a weather app for Acme" |
|---|---|---|
| `--name` | PascalCase, letters and digits, starts with a letter, at most 50 characters. Gradle root project, logger tag, desktop installer name. | `WeatherApp` |
| `--package` | Lowercase reverse DNS, at least two segments, each `[a-z][a-z0-9_]*`. No Java/Kotlin keyword segment, nothing under `java.`, `javax.`, `android.`, `kotlin.`, `kotlinx.` or `com.template`. Android application ID and Kotlin package; modules get `<package>.shared` etc. | `com.acme.weather` |
| `--display-name` | Optional. The name under the icon and in the desktop window title. Default: `--name`. Use it when the user's name for the app has spaces. | `"Acme Weather"` |
| `--bundle-id` | Optional. iOS bundle ID. Default: the package with `_` replaced by `-`. | |
| `--author` | Optional. LICENSE copyright holder. Default: `git config user.name`. | `"Acme Inc."` |
| `--no-desktop` | Optional. Leave out the desktop (JVM) app. Use it only when the user wants Android and iOS only. | |
| `--derive-from-github owner/repo` | Optional. Derives name, package (`io.github.<owner>.<repo>`), bundle ID and author from a GitHub repository. Explicit flags win. | |

Also available: `--keep-git` (keep this `.git`; no new history, no commit) and `--no-commit` (new
history, changes staged but not committed). `./setup.sh --help` documents every flag.

## 2. Preview, then apply

```bash
./setup.sh --name WeatherApp --package com.acme.weather --display-name "Acme Weather" --yes --dry-run --json
./setup.sh --name WeatherApp --package com.acme.weather --display-name "Acme Weather" --yes --json
```

- `--yes` is required without a terminal; `setup.sh` never prompts then. Pass it to the dry run
  too: the dry run's `next` command is the same invocation without `--dry-run`.
- Run it from the repository root with a clean git tree. It validates every value and computes and
  checks the whole plan before the first change, so a bad value changes nothing.
- On success it has deleted the template-only files, started a new git history on `main` with one
  commit, and checked that no template name is left.

## 3. Read the result

stdout carries exactly one JSON object; progress goes to stderr. Exit code 0 means `"status": "ok"`.

Applied:

```json
{"status": "ok", "dryRun": false, "name": "WeatherApp", "package": "com.acme.weather",
 "bundleId": "com.acme.weather", "displayName": "Acme Weather", "author": "Ada", "desktop": true,
 "removed": [".template", "setup.sh", "docs", "..."], "committed": true, "verified": false,
 "next": [{"run": "./gradlew check", "why": "..."}, {"read": "AGENTS.md", "why": "..."}]}
```

- `next`: the steps to take, in order, from the project root. Each is `{"run": "<shell command>"}`
  or `{"read": "<file>"}`, with a `why`. `next[0]` is always `./gradlew check`.
- `verified` is always `false`: `setup.sh` renames and checks files but builds nothing.
- `committed` is `false` with `--keep-git`, with `--no-commit`, or when git has no identity; `next`
  then ends with the commit command to run.

Dry run (`--dry-run`): no `removed` or `committed`; instead `plan` lists
`{"delete": [...], "write": [...], "edit": [...], "move": [{"from": "...", "to": "..."}]}`, and
`next` holds only the apply command.

`--help --json` prints the help on stderr and `{"status": "ok", "help": true}` on stdout.

Failure (non-zero exit):

```json
{"status": "error", "code": 4, "category": "precondition", "reason": "already-initialized",
 "message": "...", "recovery": "..."}
```

| code | category | meaning | do |
|---|---|---|---|
| 2 | `usage` | unknown option, missing value, no `--yes` without a terminal | fix the command |
| 3 | `validation` | a value is invalid; `message` says which and why; nothing changed | choose another value |
| 4 | `precondition` | uncommitted changes, already initialized, or perl or git missing | `reason: "already-initialized"`: the project is set up, go to step 4. Uncommitted changes: `recovery` is the command that stashes them. |
| 5 | `internal` | a `setup.sh` bug or an I/O error | run `recovery` to restore the template, then report it |

`reason` and `recovery` appear only when they apply.

## 4. Continue in the generated project

Run the `next` steps: `./gradlew check`, then read the new `AGENTS.md`. It holds the commands,
where every setting lives, the recipes and the definition of done for the project.
