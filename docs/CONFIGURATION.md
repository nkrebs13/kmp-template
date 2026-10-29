# Kotlin Multiplatform Template - Configuration Reference

This document provides detailed configuration information for the Kotlin Multiplatform template, including dependency management, build system configuration, and customization options.

## Template Stack

| Component | Version |
|-----------|---------|
| Kotlin | 2.4.21 |
| Compose Multiplatform | 1.12.2 |
| Android Gradle Plugin | 9.5.0 |
| Gradle | 9.6.1 |
| JDK | 21 (toolchain; Gradle provisions it if missing), emitting Java 17 bytecode |
| Android SDK | compileSdk 37, targetSdk 36, minSdk 24 |

## Version Catalog System

All dependencies, plugins and Android SDK levels are managed through `gradle/libs.versions.toml`.
The `[versions]` section is the single source of truth; the convention plugins in `build-logic/`
read it, and module build files reference `libs.*` aliases.

### Core Versions

| Dependency | Version | Purpose |
|------------|---------|---------|
| kotlin | 2.4.21 | Kotlin compiler and stdlib |
| compose-multiplatform | 1.12.2 | Compose Multiplatform UI framework |
| compose-multiplatform-material3 | 1.9.0 | Material 3 for Compose Multiplatform |
| agp | 9.5.0 | Android Gradle Plugin |
| kotlinx-coroutines | 1.11.0 | Async/concurrency |

### AndroidX Versions

| Dependency | Version | Purpose |
|------------|---------|---------|
| androidx-activity-compose | 1.13.0 | Activity APIs |
| androidx-splashscreen | 1.2.0 | Splash screen API |

### Code Quality Tools

| Tool | Version | Purpose |
|------|---------|---------|
| detekt | 1.23.8 | Static analysis (2.x is still pre-release) |
| compose-rules | 0.4.28 | Compose rules for detekt (last line built for detekt 1.23) |
| spotless | 8.10.4 | Code formatting |
| ktlint | 1.8.0 | Kotlin formatting rules, configured in `.editorconfig` |
| kover | 0.9.11 | Coverage |

### Optional Dependencies

The catalog also carries entries that no module references, inside blocks marked
`Optional: not referenced by the build`. They are real entries, kept current by Dependabot and
checked by `./gradlew verifyCatalog`, so using one is a one-line change in a module:
`implementation(libs.<alias>)` for a library, or `alias(libs.plugins.<alias>)` in the `plugins {}`
block for a Gradle plugin (KSP, Room, serialization). They cover JetBrains lifecycle and navigation for Compose
Multiplatform, Room (KMP) with `sqlite-bundled`, DataStore, kotlinx serialization and datetime,
Koin, Ktor (with the OkHttp and Darwin engines), Coil 3, Tink, WorkManager, and the KSP, Room and
serialization Gradle plugins.

## Configuration Files

### Project-Wide Settings (`gradle.properties`)

```properties
# Gradle performance
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
org.gradle.unsafe.isolated-projects=true

# Silences the disabled-iOS-targets warning on hosts that cannot build them (Linux)
kotlin.native.ignoreDisabledTargets=true

# App version, read by the convention.android.application plugin
app.versionCode=1
app.versionName=1.0.0
```

### Convention Plugins (`build-logic/`)

Module build files apply convention plugins instead of repeating configuration:

| Plugin | Applies |
|--------|---------|
| `convention.kmp.library` | KMP + Android library, `iosArm64` + `iosSimulatorArm64`, static framework, 60% Kover line coverage |
| `convention.compose` | Compose Multiplatform + compiler, `config/compose/stability.conf`, optional compiler reports |
| `convention.android.application` | SDK levels, version from `gradle.properties`, lint policy, release signing |
| `convention.quality` | Spotless, detekt (+ Compose rules), Kover; applied by the plugins above |

A module then only declares what is specific to it:

```kotlin
plugins {
    id("convention.android.application")
    id("convention.compose")
}

android {
    namespace = "com.example.myapp"
    defaultConfig {
        applicationId = "com.example.myapp"
    }
}
```

## Adding Dependencies

### From Version Catalog

```kotlin
dependencies {
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.serialization.json)
}
```

### Adding New Entries

1. Add version to `[versions]` section:
   ```toml
   ktor = "3.1.3"
   ```

2. Add library to `[libraries]` section:
   ```toml
   ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
   ```

3. Use in build files:
   ```kotlin
   implementation(libs.ktor.client.core)
   ```

