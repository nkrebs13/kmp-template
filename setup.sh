#!/bin/bash

# Template Setup Script
# This script renames the template project to your desired project name

set -e

echo "================================================"
echo "    Kotlin Multiplatform Template Setup"
echo "================================================"
echo ""

# Get current directory name as default
CURRENT_DIR=$(basename "$PWD")

# Prompt for project details
read -p "Enter your new project name (e.g., MyAwesomeApp): " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty"
    exit 1
fi

read -p "Enter your package name (e.g., com.company.app): " PACKAGE_NAME
if [ -z "$PACKAGE_NAME" ]; then
    echo "Error: Package name cannot be empty"
    exit 1
fi

read -p "Enter iOS bundle identifier (default: $PACKAGE_NAME): " IOS_BUNDLE_ID
if [ -z "$IOS_BUNDLE_ID" ]; then
    IOS_BUNDLE_ID=$PACKAGE_NAME
fi

# Convert package name to directory structure
PACKAGE_PATH=$(echo $PACKAGE_NAME | tr '.' '/')

# Confirmation
echo ""
echo "Configuration:"
echo "  Project Name: $PROJECT_NAME"
echo "  Package Name: $PACKAGE_NAME"
echo "  iOS Bundle ID: $IOS_BUNDLE_ID"
echo ""
read -p "Continue with these settings? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Setup cancelled"
    exit 0
fi

echo ""
echo "Starting project setup..."

# Function to replace text in files
replace_in_file() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/$1/$2/g" "$3"
    else
        # Linux
        sed -i "s/$1/$2/g" "$3"
    fi
}

