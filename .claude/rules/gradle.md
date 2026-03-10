# Gradle & Build Conventions

- All dependency versions in `gradle/libs.versions.toml` — never hardcode versions in build files
- All plugins declared in the version catalog `[plugins]` section
- Detekt: `maxIssues: 0` — zero tolerance, no suppressions without justification
- Spotless: ktlint 1.8.0, auto-correct enabled
- Android lint: `warningsAsErrors = true`, `abortOnError = true`
- Kover: 60% line coverage minimum on shared module
- CI commands: `spotlessCheck`, `detekt`, `:shared:allTests`, `:shared:koverVerify`, `:androidApp:assembleDebug`, `:androidApp:lintDebug`, `:shared:linkDebugFrameworkIosSimulatorArm64`
