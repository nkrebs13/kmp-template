# Template

A Kotlin Multiplatform application for iOS and Android.

## 🚀 Getting Started

### Prerequisites

- **JDK 17 or higher** - **Required** for Gradle 9.0 and build system compatibility
- **Android Studio Ladybug (2024.2.1) or newer** - Latest stable IDE with KMP support
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

Copyright © 2026 Template. All rights reserved.