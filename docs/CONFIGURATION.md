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

## Platform-Specific Configuration

### Android

The Android app module (`androidApp/`) uses:
- Material 3 theming
- Splash screen API
- Compose Activity
- ProGuard rules for release

### iOS

The iOS project (`iosApp/`) uses:
- SwiftUI App lifecycle
- Kotlin framework embedding
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
