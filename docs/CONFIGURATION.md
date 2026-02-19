# Kotlin Multiplatform Template - Configuration Reference

This document provides detailed configuration information for the Kotlin Multiplatform template, including dependency management, build system configuration, and customization options.

## Template Stack

| Component | Version |
|-----------|---------|
| Kotlin | 2.3.0 |
| Compose Multiplatform | 1.10.0 |
| Android Gradle Plugin | 9.0.0 |
| Gradle | 9.3.0 |
| JDK Requirement | 17+ |

## Version Catalog System

All dependencies are managed through `gradle/libs.versions.toml` for centralized version management.

### Core Versions

| Dependency | Version | Purpose |
|------------|---------|---------|
| kotlin | 2.3.0 | Kotlin compiler and stdlib |
| compose | 1.10.0 | Compose Multiplatform UI framework |
| agp | 9.0.0 | Android Gradle Plugin |
| kotlinx-coroutines | 1.10.2 | Async/concurrency |
| kotlinx-serialization | 1.10.0 | JSON serialization |

### AndroidX Versions

| Dependency | Version | Purpose |
|------------|---------|---------|
| androidx-core | 1.17.0 | Android core KTX |
| androidx-appcompat | 1.7.1 | AppCompat library |
| androidx-activity | 1.12.2 | Activity APIs |
| androidx-lifecycle | 2.10.0 | Lifecycle components |
| androidx-splashscreen | 1.2.0 | Splash screen API |
| androidx-compose-bom | 2026.01.00 | Compose BOM |
| androidx-compose-material3 | 1.4.0 | Material 3 components |

### Code Quality Tools

| Tool | Version | Purpose |
|------|---------|---------|
| detekt | 1.23.8 | Static analysis |
| spotless | 8.1.0 | Code formatting |
| ktlint | 1.8.0 | Kotlin linter |
| ksp | 2.3.3 | Kotlin Symbol Processing |

## Configuration Files

### Project-Wide Settings (`gradle.properties`)

```properties
# Android SDK versions
android.compileSdk=36
android.targetSdk=36
android.minSdk=24

# Kotlin settings
kotlin.code.style=official

# Gradle performance
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
```

### Module Configuration

Each module's `build.gradle.kts` can configure:

```kotlin
android {
    namespace = "com.example.myapp"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = libs.versions.android.minSdk.get().toInt()
        targetSdk = libs.versions.android.targetSdk.get().toInt()
        versionCode = 1
        versionName = "1.0.0"
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
   ktor = "3.2.0"
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

# iOS Simulator (Intel)
./gradlew :shared:linkDebugFrameworkIosX64
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

# All checks
./gradlew check
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

The iOS app hosts the shared Compose UI through a two-layer bridge:

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

- `BaselineProfileGenerator` runs on a connected device or emulator (min SDK 28)
- It launches the app, waits for idle, and records which code paths are exercised
- The generated profile is bundled with the APK so ART can AOT-compile critical paths

**Running baseline profile generation:**

```bash
# Requires a connected device or emulator (API 28+)
./gradlew :baselineprofile:generateBaselineProfile
```

The `androidApp/build.gradle.kts` enables `dexLayoutOptimization = true` to further optimize DEX file layout based on the profile.

**Customizing the profile:** Edit `BaselineProfileGenerator.kt` to add interactions that exercise your app's critical user journeys (navigation, data loading, etc.).

### Compose Stability Configuration

The `compose-stability.conf` file at the project root tells the Compose compiler which types are stable, allowing it to skip recomposition for unchanged parameters. This is referenced in `gradle.properties`:

```properties
compose.multiplatform.stabilityConfigPath=compose-stability.conf
```

The default configuration marks standard library collections, `kotlinx.datetime`, `java.time`, and `UUID` as stable. When you add your own immutable data classes, add them to this file:

```
# Mark your package's model classes as stable
com.yourpackage.model.*
```

Without this, Compose may unnecessarily recompose UI when passing instances of types it cannot verify as stable.

## Scripts

### `scripts/build-ios-framework.sh`

A helper script that builds the shared iOS framework for both simulator and device targets, then creates a symlink at `shared/build/xcode-frameworks/shared.framework` pointing to the correct variant.

```bash
./scripts/build-ios-framework.sh
```

The script:
- Detects installed iOS SDK versions automatically
- Builds both `IosSimulatorArm64` and `IosArm64` debug frameworks via Gradle
- Creates a symlink based on `$SDK_NAME` (set by Xcode during builds) or defaults to simulator

Use this when Xcode cannot find the framework, or as a build phase script in your Xcode project. For most development, the Gradle tasks called directly are sufficient:

```bash
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64   # Simulator
./gradlew :shared:linkReleaseFrameworkIosArm64           # Device
```

## Code Quality Configuration

### Detekt Static Analysis

The `detekt-config.yml` file customizes static analysis rules. Key choices in the template:

| Rule | Setting | Rationale |
|------|---------|-----------|
| `MaxLineLength` | 120 chars | Wider than the 100-char default; balances readability with modern wide displays |
| `ForbiddenComment` | Bans `TODO:`, `FIXME:`, `STOPSHIP:` | Prevents unfinished work from reaching CI. Use issue tracking instead |
| `FunctionNaming` | `ignoreAnnotated: ['Composable']` | Allows PascalCase `@Composable` function names per Compose conventions |
| `MagicNumber` | Active in production, ignored in tests | Encourages named constants in production code |
| `ReturnCount` | Max 2 returns per function | Keeps functions easy to follow |
| `WildcardImport` | Banned (except `java.util.*`) | Prevents import ambiguity |
| `TooManyFunctions` | 11 per file/class, tests excluded | Keeps files focused |

Test files (`**/test/**`, `**/commonTest/**`, etc.) are excluded from several rules to allow more flexibility in test code.

### Spotless Code Formatting

Spotless is configured in the root `build.gradle.kts`:
- **Kotlin/KTS**: Formatted with ktlint 1.8.0
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
- Compose Activity
- ProGuard rules for release
- Baseline profile integration with DEX layout optimization

### iOS

The iOS project (`iosApp/`) uses:
- SwiftUI App lifecycle
- Kotlin framework embedding via `ComposeUIViewController`
- Xcode project configuration

## Troubleshooting

### Gradle Sync Fails

1. Verify JDK 17+ is installed
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
