# KMP Template: maintainer guide for agents

You are working on the **template itself**, not on a project generated from it. The root
`AGENTS.md` (loaded through the root `CLAUDE.md`) tells agents *using* the template to run
`setup.sh` first; that does not apply here. Never run `setup.sh` in this checkout: it rewrites
the repository. Generate into a copy instead (below).

[docs/MAINTAINING.md](../docs/MAINTAINING.md) is the reference: how the generator works, how to
add a token or a template-only file, releases, Dependabot, repository settings, and the decisions
not to undo. Read it before changing `setup.sh`, `.template/`, the build logic or the workflows.

## Critical rules

- **Zero `.claude/` in generated projects.** `.claude/` is in `.template/template-only.txt`, and
  `setup.sh`, the harness and `template.yml` all assert it is gone. Generated projects get a
  tool-neutral `AGENTS.md` and a root `CLAUDE.md` containing only `@AGENTS.md`, both from
  `.template/project/`. Never make `setup.sh` keep Claude Code files.
- **Skeleton only.** No sample features, DI, navigation, networking or architecture. Kermit and
  `AppLogger` are the one exception. Optional libraries go in the catalog's `Optional` blocks,
  unreferenced. Every line a user must delete is friction.
- **Generated docs are the product.** `.template/project/AGENTS.md` must let an agent build,
  verify and extend a generated project with no other context. Write it with template tokens
  (`com.template.shared`, `KmpTemplate`, `KMP Template`), keep `region desktop` markers on lines
  of their own, never mention `setup.sh` or `.template/` there, and run every command it names in
  a generated project.
- **The CLI contract** (flags, `--json` shapes, exit codes) is documented in the root `AGENTS.md`
  and pinned by `tests/setup/run.sh`. Change all three together.
- **Never move, delete or re-create the version tags** (every `v*` tag on the remote). The
  CHANGELOG compare links depend on them. Releases are cut only with `scripts/release.sh`.
- **Repository docs hold long-lived knowledge only**: no session logs, dated status notes or plan
  phases. History lives in git and the pull requests.

## Verify

Template build (macOS; Linux skips the iOS parts):

```bash
./gradlew spotlessApply
./gradlew check :androidApp:assembleRelease :baselineprofile:assemble :desktopApp:createDistributable
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
./gradlew verifyCatalog          # after any catalog edit (network)
```

Generator (seconds, no Gradle):

```bash
shellcheck setup.sh .template/*.sh scripts/*.sh tests/setup/*.sh
bash tests/setup/run.sh && /bin/bash tests/setup/run.sh    # the second is macOS bash 3.2
```

Generation, as `template.yml` runs it (variants `default`, `--no-desktop`, and `edge`:
`--name MyApp2 --package io.my_company.app_core --bundle-id io.my-company.app-core --display-name "My App"`):

```bash
git clone -q . /tmp/e2e && cp -R .template /tmp/e2e-template && cp local.properties /tmp/e2e/
cd /tmp/e2e && /bin/bash setup.sh --name WeatherApp --package com.acme.weather --author Test --yes --json
bash /tmp/e2e-template/check-leftovers.sh .        # must print nothing; add --no-desktop for that variant
test ! -e .claude && test "$(cat CLAUDE.md)" = "@AGENTS.md"
./gradlew check :desktopApp:createDistributable    # plus the xcodebuild line above
```

## Where things are

- `build-logic/convention/`: convention plugins `convention.kmp.library`, `convention.compose`,
  `convention.android.application`, `convention.android.test`, `convention.jvm.application`,
  `convention.quality` (Spotless, detekt, Kover, `checkForbiddenCalls`; applied by the others) and `convention.root` (root `check`, root-level
  Spotless, `verifyCatalog`). The root `build.gradle.kts` holds only `apply false` lines.
- SDK levels: catalog `[versions]` (`android-compile-sdk`, `android-target-sdk`,
  `android-min-sdk`). Application ID, app version and desktop installer name: `gradle.properties`. JDK 21
  toolchain and Java 17 bytecode: `ProjectExtensions.kt`. iOS settings:
  `iosApp/Configuration/Config.xcconfig` only, never `project.pbxproj`.
- `.template/`: generator data. `tests/setup/run.sh`: generator harness. `scripts/release.sh`:
  releases. `docs/MAINTAINING.md`: maintainer reference.
- Workflows: `ci.yml` ships to generated projects and must stay project-neutral;
  `template.yml`, `template-cleanup.yml`, `dependabot-automerge.yml` and `release.yml` are
  template-only.

The rules in `.claude/rules/` cover Kotlin, Gradle and testing conventions; they match the
generated `AGENTS.md`.
