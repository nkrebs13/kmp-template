# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.1.0] - 2026-03-21

### Added
- `.gitattributes` for consistent line endings across platforms
- Raster launcher icons (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi) for pre-API-26 devices
- Monochrome adaptive icon layer for Android 13+ themed icons
- Dark mode splash screen (`values-night/styles.xml`)
- Kotlin keywords to package name validation in setup.sh and MCP server
- CODEOWNERS file for automatic PR review assignment
- `.tool-versions` for consistent JDK via asdf/mise
- Dry-run preview in setup.sh now shows affected files

### Changed
- Detekt: enabled `warningsAsErrors` and `checkExhaustiveness`
- Detekt: restored `FindingsReport` to console output
- Compose Stability config: narrowed to immutable collections only (`List`, `Set`, `Map`)
- Spotless: added `editorConfigOverride` to `kotlinGradle` block for consistent `.gradle.kts` formatting
- Gradle wrapper upgraded from `-bin` to `-all` distribution
- `.editorconfig`: fixed `[*.gradle]` → `[*.{gradle,gradle.kts}]`
- Xcode: Swift 5.0 → 5.9, C++ gnu++14 → gnu++20, C gnu11 → gnu17
- Xcode: Removed stale Preview Content group and asset references
- Xcode: `DEBUG_INFORMATION_FORMAT` corrected per config (dwarf for Debug, dwarf-with-dsym for Release)
- setup.sh: excluded `.git/`, `build/`, `.gradle/`, `node_modules/` from `replace_in_directory`
- setup.sh: added `.toml`, `.conf`, `.sh` to replacement file extensions
- setup.sh: added `KmpTemplate` and `orgName` replacement targets
- setup.sh: reinitializes git repo (`rm -rf .git && git init`) for clean history in generated projects
- setup.sh: uses `__PROJECT_NAME__` placeholder in README_TEMPLATE.md (avoids overbroad 'Template' replace)
- setup.sh: updates LICENSE copyright year and project name during generation
- CI: provide all 4 stdin inputs to setup.sh (project, package, bundle ID, confirm)
- CI: `allTests` documented to include `iosSimulatorArm64Test`
- MCP: TOML version regex `\w+` → `[\w-]` to parse hyphenated keys
- MCP: Fixed `coreKeys`: `compose` → `compose-plugin`
- MCP: `cpSync` now excludes `.git/` during template copies
- MCP: Added macOS system paths to `dangerousPaths`
- KSP version comment corrected to `2.3.0-1.0.31` scheme with explanation

### Removed
- Dead `themes.xml` (empty; theme is in `styles.xml`)
- Unused `INTERNET` permission from `AndroidManifest.xml`
- Stale `scripts/project.properties` (dead file, nothing reads it)
- Duplicate root-level `DEPENDENCY_RISK_REPORT.md` (canonical copy in `docs/`)
- 37+ stale remote branches cleaned up