# Function to replace text in all files in directory
replace_in_directory() {
    find "$3" -type f \( -name "*.kt" -o -name "*.kts" -o -name "*.xml" -o -name "*.gradle" -o -name "*.properties" -o -name "*.swift" -o -name "*.plist" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" \) -exec sh -c '
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i "" "s/'"$1"'/'"$2"'/g" "$0"
        else
            sed -i "s/'"$1"'/'"$2"'/g" "$0"
        fi
    ' {} \;
}

# 1. Update settings.gradle.kts
echo "• Updating project settings..."
replace_in_file "rootProject.name = \"Template\"" "rootProject.name = \"$PROJECT_NAME\"" "settings.gradle.kts"

# 2. Update package names in all Kotlin files
echo "• Updating package names..."
# Replace the full package paths to avoid partial matches
replace_in_directory "com.template.shared" "${PACKAGE_NAME}.shared" "."
replace_in_directory "com\/template\/shared" "$(echo $PACKAGE_NAME | sed 's/\./\\\//g')\/shared" "."
replace_in_directory "com.template.android" "$PACKAGE_NAME" "."
replace_in_directory "com\/template\/android" "$(echo $PACKAGE_NAME | sed 's/\./\\\//g')" "."
replace_in_directory "com.template.baselineprofile" "${PACKAGE_NAME}.baselineprofile" "."
replace_in_directory "com\/template\/baselineprofile" "$(echo $PACKAGE_NAME | sed 's/\./\\\//g')\/baselineprofile" "."
if [ -f "androidApp/src/main/kotlin/MainActivity.kt" ]; then
    replace_in_file "package com.template.android" "package $PACKAGE_NAME" "androidApp/src/main/kotlin/MainActivity.kt"
fi

# 3. Update Android application ID
echo "• Updating Android configuration..."
replace_in_file "applicationId = \"com.template.android\"" "applicationId = \"$PACKAGE_NAME\"" "androidApp/build.gradle.kts"
replace_in_file "namespace = \"com.template.android\"" "namespace = \"$PACKAGE_NAME\"" "androidApp/build.gradle.kts"
replace_in_file "namespace = \"com.template.shared\"" "namespace = \"${PACKAGE_NAME}.shared\"" "shared/build.gradle.kts"
replace_in_file "namespace = \"com.template.baselineprofile\"" "namespace = \"${PACKAGE_NAME}.baselineprofile\"" "baselineprofile/build.gradle.kts"
if [ -f "baselineprofile/src/androidTest/java/com/template/baselineprofile/BaselineProfileGenerator.kt" ]; then
    replace_in_file "packageName = \"com.template.android\"" "packageName = \"$PACKAGE_NAME\"" "baselineprofile/src/androidTest/java/com/template/baselineprofile/BaselineProfileGenerator.kt"
fi

# 4. Update iOS bundle identifier
echo "• Updating iOS configuration..."
if [ -f "iosApp/iosApp.xcodeproj/project.pbxproj" ]; then
    replace_in_file "PRODUCT_BUNDLE_IDENTIFIER = com.template.ios" "PRODUCT_BUNDLE_IDENTIFIER = $IOS_BUNDLE_ID" "iosApp/iosApp.xcodeproj/project.pbxproj"
fi

# 5. Update app names
echo "• Updating app names..."
if [ -f "androidApp/src/main/res/values/strings.xml" ]; then
    replace_in_file ">Template<" ">$PROJECT_NAME<" "androidApp/src/main/res/values/strings.xml"
fi
# Update Swift app name
if [ -f "iosApp/iosApp/TemplateApp.swift" ]; then
    replace_in_file "TemplateApp" "${PROJECT_NAME}App" "iosApp/iosApp/TemplateApp.swift"
fi

# 6. Rename directories to match new package structure
echo "• Restructuring directories..."

# Create new package directories
mkdir -p "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/commonTest/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/androidMain/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/androidUnitTest/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/iosMain/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/iosTest/kotlin/$PACKAGE_PATH/shared"
mkdir -p "androidApp/src/main/kotlin/$PACKAGE_PATH"
mkdir -p "androidApp/src/androidTest/kotlin/$PACKAGE_PATH"
mkdir -p "baselineprofile/src/androidTest/java/$PACKAGE_PATH/baselineprofile"

# Move files to new package structure
if [ -d "shared/src/commonMain/kotlin/com/template/shared" ]; then
    mv shared/src/commonMain/kotlin/com/template/shared/* "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared/" 2>/dev/null || true
fi
if [ -d "shared/src/androidMain/kotlin/com/template/shared" ]; then
    mv shared/src/androidMain/kotlin/com/template/shared/* "shared/src/androidMain/kotlin/$PACKAGE_PATH/shared/" 2>/dev/null || true
fi
if [ -d "shared/src/iosMain/kotlin/com/template/shared" ]; then
    mv shared/src/iosMain/kotlin/com/template/shared/* "shared/src/iosMain/kotlin/$PACKAGE_PATH/shared/" 2>/dev/null || true
fi
if [ -d "androidApp/src/main/kotlin/com/template/android" ]; then
    mv androidApp/src/main/kotlin/com/template/android/* "androidApp/src/main/kotlin/$PACKAGE_PATH/" 2>/dev/null || true
fi
if [ -d "baselineprofile/src/androidTest/java/com/template/baselineprofile" ]; then
    mv baselineprofile/src/androidTest/java/com/template/baselineprofile/* "baselineprofile/src/androidTest/java/$PACKAGE_PATH/baselineprofile/" 2>/dev/null || true
fi

# Clean up old directories
rm -rf shared/src/*/kotlin/com/template 2>/dev/null || true
rm -rf androidApp/src/*/kotlin/com/template 2>/dev/null || true
rm -rf baselineprofile/src/*/java/com/template 2>/dev/null || true

# 7. Rename Swift files if needed
if [ -f "iosApp/iosApp/TemplateApp.swift" ]; then
    mv "iosApp/iosApp/TemplateApp.swift" "iosApp/iosApp/${PROJECT_NAME}App.swift" 2>/dev/null || true
fi

# 8. Process README files
echo "• Setting up documentation..."
if [ -f "docs/README_TEMPLATE.md" ]; then
    cp docs/README_TEMPLATE.md README.md
    replace_in_file "Template" "$PROJECT_NAME" "README.md"
    replace_in_file "com.template" "$PACKAGE_NAME" "README.md"
fi

# 9. Remove template-specific files and directories
echo "• Cleaning up template files..."
rm -f README_TEMPLATE.md 2>/dev/null || true
rm -f local.properties.template 2>/dev/null || true
rm -rf docs 2>/dev/null || true
rm -rf scripts 2>/dev/null || true
rm -f setup.sh 2>/dev/null || true

# 10. Clean up development-specific directories and files
echo "• Cleaning up development artifacts..."
rm -rf .gradle 2>/dev/null || true
rm -rf .idea 2>/dev/null || true
rm -rf .kotlin 2>/dev/null || true
rm -rf build 2>/dev/null || true
rm -rf .claude 2>/dev/null || true
rm -rf .vscode 2>/dev/null || true
rm -rf .fleet 2>/dev/null || true
rm -rf .cursor 2>/dev/null || true

# 11. Initialize git repository
echo "• Initializing Git repository..."
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit: $PROJECT_NAME"
    echo "  Git repository initialized with initial commit"
else
    echo "  Git repository already exists, skipping initialization"
fi

echo ""
echo "================================================"
echo "    Setup Complete! 🎉"
echo "================================================"
echo ""
echo "Your project '$PROJECT_NAME' is ready!"
echo ""
echo "Next steps:"
echo "  1. Create local.properties file with: sdk.dir=/path/to/android/sdk"
echo "  2. Open the project in Android Studio or your preferred IDE"
echo "  3. Sync Gradle to download dependencies"
echo "  4. For iOS development, open iosApp/iosApp.xcodeproj in Xcode"
echo "  5. Run './gradlew spotlessApply' to format your code"
echo "  6. Run './gradlew detekt' to check code quality"
echo ""
echo "Happy coding! 🚀"