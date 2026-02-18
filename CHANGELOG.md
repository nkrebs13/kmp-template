# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- expect/actual `Platform.kt` demonstrating KMP's core pattern (Android/iOS implementations)
- `MainViewController.kt` for iOS Compose UI integration via ComposeUIViewController
- Unit tests (`PlatformTest.kt`) verifying platform detection across targets
- iOS Compose integration: ContentView.swift now renders shared Compose UI
- Dependabot configuration for automated dependency updates (GitHub Actions, npm)
- CI verification that template artifacts are properly removed after generation
- CI test execution on generated projects
- MCP npm test script for syntax validation
- Multi-client MCP configuration examples (Claude Code, Cursor)
- MIT License
- Security policy (SECURITY.md)
- Code of Conduct (CODE_OF_CONDUCT.md)
- Contributing guidelines (CONTRIBUTING.md)
- GitHub Actions CI workflow
- Issue and PR templates
- Input validation in setup.sh
- Template replacement verification in setup.sh
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
- `build-ios-framework.sh` uses dynamic SDK version detection instead of hardcoded versions
- `build-ios-framework.sh` REPO_ROOT correctly resolves from scripts/ subdirectory
- Repositioned MCP documentation as AI-harness agnostic (not Claude Code-specific)
- CI template verification expanded to check .swift, .plist, .pro, .pbxproj files and TemplateApp pattern
- ProGuard rules cleaned: removed phantom Ktor/SQLDelight/Koin rules, kept coroutines
- Updated docs/CONFIGURATION.md: kotlinx-serialization 1.9.0 -> 1.10.0, SDK 35 -> 36
- Updated docs/TEMPLATE_DEVELOPMENT.md: Kotlin version 2.1.0 -> 2.3.0, fixed file listings
- Updated docs/README_TEMPLATE.md: removed false library claims, fixed architecture description
- Updated README.md: kotlinx-serialization version 1.9.0 -> 1.10.0
- Updated AGP from 9.0.0-beta03 to 9.0.0 (stable)
- Updated Kotlin from 2.2.21 to 2.3.0
- Updated Compose Multiplatform from 1.9.3 to 1.10.0
- Updated Gradle from 9.2.1 to 9.3.0
- Improved README with badges and architecture diagram
- Fixed sed escaping in setup.sh for special characters
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

### Fixed
- TODO comment in androidApp/build.gradle.kts that violated detekt ForbiddenComment rule
- iOS app now actually uses shared KMP code (was purely static SwiftUI)
- Android app now uses shared UI (was duplicating it)
- .gitignore AI section uses neutral heading instead of tool-specific

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

[Unreleased]: https://github.com/nkrebs13/kmp-template/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/nkrebs13/kmp-template/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/nkrebs13/kmp-template/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/nkrebs13/kmp-template/releases/tag/v2.0.0
