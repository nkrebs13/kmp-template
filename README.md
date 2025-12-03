# Kotlin Multiplatform Template

A modern, production-ready Kotlin Multiplatform template for iOS and Android applications with Compose Multiplatform.

> **🎯 This is a template project** - Use `./setup.sh` to generate your own project from this template.

## ⚡ Quick Start

1. **Clone the template**:
   ```bash
   git clone <template-repo-url> my-awesome-app
   cd my-awesome-app
   ```

2. **Generate your project**:
   ```bash
   ./setup.sh
   ```

3. **Follow the prompts** to customize your project name and package.

## 🚀 What You Get

- **Latest Kotlin 2.2.21** with K2 compiler and enhanced KMP features
- **Compose Multiplatform 1.9.3** with **Production-Ready iOS Support**
- **100+ Dependencies** in organized version catalog with latest stable versions
- **Stable KMP Libraries** - Room 2.7.2, SQLite 2.5.2 with full KMP support
- **Modern Build System** - AGP 9.0.0, Gradle 9.2.1 (requires Java 17+)
- **Production-ready setup** with comprehensive tooling for development and CI/CD

## 📁 Project Structure

### Template Files (You're Here!)
```
template/
├── 📄 README.md              # This file - template overview
├── 🔧 setup.sh              # Main script to generate projects
├── 📚 docs/                 # Template documentation & guides  
├── 🧪 scripts/             # Testing & development scripts
└── 📦 Project Files/        # The actual KMP project template
```

### Generated Project Structure
After running `./setup.sh`, you'll get a clean KMP project:
```
your-project/
├── 📱 androidApp/           # Android application
├── 📱 iosApp/              # iOS application  
├── 🔄 shared/              # Shared KMP code
├── ⚡ baselineprofile/      # Performance optimization
├── 🔧 gradle/              # Build configuration
└── 📄 README.md            # Your project's documentation
```

## 📚 Documentation

### For Template Users
- **[Getting Started Guide](./docs/README_TEMPLATE.md)** - Complete user guide for generated projects
- **[Configuration Reference](./docs/CONFIGURATION.md)** - Available features and customization options

### For Template Maintainers  
- **[Development Guide](./docs/TEMPLATE_DEVELOPMENT.md)** - Template maintenance and updates
- **[Claude Code Guide](./docs/CLAUDE_CODE_GUIDE.md)** - AI-assisted development workflows
- **[Documentation Index](./docs/DOCUMENTATION_INDEX.md)** - Complete documentation overview

### Template Testing
- Use the **template-verifier agent** in Claude Code for comprehensive automated template validation

## 🔧 Template Features

### Modern Tech Stack
- **Kotlin 2.2.21**: Latest stable compiler with K2 and KMP enhancements
- **Compose Multiplatform 1.9.3**: Production-ready iOS support with Material Design 3
- **Version Catalog**: Centralized dependency management with 100+ latest libraries
- **Stable KMP Libraries**: Room 2.7.2, SQLite 2.5.2 - no more alpha versions needed

### Development Experience
- **Code Quality**: Spotless formatting + Detekt static analysis
- **Performance**: Android Baseline Profiles for optimized startup
- **Testing**: Comprehensive test setup with modern libraries
- **CI/CD Ready**: Proper build configuration and comprehensive .gitignore

### Template System
- **Smart Setup Script**: Automatic project generation with custom naming
- **Clean Generation**: Template-specific files automatically excluded
- **Testing Suite**: Automated validation of template functionality
- **Documentation**: Self-referencing system for maintainability

## 🧪 Testing the Template

Use the specialized template-verifier agent for comprehensive testing:

```bash
# In Claude Code, use the template-verifier agent
# The agent will automatically:
# - Test template generation with various configurations
# - Verify Android and iOS builds work correctly  
# - Validate package names and project structure
# - Test edge cases and fix any issues found
```

## 🤝 Contributing

1. **Template Improvements**: Modify template files and test with `./setup.sh`
2. **Dependency Updates**: Update `gradle/libs.versions.toml` 
3. **Documentation**: Keep `docs/` folder current with changes
4. **Testing**: Run template tests before submitting changes

## 📋 Requirements

- **JDK 17+**: **Required** for Gradle 9.0 and Kotlin 2.1.0 compilation
- **Android Studio**: Latest stable with KMP support
- **Xcode 15.0+**: For iOS development (macOS only)
- **Java 17+**: Essential for build system compatibility

## 🆘 Support

- **Template Issues**: Check [Template Development Guide](./docs/TEMPLATE_DEVELOPMENT.md)
- **Generated Project Issues**: Check [User Guide](./docs/README_TEMPLATE.md)
- **Testing Issues**: Use the template-verifier agent in Claude Code for automated diagnosis

---

**Template Version**: 2.2.0
**Last Updated**: 2025-12-03
**Kotlin**: 2.2.21 | **Compose**: 1.9.3 | **AGP**: 9.0.0-beta03 | **Gradle**: 9.2.1