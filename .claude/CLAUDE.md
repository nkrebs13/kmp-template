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
├── mcp/                 # MCP server for AI-assisted generation
├── scripts/             # Utility scripts (validate.sh, build-ios-framework.sh)
├── docs/                # Documentation
├── gradle/              # Version catalog (libs.versions.toml)
├── setup.sh             # Template generation script (~560 lines)
├── compose-stability.conf
├── detekt-config.yml
└── .github/workflows/ci.yml
```

## Build Commands

```bash
# Full CI suite (run before every PR)
./gradlew spotlessCheck detekt :shared:allTests :shared:koverVerify \
  :androidApp:assembleDebug :androidApp:lintDebug \
  :shared:linkDebugFrameworkIosSimulatorArm64

# Auto-fix formatting
./gradlew spotlessApply

# Individual checks
./gradlew detekt
./gradlew :shared:allTests
./gradlew :shared:koverVerify         # 60% line coverage minimum
./gradlew :androidApp:lintDebug       # Warnings are errors
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
- **`compose-stability.conf`** lists only immutable collection interfaces, not `kotlin.collections.*`
- **Detekt**: `warningsAsErrors: true`, `checkExhaustiveness: true`, `maxIssues: 0`
- **Kover**: 60% line coverage on `shared` module
- **Android lint**: `warningsAsErrors = true`, `abortOnError = true`

## CI Minutes Status

CI_MINUTES: OUT_OF_MINUTES until ~2026-04-01. All verification must be done locally.

## MCP Server

```bash
cd mcp && npm install && node --check index.js  # Verify syntax
```

The MCP `list_dependencies` tool parses `gradle/libs.versions.toml` with regex `[\w-]+` (supports
hyphenated keys like `compose-plugin`, `kotlinx-coroutines`).

## Version Tags

Tags v2.0.0, v2.1.0, v2.2.0, v3.0.0 exist on the remote. CHANGELOG comparison links depend on them.
