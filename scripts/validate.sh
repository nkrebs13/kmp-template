#!/bin/bash
#
# validate.sh - Validate a KMP project for template references
#
# Usage: ./scripts/validate.sh [project_dir]
#        If project_dir is not provided, validates the current directory.
#
# Exit codes:
#   0 - Validation passed (no template references found)
#   1 - Validation failed (template references found)
#   2 - Invalid arguments or directory not found
#

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Colors for output (check if stdout is a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Portable echo function that handles escape sequences
print_color() {
    printf '%b\n' "$1"
}

# Determine project directory
PROJECT_DIR="${1:-.}"

# Validate directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_color "${RED}Error: Directory does not exist: $PROJECT_DIR${NC}"
    exit 2
fi

# Convert to absolute path (portable method)
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd -P)

echo "=========================================="
echo "KMP Template Validation"
echo "=========================================="
echo "Project: $PROJECT_DIR"
echo ""

# Check if this looks like a KMP project
if [ ! -f "$PROJECT_DIR/build.gradle.kts" ] && [ ! -f "$PROJECT_DIR/settings.gradle.kts" ]; then
    print_color "${YELLOW}Warning: This doesn't appear to be a Gradle project${NC}"
fi

# Define patterns to search for
# - com.template. (with trailing dot to avoid matching com.mytemplate)
# - com/template/ (directory paths with trailing slash)
# - com.template followed by non-alphanumeric (end of package reference)
# - TemplateApp (class/app name)
# This avoids false positives for packages like "com.mytemplate.app"
PATTERNS='com[./]template[./]|com[./]template[^a-z0-9]|com[./]template$|TemplateApp'

# Define file types to check
FILE_TYPES=(
    "*.kt"
    "*.kts"
    "*.xml"
    "*.swift"
    "*.plist"
    "*.pro"
    "*.pbxproj"
    "*.xcscheme"
)

# Build include arguments as an array (proper quoting)
INCLUDE_ARGS=()
for type in "${FILE_TYPES[@]}"; do
    INCLUDE_ARGS+=("--include=$type")
done

# Run the search
echo "Scanning for template references..."
echo ""

# Use grep to find references, excluding build and git directories
# Note: We disable set -e temporarily since grep returns 1 when no matches found
set +e
REFERENCES=$(grep -rI \
    --color=never \
    -E "$PATTERNS" \
    "$PROJECT_DIR" \
    "${INCLUDE_ARGS[@]}" \
    --exclude-dir=.git \
    --exclude-dir=build \
    --exclude-dir=.gradle \
    --exclude-dir=node_modules \
    --exclude-dir=DerivedData \
    --exclude-dir=Pods \
    --exclude="*.generated.*" \
    2>/dev/null)
GREP_EXIT=$?
set -e

# grep returns 0=found, 1=not found, 2=error
if [ "$GREP_EXIT" -eq 2 ]; then
    print_color "${RED}Error: grep failed while scanning${NC}"
    exit 2
fi

# Filter out known acceptable references
FILTERED_REFERENCES=""
while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Skip Gradle wrapper's Groovy template comment
    case "$line" in
        *"generated from the Groovy template"*) continue ;;
    esac

    # Skip validate.sh itself
    case "$line" in
        *"validate.sh"*) continue ;;
    esac

    # Skip this scripts directory (for the template repo itself)
    case "$line" in
        *"/scripts/"*) continue ;;
    esac

    # Add to filtered list
    if [ -n "$FILTERED_REFERENCES" ]; then
        FILTERED_REFERENCES="${FILTERED_REFERENCES}"$'\n'"${line}"
    else
        FILTERED_REFERENCES="$line"
    fi
done <<< "$REFERENCES"

# Count references (handle empty string properly)
if [ -z "$FILTERED_REFERENCES" ]; then
    REF_COUNT=0
else
    REF_COUNT=$(printf '%s\n' "$FILTERED_REFERENCES" | wc -l | tr -d ' ')
fi

echo "------------------------------------------"
if [ "$REF_COUNT" -eq 0 ]; then
    print_color "${GREEN}PASSED${NC}: No template references found"
    echo "------------------------------------------"
    echo ""
    echo "The project is clean and ready to use."
    exit 0
else
    print_color "${RED}FAILED${NC}: Found $REF_COUNT template reference(s)"
    echo "------------------------------------------"
    echo ""
    echo "Template references found:"
    echo ""

    # Process and display references (using process substitution to avoid subshell)
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        # Extract file path - handle both Unix and potential Windows paths
        # Use parameter expansion to be more robust than cut
        FILE_PATH="${line%%:*}"
        CONTENT="${line#*:}"
        # Handle case where there might be a line number (file:line:content)
        if [[ "$CONTENT" == *:* ]] && [[ "${CONTENT%%:*}" =~ ^[0-9]+$ ]]; then
            LINE_NUM="${CONTENT%%:*}"
            CONTENT="${CONTENT#*:}"
            FILE_PATH="$FILE_PATH:$LINE_NUM"
        fi

        # Make path relative to project dir
        REL_PATH="${FILE_PATH#"$PROJECT_DIR"/}"

        echo "  $REL_PATH"
        echo "    $CONTENT"
        echo ""
    done <<< "$FILTERED_REFERENCES"

    echo ""
    echo "These references should be manually reviewed and updated."
    exit 1
fi
