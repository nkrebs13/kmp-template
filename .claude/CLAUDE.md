# KMP Template — Claude Code Maintainer Guide

## Project Philosophy

This is a **skeleton template**, not a demo app. It provides production-grade build infrastructure
and a clean starting point for new KMP projects. It intentionally contains no sample app features,
no DI framework, no networking, no navigation — those are the user's choices to make.

**Do not add sample features.** Every dependency and line of code a user must delete is friction.

## Critical Rule: Zero Claude Code Files in Generated Projects

`setup.sh` deletes `.claude/` entirely during generation. CI enforces this with a hard assertion.
Never modify setup.sh to preserve Claude Code files in generated output.

Generated projects must have exactly **zero** `.claude/` files.

## Project Structure

```
kmp-template/
├── shared/              # KMP shared module (commonMain/androidMain/iosMain)
├── androidApp/          # Android application
├── iosApp/              # iOS Xcode project (Swift + Compose bridge)
├── baselineprofile/     # Android Baseline Profile generator
├── build-logic/         # Included build: convention plugins (convention.*) + verifyCatalog
├── config/
│   ├── compose/stability.conf   # Compose compiler stability config (`//` comments)
│   └── detekt/detekt.yml        # detekt + Compose rules config
├── scripts/             # Utility scripts (validate.sh)
├── docs/                # Documentation
├── gradle/              # Version catalog (libs.versions.toml), gradle-daemon-jvm.properties
├── setup.sh             # Template generation script
└── .github/workflows/ci.yml
```

Convention plugins (`build-logic/convention/src/main/kotlin/convention/`):
`convention.kmp.library`, `convention.compose`, `convention.android.application`,
`convention.quality` (applied by the others), `convention.root` (root only: `check`, root-level
Spotless, `verifyCatalog`). The root `build.gradle.kts` holds only `apply false` lines.
SDK levels come from the catalog `[versions]` (`android-compile-sdk` etc.); the app version from
`gradle.properties` (`app.versionCode`, `app.versionName`); JDK toolchain 21 and Java 17 bytecode
from the constants in `ProjectExtensions.kt`. ktlint settings live in `.editorconfig`.

## Build Commands

```bash
# Full local gate (run before every PR). `check` runs in every project:
# spotlessCheck, detekt, :shared:allTests, :shared:koverVerify, :androidApp:lintDebug
./gradlew check :androidApp:assembleDebug :shared:linkDebugFrameworkIosSimulatorArm64

# Auto-fix formatting (nothing auto-corrects during check)
./gradlew spotlessApply

# Prove every catalog coordinate exists, incl. unreferenced optional entries (network; not in check)
./gradlew verifyCatalog

# Individual checks
./gradlew detekt                      # per module, config/detekt/detekt.yml
./gradlew :shared:allTests
./gradlew :shared:koverVerify         # 60% line coverage minimum
./gradlew :androidApp:lintDebug       # Warnings are errors

# Compose compiler reports/metrics -> <module>/build/compose-reports, compose-metrics
./gradlew -Pkmp.composeCompilerReports=true :shared:compileAndroidMain
```

## Template Generation Test

```bash
# Full e2e test — generates a project, verifies no artifacts, verifies it builds
cp -r . /tmp/e2e-test && cd /tmp/e2e-test
printf 'WeatherApp\ncom.example.weather\ncom.example.weather\ny\n' | bash setup.sh
grep -ri "com.template\|TemplateApp\|KmpTemplate\|orgName" . --exclude-dir=.git | wc -l  # Must be 0
test ! -d ".claude" && echo "PASS" || echo "FAIL"
./gradlew :shared:allTests :androidApp:assembleDebug
cd - && rm -rf /tmp/e2e-test
```

## Key Design Decisions

- **`replace_in_directory`** excludes `.git/`, `build/`, `.gradle/`, `node_modules/` and handles
  `.kt`, `.kts`, `.xml`, `.gradle`, `.toml`, `.conf`, `.sh`, `.md`, `.swift`, `.plist`, `.pbxproj`
- **Git reinit**: setup.sh always runs `rm -rf .git && git init` for a clean history
- **`__PROJECT_NAME__`** placeholder in `docs/README_TEMPLATE.md` — avoids overbroad "Template" replacement
- **`config/compose/stability.conf`** lists only read-only collection interfaces and `kotlin.time.*`,
  not `kotlin.collections.*`; it is a tracked compile input (editing it recompiles)
- **Detekt**: 1.23.8 until 2.x ships stable; `warningsAsErrors: true`, `checkExhaustiveness: true`
  (so every Compose rule is listed in detekt.yml), `maxIssues: 0`
- **Isolated Projects** on (`org.gradle.unsafe.isolated-projects=true`; the name without `unsafe.` is ignored)
- **Kover**: 60% line coverage on `shared` module
- **Android lint**: `warningsAsErrors = true` (aborting on errors is AGP's default)

## CI Minutes Status

CI_MINUTES: AVAILABLE. PR-open CI runs the full Build & Lint + Template Generation
matrix on `macos-14` runners. Local verification still preferred during iteration;
push to open a PR for the authoritative run.

## Version Tags

Tags v2.0.0, v2.1.0, v2.2.0, v3.0.0, v3.1.0 exist on the remote. CHANGELOG comparison links depend on them.