## Build Configuration

### Debug Builds

```bash
# Android
./gradlew :androidApp:assembleDebug

# iOS Simulator (Apple Silicon)
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

```

### Release Builds

```bash
# Android
./gradlew :androidApp:assembleRelease

# iOS Device
./gradlew :shared:linkReleaseFrameworkIosArm64
```

### Code Quality

```bash
# Format code
./gradlew spotlessApply

# Static analysis
./gradlew detekt

# All checks: Spotless, detekt, all tests, Kover verification and lint (debug) in every module
./gradlew check

# Prove every version catalog coordinate exists (needs the network; not part of check)
./gradlew verifyCatalog
```

### Performance Profiling

Compose compiler stability + metrics reports are gated behind a project property so they
don't run on every build. Enable with:

```bash
./gradlew -Pkmp.composeCompilerReports=true :shared:compileAndroidMain
```

Reports land under `shared/build/compose-reports/` and metrics under `shared/build/compose-metrics/`. The `<module>-classes.txt` file lists
which classes are skippable / stable; `<module>-composables.csv` shows recomposition
classification per `@Composable`. Read these to debug unnecessary recomposition.

### Coroutine Tests

`kotlinx-coroutines-test` is wired into `commonTest` by default. Use `runTest { … }` and a
`TestDispatcher` so virtual time replaces real `delay()`:

```kotlin
@Test fun example() = runTest {
    val dispatcher = StandardTestDispatcher(testScheduler)
    // … exercise a suspend function on `dispatcher`, advance time with
    // `testScheduler.advanceTimeBy(N.milliseconds)` instead of waiting.
}
```

## Architecture Details

### The `expect`/`actual` Pattern

Kotlin Multiplatform uses `expect`/`actual` declarations to define platform-specific implementations from shared code. The template demonstrates this with `getPlatformName()`:

```kotlin
// shared/src/commonMain/.../Platform.kt
expect fun getPlatformName(): String

// shared/src/androidMain/.../Platform.android.kt
actual fun getPlatformName(): String = "Android"

// shared/src/iosMain/.../Platform.ios.kt
actual fun getPlatformName(): String = "iOS"
```

`expect` declares the API in common code. Each platform provides an `actual` implementation. The compiler verifies all `expect` declarations have matching `actual` implementations for every target.

### iOS/Compose Bridge

The iOS app hosts the shared Compose UI through a three-layer bridge:

1. **Kotlin side** (`shared/src/iosMain/.../MainViewController.kt`):
   ```kotlin
   fun MainViewController() = ComposeUIViewController { App() }
   ```
   `ComposeUIViewController` wraps the shared `@Composable` `App()` in a `UIViewController`.

2. **Swift side** (`iosApp/iosApp/ContentView.swift`):
   A `UIViewControllerRepresentable` wraps `MainViewController()` so it can be used in SwiftUI.

3. **SwiftUI entry** (`iosApp/iosApp/TemplateApp.swift`):
   The `@main` `App` struct renders `ContentView`, completing the chain: SwiftUI -> UIViewControllerRepresentable -> ComposeUIViewController -> Compose `App()`.

### Baseline Profile Module

