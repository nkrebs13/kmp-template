# Kotlin Multiplatform Template

A Kotlin Multiplatform starter for Android, iOS and desktop, with one Compose Multiplatform UI, a
strict build and an `AGENTS.md` that lets a coding agent generate, verify and extend the project.

[![CI](https://github.com/nkrebs13/kmp-template/actions/workflows/ci.yml/badge.svg)](https://github.com/nkrebs13/kmp-template/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/nkrebs13/kmp-template)](https://github.com/nkrebs13/kmp-template/releases)
[![License](https://img.shields.io/github/license/nkrebs13/kmp-template)](LICENSE)
[![Kotlin](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnkrebs13%2Fkmp-template%2Fmain%2Fgradle%2Flibs.versions.toml&query=%24.versions.kotlin&label=Kotlin&logo=kotlin&color=7F52FF)](gradle/libs.versions.toml)
[![Compose Multiplatform](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnkrebs13%2Fkmp-template%2Fmain%2Fgradle%2Flibs.versions.toml&query=%24.versions%5B%27compose-multiplatform%27%5D&label=Compose%20Multiplatform&color=4285F4)](gradle/libs.versions.toml)
[![AGP](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnkrebs13%2Fkmp-template%2Fmain%2Fgradle%2Flibs.versions.toml&query=%24.versions.agp&label=AGP&logo=android&color=3DDC84)](gradle/libs.versions.toml)

![The template app running on Android, iOS and desktop](docs/images/platforms.png)

It is a skeleton, not a sample app: no DI, networking, navigation or architecture to delete. What
it gives you is the build, the checks, the CI, the generator and the agent guide.

## Quick start

### With a coding agent

Give your agent a prompt like this:

```text
Create a new Kotlin Multiplatform app called WeatherApp (package com.acme.weather) from
https://github.com/nkrebs13/kmp-template: clone it, read AGENTS.md, and follow it.
```

The root [AGENTS.md](AGENTS.md) tells the agent how to pick the values, preview the change with
`./setup.sh … --yes --dry-run --json`, apply it, read the one JSON result, and then run
`./gradlew check` in the generated project, whose own `AGENTS.md` takes over from there.

### By hand

**Option A: "Use this template" on GitHub.** Create your repository from the template. Its first
push runs `template-cleanup.yml`, which initializes the project with values derived from the
repository (`acme/weather-app` becomes `WeatherApp`, package `io.github.acme.weather_app`) and
commits the result. GitHub's workflow token cannot delete files in `.github/workflows`, so the
template-only workflows stay behind, inert, and the workflow opens an issue with the `git rm`
command that removes them. Details: [docs/MAINTAINING.md](docs/MAINTAINING.md#how-the-generator-works).

**Option B: clone and run `setup.sh`.**

```bash
git clone https://github.com/nkrebs13/kmp-template.git weather-app
cd weather-app
./setup.sh --name WeatherApp --package com.acme.weather --yes
./gradlew check
```

Add `--dry-run` to see every file it would change, `--no-desktop` for Android and iOS only, and
`--display-name`, `--bundle-id` or `--author` to override the defaults. `./setup.sh --help` lists
every flag and exit code. It validates everything before the first change and checks that no
template name is left before it starts the new git history.

## What you get

| Area | What is in the box |
|---|---|
| Platforms | Android, iOS and desktop (JVM) apps hosting one shared Compose Multiplatform `App()` |
| Build logic | `build-logic/` convention plugins; module build files hold only what is specific to them |
| Gradle | Configuration cache and Isolated Projects on; JDK 21 toolchain provisioned automatically |
| Quality gate | `./gradlew check`: Spotless/ktlint, detekt with Compose rules, Android lint with warnings as errors, Kover (60% line coverage), and `checkForbiddenCalls` (no `println` in production code) |
| Tests | Compose UI tests of `App()` on the JVM and the iOS simulator, sharing one body; a test per platform `actual` |
| Android | A real baseline profile, generated on a Gradle Managed Device and packed into release builds; release signing from environment variables or `local.properties` |
| iOS | Settings in xcconfig files (never the pbxproj), synchronized folders, a privacy manifest, iOS 16+ |
| Desktop | Compose Hot Reload, and Dmg/Msi/Deb packaging on JetBrains Runtime |
| CI | Linux for static analysis, Android and desktop; macOS for iOS tests and an `xcodebuild` of the app. Runs on PRs, on `main` and weekly; a separate job checks that every catalog coordinate still resolves |
| Generator | `setup.sh` with `--dry-run` and `--json`, tested by a 71-case harness and a 6-way generation matrix (Linux and macOS × default, `--no-desktop`, edge-case names) |
| Maintenance | Grouped Dependabot updates in every generated project; in this repository, auto-merge for non-major updates and one-command releases |
| Agent guide | A complete `AGENTS.md` in every generated project, imported by its `CLAUDE.md` |

## Compared with the JetBrains wizard

The [Kotlin Multiplatform wizard](https://kmp.jetbrains.com) is the right place to start if you
want a web or server target, native iOS UI, or Amper. This template starts from the same module
layout and adds the tooling around it.

| | KMP wizard | This template |
|---|---|---|
| Targets | Android, iOS, desktop, web, server | Android, iOS, desktop |
| Module layout | `shared` plus an app module per platform | The same |
| iOS UI | Compose Multiplatform or native | Compose Multiplatform |
| Build configuration | A build script per module | Convention plugins in `build-logic/` |
| Tests | Optional ("Include tests") | UI and platform tests, Kover minimum |
| Formatting and static analysis | Not included\* | Spotless/ktlint, detekt, lint as errors, all in `check` |
| CI and dependency updates | Not included\* | GitHub Actions on Linux and macOS, Dependabot |
| Android startup | Not included\* | Baseline profile on a managed device |
| Naming the project | A web or IDE form | `setup.sh` flags with JSON output, or automatic on "Use this template" |
| Agent guidance | Not included\* | `AGENTS.md` written for agents |

\* Not mentioned in JetBrains' [first-app tutorial](https://kotlinlang.org/docs/multiplatform/compose-multiplatform-new-project.html)
as of October 2026; not checked against a freshly generated project.

## Why it's built this way

| Decision | Reason |
|---|---|
| A skeleton, not a sample app | Every library and screen a user has to delete is friction; optional libraries sit unreferenced in the catalog instead. |
| Convention plugins | Shared configuration lives once in `build-logic/`, so a module's build file holds only what is specific to it. |
| `shared` plus per-platform app modules | It matches JetBrains' 2026 default and AGP 9, which no longer allows the Android application plugin in a KMP module. |
| A static framework through `embedAndSignAppleFrameworkForXcode` | Xcode builds it through Gradle with no CocoaPods or SPM setup, and Swift Export is still alpha. |
| JDK 21 toolchain, Java 17 bytecode | Builds run on a current LTS JDK that Gradle downloads itself, while the output still runs on Java 17. |
| iOS 16 minimum | It keeps devices on iOS 16 and 17 supported; raise it in one line of `Config.xcconfig` if the app needs newer APIs. |
| Live optional catalog entries | Optional libraries are real entries, and `verifyCatalog` checks that every one still resolves, so enabling one is a one-line change that works. |
| `AGENTS.md` instead of tool-specific files | One tool-neutral guide; `CLAUDE.md` only imports it. |

## Module graph

```mermaid
graph TD
    androidApp --> shared
    iosApp["iosApp (Xcode)"] -->|static framework| shared
    desktopApp --> shared
    baselineprofile -->|profiles| androidApp
    buildLogic["build-logic"] -.->|convention plugins| shared
    buildLogic -.-> androidApp
    buildLogic -.-> desktopApp
    buildLogic -.-> baselineprofile
```

## Commands and layout

In a generated project:

```bash
./gradlew spotlessApply       # format
./gradlew check               # the quality gate
./gradlew :androidApp:installDebug
./gradlew :desktopApp:run     # or :desktopApp:hotRun --auto
open iosApp/iosApp.xcodeproj  # or xcodebuild, see AGENTS.md
```

| Path | Contents |
|---|---|
| `shared/` | The KMP library: UI, logic, resources and tests |
| `androidApp/`, `iosApp/`, `desktopApp/` | Thin platform apps |
| `baselineprofile/` | The Android baseline profile producer |
| `build-logic/` | Convention plugins |
| `config/` | detekt and Compose stability configuration |
| `gradle/libs.versions.toml` | Every version, plus the optional libraries |

The generated project's `AGENTS.md` ([source](.template/project/AGENTS.md)) covers every command,
where each setting lives, recipes and the definition of done.

## Maintaining and contributing

- [docs/MAINTAINING.md](docs/MAINTAINING.md): how the generator works, releases, Dependabot,
  repository settings and the decisions not to undo.
- [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).
- [CHANGELOG.md](CHANGELOG.md) and [releases](https://github.com/nkrebs13/kmp-template/releases).
- [MIT License](LICENSE).
