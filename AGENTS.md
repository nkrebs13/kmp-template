# KMP Template: guide for coding agents

This repository is an **uninitialized template**. Turn it into the user's project with `setup.sh`
before doing anything else; it replaces this file with the project's own `AGENTS.md`.

```bash
./setup.sh --name WeatherApp --package com.acme.weather --yes --json
```

- `--name`: PascalCase app name (letters and digits, starting with a letter).
- `--package`: reverse-DNS Android application ID and Kotlin package, lowercase.
- Optional: `--bundle-id` (iOS; default: the package with `_` replaced by `-`), `--display-name`,
  `--author` (LICENSE holder; default `git config user.name`), `--no-desktop`, `--keep-git`,
  `--no-commit`, `--derive-from-github owner/repo`. `./setup.sh --help` lists them all.
- Run `--dry-run --json` first to see every file it would delete, write, edit or move.

`setup.sh` never prompts without a terminal and never half-applies a bad value: every input is
validated, and the plan computed and checked, before the first change.

## The `--json` result

stdout carries exactly one JSON object; human-readable progress goes to stderr.

Success:

```json
{"status": "ok", "dryRun": false, "name": "WeatherApp", "package": "com.acme.weather",
 "bundleId": "com.acme.weather", "displayName": "WeatherApp", "author": "Ada", "desktop": true,
 "removed": ["setup.sh", "..."], "committed": true, "verified": false,
 "next": [{"run": "./gradlew check", "why": "..."}, {"read": "AGENTS.md", "why": "..."}]}
```

- `verified` is always `false`: setup.sh renames and checks files but builds nothing.
  `./gradlew check` (always `next[0]`) is the proof that the project works.
- `next` lists steps in order: `{"run": "<shell command>"}` or `{"read": "<file>"}`, each with a
  `why`. Run them from the project root.
- With `--dry-run`, `removed` and `committed` are absent, `plan` lists
  `{"delete": [...], "write": [...], "edit": [...], "move": [{"from": ..., "to": ...}]}`, and
  `next` holds only the same command without `--dry-run`.
- `--help --json` prints the help on stderr and `{"status": "ok", "help": true}`.

Failure:

```json
{"status": "error", "code": 4, "category": "precondition", "reason": "already-initialized",
 "message": "...", "recovery": "..."}
```

| code | category | meaning |
|---|---|---|
| 2 | `usage` | unknown option, missing value, a required option without a terminal, or no `--yes` |
| 3 | `validation` | an invalid value; nothing changed |
| 4 | `precondition` | uncommitted changes (`recovery` stashes them), already initialized (`reason: "already-initialized"`: the project is set up, carry on), perl or git missing |
| 5 | `internal` | a setup.sh bug or an I/O error; `recovery` restores the template |

Maintainers: see `.claude/CLAUDE.md` and `CONTRIBUTING.md`.
