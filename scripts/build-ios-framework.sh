#!/bin/bash

# Build script for iOS framework
# This script ensures the shared framework is available for Xcode builds

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORK_PATH="$REPO_ROOT/shared/build/xcode-frameworks/shared.framework"

# Detect SDK versions dynamically
SIMULATOR_SDK=$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null || true)
DEVICE_SDK=$(xcrun --sdk iphoneos --show-sdk-version 2>/dev/null || true)

if [ -z "$SIMULATOR_SDK" ] && [ -z "$DEVICE_SDK" ]; then
    echo "Error: Could not detect iOS SDK versions. Is Xcode installed?"
    echo "  Install Xcode from the App Store or run: xcode-select --install"
    exit 1
fi

echo "Building iOS frameworks..."
echo "  Simulator SDK: $SIMULATOR_SDK"
echo "  Device SDK: $DEVICE_SDK"

# Build iOS frameworks for all targets
cd "$REPO_ROOT"
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
./gradlew :shared:linkDebugFrameworkIosArm64

# Determine which framework to use based on SDK
if [[ "$SDK_NAME" == *"simulator"* ]]; then
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphonesimulator${SIMULATOR_SDK}/shared.framework"
else
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphoneos${DEVICE_SDK}/shared.framework"
fi

# If no specific SDK, default to simulator
if [[ -z "$SDK_NAME" ]]; then
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphonesimulator${SIMULATOR_SDK}/shared.framework"
fi

# Create symbolic link to the appropriate framework
echo "Linking framework from $SOURCE_FRAMEWORK to $FRAMEWORK_PATH"
rm -f "$FRAMEWORK_PATH"

# Create relative path for the symlink
if [[ "$SDK_NAME" == *"simulator"* ]] || [[ -z "$SDK_NAME" ]]; then
    ln -sf "Debug/iphonesimulator${SIMULATOR_SDK}/shared.framework" "$FRAMEWORK_PATH"
else
    ln -sf "Debug/iphoneos${DEVICE_SDK}/shared.framework" "$FRAMEWORK_PATH"
fi

echo "iOS framework setup complete!"
