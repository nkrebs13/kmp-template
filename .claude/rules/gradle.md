# Gradle & Build Conventions

- All dependency versions in `gradle/libs.versions.toml` — never hardcode versions in build files
- All plugins declared in the version catalog `[plugins]` section
- Shared module configuration lives in the convention plugins in `build-logic/` — not in
  `subprojects {}`/`allprojects {}` (Isolated Projects is on; those blocks would break it)
- Detekt: `maxIssues: 0` — zero tolerance, no suppressions without justification; config in `config/detekt/detekt.yml`
- Spotless: ktlint 1.8.0 configured in `.editorconfig`; nothing auto-corrects during `check` — run `spotlessApply`
- Android lint: `warningsAsErrors = true` (AGP's defaults already abort on errors and check release builds)
- Kover: 60% line coverage minimum on shared module
- Local gate: `./gradlew check :androidApp:assembleDebug :shared:linkDebugFrameworkIosSimulatorArm64`
  (`check` = spotlessCheck, detekt, allTests, koverVerify, lintDebug in every module)
- After editing the catalog: `./gradlew verifyCatalog`
- Catalog aliases are kebab-case (`android-compile-sdk`, `compose-multiplatform`); build-logic looks them up by those names