The `baselineprofile/` module generates [Android Baseline Profiles](https://developer.android.com/topic/performance/baselineprofiles/overview) to improve app startup and runtime performance. Baseline profiles tell the Android runtime (ART) which code paths to pre-compile during installation.

**How it works:**

- `baselineprofile` is a `com.android.test` module (via `convention.android.test`) targeting `:androidApp`. `BaselineProfileGenerator` launches the app and records which code paths run during startup (min SDK 28).
- `:androidApp:generateBaselineProfile` builds a non-minified release, runs the generator on the Gradle Managed Device `pixel6Api34` (Pixel 6, API 34, AOSP image; downloaded on first use) and writes the result to `androidApp/src/release/generated/baselineProfiles/`.
- `baseline-prof.txt` and `startup-prof.txt` are committed, so a normal `assembleRelease` packs the profile as `assets/dexopt/baseline.prof` without running the generator.

**Regenerating the profile:**

```bash
./gradlew :androidApp:generateBaselineProfile
```

Regenerate after changing startup behaviour or adding user journeys. To use a physical device or running emulator instead, set `useConnectedDevices = true` (and drop `managedDevices`) in the `baselineProfile {}` block of `baselineprofile/build.gradle.kts`.

The `androidApp/build.gradle.kts` enables `dexLayoutOptimization = true` to further optimize DEX file layout based on the profile.

**Customizing the profile:** Edit `BaselineProfileGenerator.kt` to add interactions that exercise your app's critical user journeys (navigation, data loading, etc.).

### Compose Stability Configuration

`config/compose/stability.conf` tells the Compose compiler which types are stable, allowing it to skip recomposition for unchanged parameters. The `convention.compose` plugin passes it to the compiler and tracks it as a compile input, so editing it recompiles.

The default configuration marks the standard library's read-only collection interfaces (`List`, `Set`, `Map`) and `kotlin.time.*` as stable. When you add your own immutable data classes, add them to this file (comments use `//`):

```
// Mark your package's model classes as stable
com.yourapp.model.*
```

Without this, Compose may unnecessarily recompose UI when passing instances of types it cannot verify as stable. The compiler reports (see Performance Profiling) show the effect: a parameter is listed as `stable` when the configuration applies.

## Code Quality Configuration

### Detekt Static Analysis

`config/detekt/detekt.yml` customizes static analysis rules. detekt runs per module (`./gradlew detekt` covers them all) together with the [Compose rules](https://mrmans0n.github.io/compose-rules/). Key choices in the template:

| Rule | Setting | Rationale |
|------|---------|-----------|
| `MaxLineLength` | 120 chars | Wider than the 100-char default; balances readability with modern wide displays |
| `ForbiddenComment` | Bans `TODO:`, `FIXME:`, `STOPSHIP:` | Prevents unfinished work from reaching CI. Use issue tracking instead |
| `FunctionNaming` | `ignoreAnnotated: ['Composable']` | Allows PascalCase `@Composable` function names per Compose conventions |
| `MagicNumber` | Active in production, ignored in tests | Encourages named constants in production code |
| `ReturnCount` | Max 2 returns per function | Keeps functions easy to follow |
| `WildcardImport` | Banned | Prevents import ambiguity |
| `TooManyFunctions` | 11 per file/class, tests excluded | Keeps files focused |
| `Compose:*` | All Compose rules except `PreviewNaming` and `UnstableCollections` | Catches missing modifiers, public previews, Material 2 imports and more |

Test files (`**/test/**`, `**/commonTest/**`, etc.) are excluded from several rules to allow more flexibility in test code.

### Spotless Code Formatting

Each module formats its own sources through the `convention.quality` plugin; the `convention.root` plugin formats files that belong to no module (root scripts, `build-logic/`, docs, config):
- **Kotlin/KTS**: Formatted with ktlint 1.8.0, configured in `.editorconfig` (IntelliJ Kotlin style)
- **XML**: Formatted with Eclipse WTP
- **Markdown/YAML**: Trailing whitespace trimmed, newline enforced at end of file

```bash
./gradlew spotlessApply    # Auto-fix formatting
./gradlew spotlessCheck    # Check without modifying (used in CI)
```

## Platform-Specific Configuration

### Android

The Android app module (`androidApp/`) uses:
- Material 3 theming
- Splash screen API
- Edge-to-edge by default (`enableEdgeToEdge()`)
- Predictive back gesture (`android:enableOnBackInvokedCallback="true"`)
- Per-app language preferences (`@xml/locales_config`, App Bundle language splits disabled)
- Compose Activity
- ProGuard rules for release
- Baseline profile integration with DEX layout optimization

**Adding a new locale:** edit `androidApp/src/main/res/xml/locales_config.xml` and add a
`<locale android:name="…"/>` entry; ship matching string resources under
`res/values-<bcp47>/strings.xml`.

### iOS

The iOS project (`iosApp/`) uses:
- SwiftUI App lifecycle
- Kotlin framework embedding via `ComposeUIViewController`
- Xcode project configuration

## Troubleshooting

### Gradle Sync Fails

1. Verify JDK 21 is available (Gradle provisions it automatically when it is not)
2. Check `JAVA_HOME` environment variable
3. Run `./gradlew --stop` to stop daemon
4. Invalidate caches and restart IDE

### Missing Dependencies

1. Sync project with Gradle files
2. Check version catalog for typos
3. Verify internet connectivity for dependency download

### iOS Build Errors

1. Ensure Xcode 15.0+ is installed
2. Run `./gradlew :shared:linkDebugFrameworkIosSimulatorArm64`
3. Clean Xcode derived data
4. Check framework search paths in Xcode
