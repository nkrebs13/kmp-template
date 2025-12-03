# Kotlin Multiplatform Template - Configuration Reference

This document provides detailed configuration information for the Kotlin Multiplatform template, including dependency management, build system configuration, and customization options.

## 🎯 Template Overview

This is a modern, production-ready template featuring:
- **Kotlin 2.1.0+** with latest stable compiler
- **Compose Multiplatform 1.8.0** for shared UI with **Production-Ready iOS Support**
- **100+ Dependencies** managed via version catalog with latest stable versions
- **Stable KMP Libraries** - Room 2.7.2, SQLite 2.5.2 now stable with full KMP support
- **Modern Build System** - AGP 8.12.1, Gradle 9.0 (requires Java 17+)
- **Comprehensive Tooling** for development and CI/CD

## 📋 Version Catalog System

All dependencies are managed through `gradle/libs.versions.toml` for centralized version management.

## Available Features

### Core Features
- `COROUTINES` - Kotlinx Coroutines
- `SERIALIZATION` - Kotlinx Serialization JSON
- `DATETIME` - Kotlinx DateTime
- `IMMUTABLE_COLLECTIONS` - Kotlinx Immutable Collections

### UI Features
- `COMPOSE_MULTIPLATFORM` - Compose Multiplatform UI framework
- `ANDROID_LIFECYCLE` - Android Lifecycle components for Compose
- `ANDROID_SPLASH_SCREEN` - Android splash screen support

### Navigation Features (choose one)
- `VOYAGER_NAVIGATION` - Voyager navigation library
- `DECOMPOSE_NAVIGATION` - Decompose navigation library
- `PRECOMPOSE_NAVIGATION` - PreCompose navigation library

### Dependency Injection
- `KOIN` - Koin dependency injection

### Networking
- `KTOR_CLIENT` - Ktor HTTP client
- `KTOR_WEBSOCKETS` - Ktor WebSocket support

### Storage & Settings
- `DATASTORE` - AndroidX DataStore for preferences
- `MULTIPLATFORM_SETTINGS` - Multiplatform settings library
- `UUID` - UUID generation

### Image Loading
- `COIL` - Coil image loading library

### Logging
- `KERMIT` - Kermit logging library

### Testing
- `TESTING` - Testing libraries (MockK, Turbine, etc.)

## Feature Sets

Predefined combinations of features for common use cases:

### CORE
Basic Kotlin multiplatform functionality:
- Coroutines
- Serialization

### UI
Essential UI development:
- CORE features
- Compose Multiplatform
- Android Lifecycle

### NETWORKING
Network-enabled applications:
- UI features
- Ktor Client
- Koin (for DI)

### FULL_STACK
Complete feature set for full applications:
- All UI and Networking features
- DataStore, Settings, Logging
- Image loading, UUID generation

### MINIMAL
Absolute minimum for basic apps:
- Coroutines only

### TESTING
Testing-focused configuration:
- CORE features
- Testing libraries

## Configuration Files

### Project-Wide Defaults (`project.properties`)

Set default configuration for all modules:

```properties
# Default feature set for new modules
default.features.set=CORE

# Global Android settings
android.compileSdk=34
android.targetSdk=34
android.minSdk=24

# Project metadata
project.name=MyApp
project.group=com.example
project.version=1.0.0
```

### Module-Specific Configuration (`module.properties`)

Each module can have its own `module.properties` file to override defaults:

```properties
# Use a predefined feature set
features.set=FULL_STACK

# Or enable individual features
feature.koin=true
feature.voyager.navigation=true
feature.android.lifecycle=true

# Module-specific Android settings
android.applicationId=com.example.myapp
android.versionCode=1
android.versionName=1.0.0
android.minSdk=24
```

## Examples

### Shared Library Module
For a shared module with comprehensive functionality:

```properties
# shared/module.properties
features.set=FULL_STACK
feature.voyager.navigation=true
feature.android.lifecycle=true
android.minSdk=24
```

### Android App Module
For an Android app with minimal dependencies:

```properties
# androidApp/module.properties
features.set=MINIMAL
feature.koin=true
feature.compose.multiplatform=true
feature.android.splash.screen=true
feature.android.lifecycle=true

android.applicationId=com.example.myapp
android.versionCode=1
android.versionName=1.0.0
android.minSdk=24
```

### Feature-Specific Module
For a module focused on networking:

```properties
# networkModule/module.properties
features.set=NETWORKING
feature.kermit=true
```

### Testing Module
For a module dedicated to testing:

```properties
# testUtils/module.properties
features.set=TESTING
```

## Adding New Modules

1. Create your module directory structure
2. Add a `module.properties` file with desired configuration
3. Create `build.gradle.kts` that applies the appropriate convention plugin:

```kotlin
// For KMP modules
plugins {
    id("kmp-module")
}

// For Android app modules
plugins {
    id("android-app")
}
```

4. Add the module to `settings.gradle.kts`

## Best Practices

### Feature Selection
- Start with **CORE** or **UI** for basic functionality
- Use **FULL_STACK** for main application modules
- Use **MINIMAL** for utility modules that don't need many dependencies
- Enable individual features as needed rather than using large feature sets

### Multi-Module Projects
- Keep shared modules focused with **UI** or **NETWORKING** feature sets
- Use **MINIMAL** for pure utility modules
- Enable platform-specific features only where needed
- Consider creating domain-specific modules with targeted feature sets

### Performance Considerations
- Only enable features you actually use to keep build times fast
- Testing features should only be enabled in test modules
- Image loading and networking features add significant dependencies

## Troubleshooting

### Missing Dependencies
If you get compilation errors about missing classes:
1. Check that the required feature is enabled in your `module.properties`
2. Verify the feature is spelled correctly
3. Make sure you've synced the project after configuration changes

### Unexpected Dependencies
If you see dependencies you don't expect:
1. Check which feature set you're using - feature sets include multiple features
2. Review your `module.properties` for any accidentally enabled individual features
3. Consider using individual features instead of feature sets for more control

### Build Errors
If you encounter build errors after configuration changes:
1. Clean and rebuild the project
2. Invalidate caches and restart your IDE
3. Check that your Gradle wrapper is up to date