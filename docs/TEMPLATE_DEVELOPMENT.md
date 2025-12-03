# Kotlin Multiplatform Template - Development Guide

This document provides comprehensive guidance for maintaining and updating this Kotlin Multiplatform template project.

## 📁 Template Structure

### Core Template Files
```
template/
├── androidApp/                 # Android application module
├── shared/                     # Shared KMP module  
├── iosApp/                     # iOS application
├── baselineprofile/            # Android baseline profiles
├── gradle/                     # Gradle configuration
│   └── libs.versions.toml      # Version catalog (CRITICAL)
├── build.gradle.kts            # Root build script
├── settings.gradle.kts         # Project settings
├── setup.sh                    # Template generation script (CRITICAL)
├── .gitignore                  # Comprehensive gitignore
└── local.properties.template   # SDK configuration template
```

### Documentation Files (Template Only)
```
template/
├── TEMPLATE_DEVELOPMENT.md     # This file - template maintenance
├── CLAUDE_CODE_GUIDE.md        # Claude Code usage guide  
├── CONFIGURATION.md            # Detailed configuration documentation
├── README_TEMPLATE.md          # Template overview (becomes README.md)
└── README.md.template          # User-facing README template
```

## 🔧 Critical Components

### 1. Version Catalog (`gradle/libs.versions.toml`)
**Location**: `gradle/libs.versions.toml`
**Purpose**: Centralized dependency management with latest KMP-compatible versions

**Key Sections**:
- `[versions]`: Version numbers for all dependencies
- `[libraries]`: Library definitions referencing versions
- `[plugins]`: Plugin definitions for build scripts

**Update Process**:
1. Check for new stable releases of core dependencies
2. For KMP-focused libraries, use beta/alpha if they enable KMP features
3. Test all updates thoroughly with template generation
4. Update related build scripts if dependency API changes

**Critical Dependencies to Monitor**:
- `kotlin` - Kotlin compiler version
- `agp` - Android Gradle Plugin  
- `compose` - Compose Multiplatform
- `androidx-*` - AndroidX libraries with KMP support

### 2. Setup Script (`setup.sh`)
**Location**: `setup.sh`
**Purpose**: Converts template into a new project with custom naming/packaging

**Key Functions**:
- `replace_in_file()`: File-specific text replacement
- `replace_in_directory()`: Bulk text replacement across multiple files
- Package name transformation and directory restructuring
- File cleanup and git initialization

**Update Considerations**:
- Test with various package name formats
- Ensure all placeholders are replaced (com.template.*)
- Verify file cleanup removes template-specific files
- Test directory restructuring with new source sets

**Testing**: Use the Template Testing subagent for comprehensive validation

### 3. Build Configuration
**Files**: `build.gradle.kts`, `androidApp/build.gradle.kts`, `shared/build.gradle.kts`
**Purpose**: Modern KMP build setup with latest best practices

**Key Features**:
- Kotlin 2.1.0+ with modern compiler options DSL
- Compose Multiplatform with stable component access
- Version catalog references throughout
- iOS framework configuration for Xcode integration

## 📋 Maintenance Checklist

### Monthly Updates
- [ ] Check for new Kotlin releases
- [ ] Update AndroidX library versions
- [ ] Review Compose Multiplatform updates
- [ ] Update AGP to latest stable
- [ ] Test template generation with updates

### Quarterly Reviews  
- [ ] Review and update comprehensive .gitignore
- [ ] Check for new useful KMP libraries to add to version catalog
- [ ] Update documentation for any workflow changes
- [ ] Performance test template generation and builds
- [ ] Review and update baseline profiles configuration

### Before Major Releases
- [ ] Full dependency audit and updates
- [ ] Comprehensive testing across platforms
- [ ] Documentation review and updates
- [ ] Template generation testing with edge cases
- [ ] Performance benchmarking

## 🔄 Update Workflow

### 1. Dependency Updates
```bash
# 1. Update gradle/libs.versions.toml
# 2. Test builds
./gradlew clean build

# 3. Test template generation
./setup.sh  # Test with sample project

# 4. Run comprehensive tests using template-verifier agent
# Use Claude Code's template-verifier agent for automated testing
```

### 2. Adding New Dependencies
1. Add to appropriate section in `libs.versions.toml`
2. Reference in relevant build.gradle.kts files
3. Update documentation if user-facing
4. Test template generation to ensure setup.sh handles new files
5. Update .gitignore if needed for new tools/artifacts

### 3. Structural Changes
1. Update setup.sh to handle new file/directory structure
2. Test package name replacement in new locations
3. Update cleanup logic for new template-specific files
4. Verify .gitignore covers new artifacts
5. Update this documentation

## 🧪 Testing Strategy

### Automated Testing (Recommended)
Use the template-verifier agent in Claude Code for comprehensive automated testing:
- Template generation with various configurations
- Build verification for Android and iOS
- Package name validation and edge case testing

### Manual Testing Process
1. **Template Generation**:
   ```bash
   cp -r template test-project
   cd test-project
   ./setup.sh
   # Test with various inputs
   ```

2. **Build Verification**:
   ```bash
   # Android
   ./gradlew :androidApp:assembleDebug
   ./gradlew :androidApp:assembleRelease
   
   # iOS  
   ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
   
   # Tests
   ./gradlew testDebugUnitTest
   ```

3. **Package Verification**:
   - Check all files use new package names
   - Verify no "com.template" references remain
   - Test app launches and functions correctly

4. **Cleanup Verification**:
   - Confirm template-specific files are removed
   - Verify development artifacts are cleaned
   - Check git repository initialization

## 📚 Related Documentation

- **[CLAUDE_CODE_GUIDE.md](./CLAUDE_CODE_GUIDE.md)**: Claude Code specific guidance
- **[CONFIGURATION.md](./CONFIGURATION.md)**: Detailed configuration reference
- **[README_TEMPLATE.md](./README_TEMPLATE.md)**: Template overview and features
- **setup.sh**: Contains inline documentation for template generation process
- **gradle/libs.versions.toml**: Comments explain dependency choices and versions

## 🚨 Common Issues

### Template Generation Issues
- **Package name not updated**: Check setup.sh replacement patterns
- **Build failures**: Usually dependency version incompatibilities  
- **iOS build issues**: Framework paths or Xcode integration problems
- **File not found**: Template structure changed, update setup.sh paths

### Dependency Issues
- **Version conflicts**: Check version catalog consistency
- **Missing dependencies**: Ensure all build.gradle.kts files reference libs
- **Compilation errors**: May need to update import statements for API changes

### Solutions
1. Use template-verifier agent for automated diagnosis
2. Check recent commit history for breaking changes
3. Test with clean template generation
4. Compare with known-working version

## 🎯 Goals

This template aims to provide:
- **Modern KMP setup** with latest stable versions
- **Production-ready configuration** with proper tooling
- **Easy customization** through version catalog
- **Comprehensive coverage** of common KMP needs
- **Reliable generation** through robust setup script
- **Maintainable codebase** with clear documentation

## 🔗 External Resources

- [Kotlin Multiplatform Documentation](https://kotlinlang.org/docs/multiplatform.html)
- [Compose Multiplatform](https://github.com/JetBrains/compose-multiplatform)
- [AndroidX Release Notes](https://developer.android.com/jetpack/androidx/versions)
- [KMP Libraries Directory](https://github.com/terrakok/kmm-awesome)

---

**Last Updated**: 2025-12-03
**Template Version**: 2.2.0 (Kotlin 2.2.21 | Compose 1.9.3 | AGP 9.0.0-beta03 | Gradle 9.2.1)
**Maintainer**: Template Development Team