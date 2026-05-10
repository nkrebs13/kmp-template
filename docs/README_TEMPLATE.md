# __PROJECT_NAME__

A Kotlin Multiplatform application for iOS and Android.

## 🚀 Getting Started

### Prerequisites

- **JDK 17 or higher** - **Required** for Gradle 9.0 and build system compatibility
- **Android Studio Meerkat (2024.3.2) or newer** - Latest stable IDE with KMP support
- **Xcode 15.0 or newer** - For iOS development and latest iOS SDK support  
- **macOS** - Required for iOS development and Xcode

### Building the Project

#### Android
```bash
./gradlew :androidApp:assembleDebug
```

#### iOS
1. Open `iosApp/iosApp.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run

## 📱 Features

- Cross-platform shared business logic
- Shared UI with Compose Multiplatform
- Platform detection via expect/actual pattern
- Unit testing with kotlin.test

## 🏗️ Architecture

This app uses Kotlin Multiplatform with Compose Multiplatform for shared UI:
- **Shared Module**: Cross-platform UI and business logic
- **Android App**: Native Android entry point using shared Compose UI
- **iOS App**: Native SwiftUI shell hosting shared Compose UI via ComposeUIViewController

## 🧪 Testing

Run all tests:
```bash
./gradlew :shared:allTests
```

## 🔐 Release Signing

To sign release APKs, add your keystore details to `local.properties` (never commit this file):

```
signing.storeFile=/absolute/path/to/release.jks
signing.storePassword=your_store_password
signing.keyAlias=your_key_alias
signing.keyPassword=your_key_password
```

Then uncomment the `signingConfigs` block in `androidApp/build.gradle.kts`.

Generate a new keystore if you don't have one:
```bash
keytool -genkey -v -keystore release.jks -alias key0 -keyAlg RSA -keySize 2048 -validity 10000
```

For CI/CD, inject signing values as environment variables and read them in `build.gradle.kts` instead of `local.properties`.

## ⚡ Baseline Profiles

This template includes a `baselineprofile` module for [Android Baseline Profiles](https://developer.android.com/topic/performance/baselineprofiles/overview) — a performance optimization that pre-compiles critical code paths, reducing app startup by up to 40%.

To generate a profile:
1. Connect a physical device (API 28+) or configure a managed device in `baselineprofile/build.gradle.kts`
2. Run: `./gradlew :baselineprofile:generateBaselineProfile`
3. Commit the generated `baseline-prof.txt` in `androidApp/src/main/`

The module is pre-wired with `dexLayoutOptimization = true`. Most projects can ignore this until they have stable user flows worth optimizing.

## 📦 Tech Stack

- **Kotlin Multiplatform**: Code sharing between platforms
- **Compose Multiplatform**: Shared UI framework
- **SwiftUI**: iOS app shell with Compose integration
- **Kotlinx Coroutines**: Asynchronous programming
- **Material 3**: Design system

## 🔧 Development

### Code Style
```bash
# Format code
./gradlew spotlessApply

# Check code quality
./gradlew detekt
```

## 📄 License

Copyright © 2026 __PROJECT_NAME__. All rights reserved.