# Project: kmp-template

Kotlin Multiplatform project template for Android + iOS apps.

## Stack
- Kotlin Multiplatform (KMP), Kotlin 2.x
- Compose Multiplatform for shared UI
- Gradle with version catalog (`libs.versions.toml`)
- Targets: Android, iOS (iosApp/)

## Build & Test
```
./gradlew build              # full build
./gradlew test               # unit tests
./gradlew detekt             # static analysis
./gradlew :shared:test       # shared module tests only
```

## Never touch
- `gradle/wrapper/` — Gradle wrapper files
- `.github/workflows/` — CI configuration
- `iosApp/` — iOS Xcode project files (fragile, don't modify)
- `local.properties` — machine-local SDK paths
