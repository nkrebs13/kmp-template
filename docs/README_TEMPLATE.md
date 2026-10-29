# __PROJECT_NAME__

A Kotlin Multiplatform application for iOS, Android and desktop (JVM).

## 🚀 Getting Started

### Prerequisites

- **JDK 21** - the build toolchain. The Gradle wrapper needs some Java runtime on `PATH` or
  `JAVA_HOME` to start; installing JDK 21 directly is simplest, otherwise Gradle downloads it
- **Android Studio Meerkat (2024.3.2) or newer** - Latest stable IDE with KMP support
- **Xcode 16.0 or newer** - For iOS development (the project uses Xcode 16 synchronized folders); the app targets iOS 16+
- **macOS** - Required for iOS development and Xcode

### Building the Project

#### Android
```bash
./gradlew :androidApp:assembleDebug
```

#### Desktop
```bash
./gradlew :desktopApp:run                           # run the app
./gradlew :desktopApp:hotRun --auto                 # run with Compose Hot Reload (edits appear live)
./gradlew :desktopApp:packageDistributionForCurrentOS   # .dmg on macOS, .msi on Windows, .deb on Linux
```

Packaging needs a non-Homebrew JDK 21 (Temurin, Corretto or JetBrains Runtime).

#### iOS
App settings (display name, bundle ID, version, build number, deployment target) live in
`iosApp/Configuration/Config.xcconfig`. Change them there, not in Xcode's build settings editor.

To run on a device, set your Apple Developer team once (the file is gitignored):
```bash
cp iosApp/Configuration/Local.xcconfig.example iosApp/Configuration/Local.xcconfig
# then edit TEAM_ID in Local.xcconfig
```

In Xcode: open `iosApp/iosApp.xcodeproj`, pick a simulator or device, and run.

From the command line, on a simulator:
```bash
# Build for the simulator (also runs the Gradle phase that builds the shared framework)
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build

# Boot a simulator, install, launch
xcrun simctl list devices available            # pick an iPhone
xcrun simctl boot "<device name or UDID>"
open -a Simulator
xcrun simctl install booted build/xcode/Build/Products/Debug-iphonesimulator/iosApp.app
xcrun simctl launch booted __BUNDLE_ID__
```

## 📱 Features

- Cross-platform shared business logic
- Shared UI with Compose Multiplatform
- Platform detection via expect/actual pattern
- Unit testing with kotlin.test

## 🏗️ Architecture

This app uses Kotlin Multiplatform with Compose Multiplatform for shared UI:
- **Shared Module**: Cross-platform UI and business logic
- **Android App**: Native Android entry point using shared Compose UI
- **Desktop App**: Compose for Desktop window (`desktopApp`) hosting the shared Compose UI
- **iOS App**: Native SwiftUI shell hosting shared Compose UI via ComposeUIViewController

## 🧪 Testing

Run all tests:
```bash
./gradlew :shared:allTests
```

## 🔐 Release Signing

To sign release APKs, add your keystore details to `local.properties` (never commit this file):

```properties
signing.storeFile=/absolute/path/to/release.jks
signing.storePassword=your_store_password
signing.keyAlias=your_key_alias
signing.keyPassword=your_key_password
```

`signing.storeFile` is absolute, or relative to the repository root. The build signs the release variant once all four values are set in one place; with none set, the release APK is unsigned. Setting only some of them makes release packaging fail with a message naming the missing keys; debug builds keep working.

Generate a new keystore if you don't have one:
```bash
keytool -genkey -v -keystore release.jks -alias key0 -keyalg RSA -keysize 2048 -validity 10000
```

For CI/CD, set the environment variables `SIGNING_STORE_FILE`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS` and `SIGNING_KEY_PASSWORD` instead. If any of them is set, all four must be, and `local.properties` is ignored.

## ⚡ Baseline Profiles

This template includes a `baselineprofile` module for [Android Baseline Profiles](https://developer.android.com/topic/performance/baselineprofiles/overview), which pre-compile the startup path so the app starts faster after install.

A starting profile for the template's startup path is committed in `androidApp/src/release/generated/baselineProfiles/`, and `assembleRelease` packs it into the APK. Regenerate it after changing startup behaviour:

```bash
./gradlew :androidApp:generateBaselineProfile
```

This runs `BaselineProfileGenerator` on a Gradle Managed Device and rewrites the committed files; see `docs/CONFIGURATION.md` for details.

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
