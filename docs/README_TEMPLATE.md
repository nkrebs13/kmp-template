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
- Native UI for each platform
- Modern architecture with clean separation of concerns
- Comprehensive testing setup

## 🏗️ Architecture

This app follows Clean Architecture principles with:
- **Presentation Layer**: Platform-specific UI
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Repository pattern with remote and local data sources

## 🧪 Testing

Run all tests:
```bash
./gradlew test
```

## 📦 Tech Stack

- **Kotlin Multiplatform**: Code sharing between platforms
- **Compose UI**: Android UI framework
- **SwiftUI**: iOS UI framework
- **Ktor**: Networking
- **SQLDelight**: Local database
- **Koin**: Dependency injection
- **Kotlinx Coroutines**: Asynchronous programming

## 🔧 Development

### Code Style
```bash
# Format code
./gradlew spotlessApply

# Check code quality
./gradlew detekt
```

## 📄 License

Copyright © 2024 Template. All rights reserved.