# Contributing to KMP Template

First off, thanks for taking the time to contribute! This template helps developers kickstart their Kotlin Multiplatform projects, and your contributions make it better for everyone.

## Prerequisites

Before contributing, ensure you have:

- **macOS** (required for iOS development and testing)
- **JDK 17+** (required for Gradle 9.x and Kotlin 2.x)
- **Android Studio** (latest stable with KMP plugin)
- **Xcode 15.0+** (for iOS framework compilation)

> **Note:** Windows and Linux are not supported for full template development due to iOS build requirements.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/template.git
   cd template
   ```
3. **Verify the build**:
   ```bash
   ./gradlew :androidApp:assembleDebug
   ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
   ```

## Development Workflow

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Format and lint:
   ```bash
   ./gradlew spotlessApply
   ./gradlew detekt
   ```

4. Test template generation:
   ```bash
   # Create a test directory
   cp -r . ../template-test
   cd ../template-test
   ./setup.sh
   # Test with package name like: com.test.myapp
   ```

5. Verify no template references remain:
   ```bash
   grep -r "com.template" . --include="*.kt" --include="*.kts" --include="*.xml" --exclude-dir=.git
   ```

### Testing Guidelines

Before submitting a PR, test with multiple package name patterns:

| Pattern | Example | Tests |
|---------|---------|-------|
| Standard | `com.example.myapp` | Common case |
| Deep | `io.company.product.mobile.app` | Long package paths |
| Minimal | `app.short` | Edge case |

### Code Style

- Follow existing code patterns in the project
- Use the version catalog (`libs.versions.toml`) for all dependencies
- Keep Kotlin code formatted with Spotless
- Prefer clarity over cleverness

## Commit Conventions

Write clear, descriptive commit messages:

```
feat: add Room database support to shared module
fix: correct sed escaping in setup.sh for special characters
docs: update README with new quick start guide
chore: update Kotlin to 2.3.0
```

Prefixes:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks (dependency updates, etc.)
- `refactor:` - Code changes that neither fix bugs nor add features

## Pull Request Process

1. **Update documentation** if your changes affect usage
2. **Update the version catalog** if adding/updating dependencies
3. **Test template generation** with at least 2 different package names
4. **Ensure CI passes** (builds, linting, template tests)
5. **Fill out the PR template** completely

## CI Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and PR to `main`. It consists of two jobs:

### Build & Lint

Runs on `macos-14` with JDK 17:

1. `spotlessCheck` - Verifies code formatting
2. `detekt` - Runs static analysis
3. `:androidApp:assembleDebug` - Builds the Android app
4. `:shared:linkDebugFrameworkIosSimulatorArm64` - Builds the iOS framework
5. `:shared:allTests` - Runs shared module tests

### Template Generation

Validates that `setup.sh` produces a working project:

1. Runs `setup.sh` with test inputs (`MyApp` / `com.example.myapp`)
2. Verifies no `com.template` or `TemplateApp` references remain
3. Verifies template-only files (`setup.sh`, `CHANGELOG.md`, `docs/TEMPLATE_DEVELOPMENT.md`, `docs/CONFIGURATION.md`, `.github/`, etc.) are removed
4. Builds and tests the generated project (shared tests, Android build, iOS framework)

Both jobs must pass before a PR can be merged. The workflow uses concurrency groups to cancel in-progress runs when new commits are pushed.

## What to Contribute

We welcome contributions in these areas:

- **Dependency updates** - Keep libraries current
- **Build improvements** - Faster, more reliable builds
- **Documentation** - Clearer guides and examples
- **Bug fixes** - Especially in `setup.sh`
- **New features** - Discuss in an issue first

## Questions?

- Open a [GitHub Discussion](../../discussions) for questions
- Check existing [Issues](../../issues) before creating new ones
- Read the [Template Development Guide](./docs/TEMPLATE_DEVELOPMENT.md) for maintainer info

Thanks for contributing!
