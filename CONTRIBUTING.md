# Contributing to KMP Template

First off, thanks for taking the time to contribute! This template helps developers kickstart their Kotlin Multiplatform projects, and your contributions make it better for everyone.

## Prerequisites

Before contributing, ensure you have:

- **macOS** (required for iOS development and testing)
- **A JDK** to start Gradle (the JDK 21 toolchain is downloaded automatically if it is missing)
- **Android Studio** (latest stable with KMP plugin)
- **Xcode 16+** (the iOS project uses synchronized folders)

> **Note:** Windows and Linux are not supported for full template development due to iOS build requirements.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/kmp-template.git
   cd kmp-template
   ```
3. **Verify the build**:
   ```bash
   ./gradlew check
   ```

## Development Workflow

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Format, then run the full gate:
   ```bash
   ./gradlew spotlessApply
   ./gradlew check
   ```

4. If you touched `setup.sh` or `.template/`, run the generator checks:
   ```bash
   shellcheck setup.sh .template/*.sh scripts/*.sh tests/setup/*.sh
   bash tests/setup/run.sh                     # on macOS, also: /bin/bash tests/setup/run.sh
   ```

5. Generate a project in a copy and build it (never run `setup.sh` in your checkout).
   `setup.sh` checks for template leftovers itself and exits 5 if it finds any. The full
   end-to-end procedure is in [docs/MAINTAINING.md](docs/MAINTAINING.md#verifying-generator-changes):
   ```bash
   git clone . ../template-test && cd ../template-test
   ./setup.sh --name WeatherApp --package com.acme.weather --author "Test" --yes
   ./gradlew check
   ```

### Testing Guidelines

Before submitting a PR, test with multiple package name patterns:

| Pattern | Example | Tests |
|---------|---------|-------|
| Standard | `com.example.myapp` | Common case |
| Deep | `io.company.product.mobile.app` | Long package paths |
| Minimal | `app.short` | Edge case |

### Code Style

- Follow existing code patterns in the project
- Use the version catalog (`libs.versions.toml`) for all dependencies
- Keep Kotlin code formatted with Spotless
- Prefer clarity over cleverness

## Commit Conventions

Write clear, descriptive commit messages:

```
feat: add Room database support to shared module
fix: correct sed escaping in setup.sh for special characters
docs: update README with new quick start guide
chore: update the Kotlin Gradle plugin
```

Prefixes:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks (dependency updates, etc.)
- `refactor:` - Code changes that neither fix bugs nor add features

## Pull Request Process

1. **Update documentation** if your changes affect usage
2. **Update the version catalog** if adding/updating dependencies
3. **Test template generation** with at least 2 different package names
4. **Ensure CI passes** (builds, linting, template tests)
5. **Fill out the PR template** completely

## CI Pipeline

Two workflows run on pull requests targeting `main` and on pushes to `main`. `template.yml` runs only in the canonical `nkrebs13/kmp-template` repository, not in forks.

**`.github/workflows/ci.yml`** is the project CI. It contains no project-specific names.

| Job | Runner | Runs |
|-----|--------|------|
| Static analysis | ubuntu | `spotlessCheck detekt` |
| Android & Desktop | ubuntu | `check` (tests, lint, Kover), Kover HTML report, `:androidApp:assembleRelease`, `:baselineprofile:assemble`, `:desktopApp:createDistributable` |
| iOS | macos-26 | `:shared:iosSimulatorArm64Test :shared:linkDebugFrameworkIosSimulatorArm64`, privacy manifest lint, `xcodebuild` of the app |
| Verify catalog | ubuntu | `verifyCatalog` (needs the network): every catalog coordinate, including unreferenced optional entries, resolves |

Every job runs on every event. The workflow also runs weekly on a schedule, so toolchain drift shows up without a PR.

**`.github/workflows/template.yml`** is template-only:

- **Generator lint and tests**: `shellcheck`, then `tests/setup/run.sh` (exit codes, validation,
  dry run, generation variants, `--derive-from-github` derivation), on ubuntu and on macOS
  `/bin/bash` 3.2.
- **Generate**: {ubuntu, macOS} × {default, `--no-desktop`, edge (underscore package, hyphenated
  bundle ID, display name with a space)}. macOS runs `setup.sh` on `/bin/bash` 3.2. Every
  combination runs the leftover check and asserts there is no `.claude/`, that `AGENTS.md` and
  the `@AGENTS.md` `CLAUDE.md` exist, and that `ci.yml` and `dependabot.yml` survive. On ubuntu,
  default and `--no-desktop` run `./gradlew check` and edge builds Android; on macOS, default runs
  the iOS tests and `xcodebuild`, and edge links the iOS framework and checks its bundle ID.

**`.github/workflows/template-cleanup.yml`** is template-only too. In a repository created with
"Use this template", it runs `setup.sh --derive-from-github` on the first push to `main` and
commits the result.

Every job, Verify catalog included, must pass before a PR can be merged (the list is in `docs/MAINTAINING.md`). Concurrency groups cancel in-progress runs when new commits are pushed.

## What to Contribute

We welcome contributions in these areas:

- **Dependency updates** - Keep libraries current
- **Build improvements** - Faster, more reliable builds
- **Documentation** - Clearer guides and examples
- **Bug fixes** - Especially in `setup.sh`
- **New features** - Discuss in an issue first

## Questions?

- Ask in an [issue](https://github.com/nkrebs13/kmp-template/issues); check the existing ones first
- Read the [maintainer guide](docs/MAINTAINING.md) for how the generator works and how releases are cut

Thanks for contributing!
