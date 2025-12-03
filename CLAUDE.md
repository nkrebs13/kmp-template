# Kotlin Multiplatform Template

## What
KMP project template for generating iOS/Android apps with Compose Multiplatform.

**Stack:** Kotlin 2.2.21 | Compose Multiplatform 1.9.3 | AGP 9.0.0-beta03 | Gradle 9.2.1

**Structure:**
- `shared/` - KMP shared code (commonMain, androidMain, iosMain)
- `androidApp/` - Android application module
- `iosApp/` - iOS Xcode project consuming shared framework
- `gradle/libs.versions.toml` - Centralized version catalog (100+ deps)
- `setup.sh` - Template generation script

## Why
This is a **template factory**, not an application. Users run `./setup.sh` to generate customized KMP projects with their own package names.

## How

### Build Commands
```bash
./gradlew :androidApp:assembleDebug          # Android debug
./gradlew :androidApp:assembleRelease        # Android release
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64  # iOS framework
./gradlew testDebugUnitTest                  # Run tests
./gradlew spotlessApply                      # Format code
./gradlew detekt                             # Static analysis
```

### Template Testing
```bash
./setup.sh                                   # Generate project interactively
grep -r "com.template" . --exclude-dir=.git  # Verify no template refs remain
```

### Key Patterns
- Always use version catalog refs: `libs.kotlinx.coroutines.core`
- Use modern Kotlin compiler options DSL, not deprecated `kotlinOptions`
- Test with varied package names (short, deep hierarchy)

## References
- `docs/TEMPLATE_DEVELOPMENT.md` - Maintenance guide
- `docs/CONFIGURATION.md` - Configuration reference
- `.claude/agents/template-verifier.md` - Automated validation agent
- `.claude/agents/dependency-updater.md` - Dependency update agent
