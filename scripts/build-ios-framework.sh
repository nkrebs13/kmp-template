#!/bin/bash

# Build script for iOS framework
# This script ensures the shared framework is available for Xcode builds

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_PATH="$REPO_ROOT/shared/build/xcode-frameworks/shared.framework"

echo "Building iOS frameworks..."

# Build iOS frameworks for all targets
cd "$REPO_ROOT"
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
./gradlew :shared:linkDebugFrameworkIosArm64

# Determine which framework to use based on SDK
if [[ "$SDK_NAME" == *"simulator"* ]]; then
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphonesimulator18.5/shared.framework"
else
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphoneos18.5/shared.framework"
fi

# If no specific SDK, default to simulator
if [[ -z "$SDK_NAME" ]]; then
    SOURCE_FRAMEWORK="$REPO_ROOT/shared/build/xcode-frameworks/Debug/iphonesimulator18.5/shared.framework"
fi

# Create symbolic link to the appropriate framework
echo "Linking framework from $SOURCE_FRAMEWORK to $FRAMEWORK_PATH"
rm -f "$FRAMEWORK_PATH"

# Create relative path for the symlink
if [[ "$SDK_NAME" == *"simulator"* ]] || [[ -z "$SDK_NAME" ]]; then
    ln -sf "Debug/iphonesimulator18.5/shared.framework" "$FRAMEWORK_PATH"
else
    ln -sf "Debug/iphoneos18.5/shared.framework" "$FRAMEWORK_PATH"
fi

echo "iOS framework setup complete!"