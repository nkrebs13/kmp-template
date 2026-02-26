## 2026-02-26
- fix: migrate deprecated ktlint config and simplify editorconfig globs (#21)
- chore: remove dead code from build config (#20)
- fix: harden Android security defaults (#19)
- fix: pin CI actions, remove debug signing from release, scope profileable to debug (#18)
- feat: add Kermit multiplatform logging foundation (#17)
- docs: remove LinkLocker dogfooding section and fix version drift (#16)
- docs: backfill missing documentation for architecture, CI, and tooling (#15)
- docs: fix documentation drift with actual build system (#14)
- test: close test gaps with platform-specific tests and build fixes (#11)
- chore(deps): dependency risk scan and safe version bumps (#13)
- perf: optimize build config and consolidate CI Gradle invocations (#10)
- chore(deps): Bump actions/setup-java from 4 to 5 (#4)
- chore(deps): Bump actions/checkout from 4 to 6 (#3)
- chore(deps): Bump gradle/actions from 4 to 5 (#2)
- docs: promote changelog to v3.0.0 release (#12)
- chore(deps): Bump @modelcontextprotocol/sdk in /mcp (#5)
- fix: apply linting and style auto-fixes (#7)
- ci: reduce template-test to standard check only (#8)
- docs: dogfooding feedback from LinkLocker production app (#6)
- feat: comprehensive quality overhaul for production-grade template
- chore(deps): update kotlinx-serialization to 1.10.0
- feat: enhance validation and add dry-run mode
- feat: add --with-mcp flag to optionally keep MCP server
- chore: use built-in gradle wrapper validation
- fix: correct Gradle wrapper validation action path
- fix: add Java keyword validation and CI improvements
- fix: apply spotless XML formatting to AndroidManifest.xml
- fix: add gradle wrapper jar to repository
- feat(mcp): add MCP tool for AI-assisted project generation
- fix(template): iteration 1 improvements
- feat: polish template for public release
- fix: AGP 9.0 compatibility and template verification fixes
- chore: re-architect documentation and update all dependencies
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed
- Dogfooding notes section from README (LinkLocker-specific production patterns)

### Fixed
- Template version references across docs (2.3.0 → 3.0.0)
- Stale dependency versions in docs/CONFIGURATION.md (Spotless 8.1.0 → 8.2.1, KSP 2.3.3 → 2.3.6)
- Navigation version in README (2.9.0 → 2.9.7)
- "Detekt + Spotless | Latest" in README replaced with actual versions

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
- Dogfooding notes section in README with production patterns from LinkLocker
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
- Updated docs/CONFIGURATION.md: kotlinx-serialization 1.9.0 -> 1.10.0, SDK 35 -> 36
- Updated docs/TEMPLATE_DEVELOPMENT.md: Kotlin version 2.1.0 -> 2.3.0, fixed file listings
- Updated docs/README_TEMPLATE.md: removed false library claims, fixed architecture description
- Updated README.md with badges, architecture diagram, and corrected version references
- Expanded version catalog with production-proven library entries (commented out by default)
- Updated dependencies documentation to reflect Navigation and DateTime version catalog entries

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

[Unreleased]: https://github.com/nkrebs13/kmp-template/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/nkrebs13/kmp-template/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/nkrebs13/kmp-template/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/nkrebs13/kmp-template/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/nkrebs13/kmp-template/releases/tag/v2.0.0
