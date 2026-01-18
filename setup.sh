#!/bin/bash

# Template Setup Script
# This script renames the template project to your desired project name

set -e

# Ensure we're running in bash (not sh)
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash. Please run with: bash setup.sh"
    exit 1
fi

# Verify we're in the correct directory (should have settings.gradle.kts)
if [ ! -f "settings.gradle.kts" ]; then
    echo "Error: setup.sh must be run from the template project root directory"
    echo "       (the directory containing settings.gradle.kts)"
    exit 1
fi

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

# Validate project name: alphanumeric, starts with letter
if ! [[ "$PROJECT_NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
    echo "Error: Project name must start with a letter and contain only alphanumeric characters"
    exit 1
fi

read -p "Enter your package name (e.g., com.company.app): " PACKAGE_NAME
if [ -z "$PACKAGE_NAME" ]; then
    echo "Error: Package name cannot be empty"
    exit 1
fi

# Validate package name: lowercase, 2+ parts, Java conventions
if ! [[ "$PACKAGE_NAME" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]]; then
    echo "Error: Invalid package name format"
    echo "  - Must be lowercase"
    echo "  - Must have at least 2 parts separated by dots"
    echo "  - Each part must start with a letter"
    echo "  - Example: com.company.app"
    exit 1
fi

# Check for Java keywords and reserved words in package name parts
# This list includes:
# - All Java keywords (JLS 3.9)
# - Reserved keywords (const, goto)
# - Literals that cannot be identifiers (true, false, null)
# - Underscore (reserved since Java 9)
# - Contextual keywords that should be avoided (var, yield, record, sealed, permits)
JAVA_KEYWORDS=(
    # Keywords
    "abstract" "assert" "boolean" "break" "byte" "case" "catch" "char" "class"
    "const" "continue" "default" "do" "double" "else" "enum" "extends" "final"
    "finally" "float" "for" "goto" "if" "implements" "import" "instanceof" "int"
    "interface" "long" "native" "new" "package" "private" "protected" "public"
    "return" "short" "static" "strictfp" "super" "switch" "synchronized" "this"
    "throw" "throws" "transient" "try" "void" "volatile" "while"
    # Literals (not technically keywords but cannot be used as identifiers)
    "true" "false" "null"
    # Reserved identifier (Java 9+)
    "_"
    # Contextual keywords (Java 10+) - technically allowed in some contexts but problematic
    "var" "yield" "record" "sealed" "permits"
)

# Build regex pattern from array
JAVA_KEYWORDS_PATTERN=$(IFS='|'; echo "${JAVA_KEYWORDS[*]}")

IFS='.' read -ra PARTS <<< "$PACKAGE_NAME"
for part in "${PARTS[@]}"; do
    if [[ "$part" =~ ^($JAVA_KEYWORDS_PATTERN)$ ]]; then
        echo "Error: Package name contains Java keyword or reserved word: '$part'"
        echo "  - Java keywords and reserved words cannot be used as package name components"
        echo "  - Consider adding a prefix or suffix, e.g., '${part}s' or 'my${part}'"
        exit 1
    fi
done

read -p "Enter iOS bundle identifier (default: $PACKAGE_NAME): " IOS_BUNDLE_ID
if [ -z "$IOS_BUNDLE_ID" ]; then
    IOS_BUNDLE_ID="$PACKAGE_NAME"
fi

# Validate iOS bundle identifier (similar rules to package name but allows hyphens)
if ! [[ "$IOS_BUNDLE_ID" =~ ^[a-zA-Z][a-zA-Z0-9-]*(\.[a-zA-Z][a-zA-Z0-9-]*)+$ ]]; then
    echo "Error: Invalid iOS bundle identifier format"
    echo "  - Must have at least 2 parts separated by dots"
    echo "  - Each part must start with a letter"
    echo "  - Can contain letters, numbers, and hyphens"
    echo "  - Example: com.company.my-app"
    exit 1
fi

# Convert package name to directory structure
PACKAGE_PATH=$(echo "$PACKAGE_NAME" | tr '.' '/')

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

# Function to replace text in files with proper escaping
replace_in_file() {
    local search="$1"
    local replace="$2"
    local file="$3"

    # Check file exists
    if [ ! -f "$file" ]; then
        echo "  Warning: File not found: $file"
        return 1
    fi

    # Escape special sed characters in search pattern
    # Order matters: escape backslash first, then other special chars
    local escaped_search=$(printf '%s\n' "$search" | sed -e 's/[]\/$*.^[]/\\&/g')
    # Escape special sed characters in replacement (& and \ and /)
    local escaped_replace=$(printf '%s\n' "$replace" | sed -e 's/[\/&]/\\&/g')

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/${escaped_search}/${escaped_replace}/g" "$file"
    else
        # Linux
        sed -i "s/${escaped_search}/${escaped_replace}/g" "$file"
    fi
}

# Function to replace text in all files in directory
# Arguments: search_pattern replacement_text directory
replace_in_directory() {
    local search="$1"
    local replace="$2"
    local dir="$3"

    # Escape special sed characters in search pattern
    local escaped_search=$(printf '%s\n' "$search" | sed -e 's/[]\/$*.^[]/\\&/g')
    # Escape special sed characters in replacement
    local escaped_replace=$(printf '%s\n' "$replace" | sed -e 's/[\/&]/\\&/g')

    # Detect OS once and store sed command variant
    local sed_inplace
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed_inplace=(-i '')
    else
        sed_inplace=(-i)
    fi

    # Find and process files
    while IFS= read -r -d '' file; do
        sed "${sed_inplace[@]}" "s/${escaped_search}/${escaped_replace}/g" "$file"
    done < <(find "$dir" -type f \( \
        -name "*.kt" -o -name "*.kts" -o -name "*.xml" -o -name "*.gradle" \
        -o -name "*.properties" -o -name "*.swift" -o -name "*.plist" \
        -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" \
        -o -name "*.pbxproj" -o -name "*.pro" \
    \) -print0 2>/dev/null)
}

# 1. Update settings.gradle.kts
echo "• Updating project settings..."
replace_in_file "rootProject.name = \"Template\"" "rootProject.name = \"$PROJECT_NAME\"" "settings.gradle.kts"

# 2. Update package names in all Kotlin files
echo "• Updating package names..."
# Replace the full package paths to avoid partial matches
# Note: replace_in_directory handles escaping internally, use literal strings
replace_in_directory "com.template.shared" "${PACKAGE_NAME}.shared" "."
replace_in_directory "com/template/shared" "${PACKAGE_PATH}/shared" "."
replace_in_directory "com.template.android" "$PACKAGE_NAME" "."
replace_in_directory "com/template/android" "$PACKAGE_PATH" "."
replace_in_directory "com.template.baselineprofile" "${PACKAGE_NAME}.baselineprofile" "."
replace_in_directory "com/template/baselineprofile" "${PACKAGE_PATH}/baselineprofile" "."
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

# 4. Update iOS bundle identifier and project references
echo "• Updating iOS configuration..."
if [ -f "iosApp/iosApp.xcodeproj/project.pbxproj" ]; then
    # Update bundle identifier (all occurrences) - use replace_in_file for proper escaping
    replace_in_file "com.template.ios" "$IOS_BUNDLE_ID" "iosApp/iosApp.xcodeproj/project.pbxproj"
    # Update Swift file references in Xcode project
    replace_in_file "TemplateApp.swift" "${PROJECT_NAME}App.swift" "iosApp/iosApp.xcodeproj/project.pbxproj"
fi

# 4b. Update ProGuard rules with new package name
echo "• Updating ProGuard configuration..."
if [ -f "androidApp/proguard-rules.pro" ]; then
    replace_in_file "com.template" "$PACKAGE_NAME" "androidApp/proguard-rules.pro"
fi

# 5. Update app names
echo "• Updating app names..."
if [ -f "androidApp/src/main/res/values/strings.xml" ]; then
    replace_in_file ">Template<" ">$PROJECT_NAME<" "androidApp/src/main/res/values/strings.xml"
fi
# Update theme name
if [ -f "androidApp/src/main/res/values/themes.xml" ]; then
    replace_in_file "Theme.Template" "Theme.${PROJECT_NAME}" "androidApp/src/main/res/values/themes.xml"
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
    replace_in_file "Template" "$PROJECT_NAME" "README.md" || true
    replace_in_file "com.template" "$PACKAGE_NAME" "README.md" || true
else
    echo "  Note: docs/README_TEMPLATE.md not found, keeping existing README.md"
fi

# 9. Remove template-specific files and directories
echo "• Cleaning up template files..."
rm -f README_TEMPLATE.md 2>/dev/null || true
rm -f local.properties.template 2>/dev/null || true
rm -f CLAUDE.md 2>/dev/null || true
rm -rf docs 2>/dev/null || true
rm -rf scripts 2>/dev/null || true
rm -f setup.sh 2>/dev/null || true
# Remove template-specific community files
rm -f CONTRIBUTING.md 2>/dev/null || true
rm -f SECURITY.md 2>/dev/null || true
rm -f CODE_OF_CONDUCT.md 2>/dev/null || true
rm -f CHANGELOG.md 2>/dev/null || true
rm -rf .github 2>/dev/null || true

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

# 11. Verify template replacement
echo "• Verifying template replacement..."
# Comprehensive check for template references across all relevant file types
REMAINING=$(grep -ri "com\.template\|TemplateApp" . \
    --include="*.kt" --include="*.kts" --include="*.xml" --include="*.swift" \
    --include="*.plist" --include="*.pro" --include="*.pbxproj" \
    --exclude-dir=.git --exclude-dir=build 2>/dev/null | wc -l | tr -d ' ')
if [ "$REMAINING" -gt 0 ]; then
    echo ""
    echo "WARNING: Found $REMAINING occurrences of template references that may need manual review:"
    grep -ri "com\.template\|TemplateApp" . \
        --include="*.kt" --include="*.kts" --include="*.xml" --include="*.swift" \
        --include="*.plist" --include="*.pro" --include="*.pbxproj" \
        --exclude-dir=.git --exclude-dir=build -l 2>/dev/null
    echo ""
else
    echo "  All template references successfully replaced"
fi

# 12. Initialize git repository
echo "• Initializing Git repository..."
if [ ! -d ".git" ]; then
    git init
    git add .
    # Check if git user is configured
    if git config user.name >/dev/null 2>&1 && git config user.email >/dev/null 2>&1; then
        git commit -m "Initial commit: $PROJECT_NAME"
        echo "  Git repository initialized with initial commit"
    else
        echo "  Git repository initialized (commit skipped - please configure git user.name and user.email)"
        echo "  Run: git config user.name \"Your Name\""
        echo "       git config user.email \"your@email.com\""
        echo "  Then: git commit -m \"Initial commit: $PROJECT_NAME\""
    fi
else
    echo "  Git repository already exists, skipping initialization"
fi

echo ""
echo "================================================"
echo "    Setup Complete!"
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
echo "Happy coding!"