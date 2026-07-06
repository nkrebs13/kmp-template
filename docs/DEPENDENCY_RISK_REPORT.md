# Dependency Risk Report

**Generated:** 2026-07-06
**Scope:** Active Gradle, npm, Gradle wrapper, and GitHub Actions dependencies

## Executive Summary

This report reflects the dependency refresh in this PR. Active dependencies were checked against Maven Central, Google's Maven repository, npm, Gradle distribution metadata, and GitHub release metadata.

**Current risk level: LOW**

- No known npm vulnerabilities remain after updating the MCP lockfile and running `npm audit fix`.
- GitHub Actions remain pinned to immutable commit SHAs and are updated to current release tags.
- Gradle wrapper is updated to `9.5.0`, the maximum fully supported Gradle version for Kotlin 2.4.0.
- `androidx-benchmark` remains on an alpha line because the baseline profile module depends on the AGP 9-compatible 1.5.x series.
- Compose Multiplatform `1.11.1` was evaluated but deferred because its published artifacts do not include an `ios_x64` variant required by this template.

## Version Bumps Applied

| Dependency | Before | After | Notes |
|------------|--------|-------|-------|
| Gradle wrapper | 9.3.0 | 9.5.0 | Maximum fully supported by Kotlin 2.4.0 |
| Android Gradle Plugin | 9.0.0 | 9.1.0 | Maximum fully supported by Kotlin 2.4.0 |
| Kotlin | 2.3.0 | 2.4.0 | Latest stable Kotlin release |
| Compose Multiplatform | 1.10.0 | 1.10.3 | Latest stable line compatible with `iosX64` |
| AndroidX Activity Compose | 1.12.4 | 1.13.0 | Latest stable |
| AndroidX Benchmark | 1.5.0-alpha03 | 1.5.0-alpha07 | Latest alpha on required 1.5.x line |
| AndroidX Test UIAutomator | 2.3.0 | 2.4.0 | Latest stable |
| kotlinx-coroutines | 1.10.2 | 1.11.0 | Latest stable |
| Kermit | 2.0.8 | 2.1.0 | Latest stable |
| Kover | 0.9.4 | 0.9.8 | Latest stable |
| Spotless | 8.2.1 | 8.8.0 | Latest stable |
| `@modelcontextprotocol/sdk` | 1.26.0 | 1.29.0 | Latest npm release |

## CI Supply Chain

GitHub Actions are SHA-pinned to current release commits:

| Action | Version | Commit |
|--------|---------|--------|
| `actions/checkout` | v7.0.0 | `9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` |
| `actions/setup-java` | v5.4.0 | `1bcf9fb12cf4aa7d266a90ae39939e61372fe520` |
| `gradle/actions/setup-gradle` | v6.2.0 | `3f131e8634966bd73d06cc69884922b02e6faf92` |
| `actions/upload-artifact` | v7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |

## Deferred Updates

- **Compose Multiplatform `1.11.1`:** not applied. `:shared:compileKotlinIosX64` fails because `org.jetbrains.compose.*:1.11.1` artifacts do not publish an `ios_x64` variant. Keeping `iosX64` support is more important than taking this update.
- **Optional KSP catalog entry:** removed from the commented catalog surface. No Kotlin `2.4.0`-compatible KSP coordinate was published in the checked Maven metadata, so leaving the old `2.3.0` coordinate would make MCP `set_dependency` enable an incompatible plugin.
- **Commented optional dependencies:** not updated unless they are active in the build. This keeps the PR focused on dependencies actually resolved by CI.

## Validation Requirements

Before merging this dependency refresh, the PR must pass:

- `npm test`
- `npm audit`
- Full Gradle build/lint/test gate
- Generated-template setup and build gate
- CodeRabbit CLI review
- GitHub CI on the final PR head