### Fixed
- `AndroidManifest.xml`: added `fullBackupContent` for pre-API-31 compat with `dataExtractionRules`
- CI template-test stdin: was missing iOS bundle ID prompt (3 inputs → 4)
- CI: added zero `.claude/` assertion — generated projects must contain no Claude Code files
- setup.sh verification regex unified with CI (both now check `.toml`, `.conf`, `.sh`)
- Detekt: added missing `UseLet` rule (discovered by `checkExhaustiveness: true`)
- CHANGELOG header ordering (entries were prepended above `# Changelog` header)
- SECURITY.md version table updated to 3.x.x
- Kermit multiplatform logging (#17)
- ktlint config migration (#21)
- Android security hardening (#19)
- CI action SHA pinning (#18)
- Documentation drift fixes (#14, #15, #16)
- Build config dead code removal (#20)
- Gradle invocation consolidation (#10)
- Dependency risk scan and safe version bumps (#13)
- Test coverage improvements (#11)

## [3.0.0] - 2026-02-18

### Added
- expect/actual `Platform.kt` demonstrating KMP's core pattern (Android/iOS implementations)
- `MainViewController.kt` for iOS Compose UI integration via ComposeUIViewController
- Unit tests (`PlatformTest.kt`) verifying platform detection across targets
- iOS Compose integration: ContentView.swift now renders shared Compose UI
- MCP server (`mcp/index.js`) with generate, validate, and list_dependencies tools
- `scripts/validate.sh` standalone template reference validator (macOS/Linux)
- MCP npm test script for syntax validation
- Multi-client MCP configuration examples (Claude Code, Cursor)
- Dependabot configuration for automated dependency updates (GitHub Actions, npm)
- CI verification that template artifacts are properly removed after generation
- CI test execution on generated projects
- GitHub Actions CI workflow with explicit permissions, wrapper validation, and job timeouts
- Issue and PR templates
- MIT License
- Security policy (SECURITY.md)
- Code of Conduct (CODE_OF_CONDUCT.md)
- Contributing guidelines (CONTRIBUTING.md)
- `setup.sh` flags: `--dry-run` (preview changes), `--with-mcp` (keep MCP server), `--help`/`-h`
- Input validation in setup.sh: package format, Java keyword/reserved word checking, reserved package prefix validation
- Template replacement verification in setup.sh
- Git uncommitted changes warning in setup.sh
- Credential file patterns (.env, API keys, certificates) added to .gitignore
- Commented-out version catalog entries for commonly-needed libraries:
  Room, DataStore, WorkManager, Ktor Client, Koin, Coil, Timber, Tink
- `androidx-navigation-compose` version catalog entry (2.9.0)
- `kotlinx-datetime` version catalog entry (0.6.2)

### Changed
- Android `MainActivity` now calls shared `App()` instead of duplicating UI
- Moved all source files into proper package directories (`com/template/shared/`, `com/template/android/`)
- Added package declarations to all Kotlin source files
- Baseline profiles fully enabled (previously commented out)
- `setup.sh` package regex now allows underscores (aligned with MCP server)
- `setup.sh` cleanup now removes CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, and .github/ during generation
- `build-ios-framework.sh` uses dynamic SDK version detection instead of hardcoded versions
- `build-ios-framework.sh` REPO_ROOT correctly resolves from scripts/ subdirectory
- Repositioned MCP documentation as AI-harness agnostic (not Claude Code-specific)
- CI template verification expanded to check .swift, .plist, .pro, .pbxproj files and TemplateApp pattern
- CI reduced from 3-entry test matrix to single standard configuration
- CI uses built-in Gradle wrapper validation instead of deprecated standalone action
- ProGuard rules cleaned: removed phantom Ktor/SQLDelight/Koin rules, kept coroutines
- Detekt configuration: added source paths for androidApp/src and shared/src, fixed deprecated ForbiddenComment config, added Composable exception to FunctionNaming rule
- Updated AGP from 9.0.0-beta03 to 9.0.0 (stable)
- Updated Kotlin from 2.2.21 to 2.3.0
- Updated Compose Multiplatform from 1.9.3 to 1.10.0
- Updated Gradle from 9.2.1 to 9.3.0
- Updated androidx-activity-compose from 1.10.0 to 1.12.2
- Updated androidx-compose-bom from 2025.10.01 to 2026.01.00
- Updated androidx-compose-material3 from 1.3.1 to 1.4.0
- Updated androidx-benchmark from 1.3.3 to 1.4.1
- Updated ktlint from 1.7.0 to 1.8.0

### Removed
- Dead code: commented-out Preview in MainActivity.kt
- Unused kotlinx-serialization plugin and dependency from shared/build.gradle.kts
- Phantom ProGuard rules for Ktor, SQLDelight, Koin (libraries not in template)
- Duplicate MyApp() composable from MainActivity.kt
- References to nonexistent CLAUDE_CODE_GUIDE.md and README.md.template
- CLAUDE.md references from setup.sh (file doesn't exist in repo)
- Template-specific AI configuration files
- 75+ unused dependencies from version catalog (kept only actually-used entries)
- Deprecated Kotlin native properties (`kotlin.native.binary.memoryModel`, `kotlin.native.cacheKind`)
- `kotlinAndroid` plugin (now built into AGP 9.0)

### Fixed
- sed escaping in setup.sh for special characters
- TODO comment in androidApp/build.gradle.kts that violated detekt ForbiddenComment rule
- iOS app now actually uses shared KMP code (was purely static SwiftUI)
- Android app now uses shared UI (was duplicating it)
- .gitignore AI section uses neutral heading instead of tool-specific
- Gradle wrapper jar gitignore exclusion ordering (was blocked by `*.jar` pattern)

## [2.2.0] - 2025-12-03

### Added
- Kotlin 2.2.21 with K2 compiler
- Compose Multiplatform 1.9.3 with production iOS support
- AGP 9.0.0-beta03 with modern build features
- Gradle 9.2.1
- Room 2.7.2 with full KMP support
- SQLite 2.5.2 multiplatform support
- Comprehensive version catalog with 100+ dependencies
- Spotless code formatting
- Detekt static analysis
- Baseline Profiles for Android performance
- Template setup script (setup.sh)

### Changed
- Migrated to modern Kotlin compiler options DSL
- Restructured project for better KMP organization

## [2.1.0] - 2025-10-15

### Added
- Initial Compose Multiplatform support
- Koin dependency injection
- Ktor networking
- Coil image loading

### Changed
- Updated to Kotlin 2.1.0
- Migrated from Gradle Groovy to Kotlin DSL

## [2.0.0] - 2025-08-01

### Added
- Kotlin Multiplatform project structure
- Shared module for iOS and Android
- Version catalog for dependency management

### Changed
- Complete rewrite from single-platform template

[Unreleased]: https://github.com/nkrebs13/kmp-template/compare/v3.1.0...HEAD
[3.1.0]: https://github.com/nkrebs13/kmp-template/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/nkrebs13/kmp-template/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/nkrebs13/kmp-template/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/nkrebs13/kmp-template/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/nkrebs13/kmp-template/releases/tag/v2.0.0
