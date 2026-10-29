# Gradle & Build Conventions

- Every version lives in `gradle/libs.versions.toml`, including SDK levels; never hardcode one in a
  build file. Plugins are declared in its `[plugins]` section.
- Catalog aliases are kebab-case (`android-compile-sdk`, `compose-multiplatform`); build-logic looks
  them up by those names.
- Shared configuration lives in the convention plugins in `build-logic/`, never in
  `subprojects {}`/`allprojects {}`. Isolated Projects is on
  (`org.gradle.unsafe.isolated-projects=true`; the name without `unsafe.` is silently ignored), so
  no script may read or configure another project. Read properties through `providers`.
- `./gradlew check` = Spotless check, detekt, `checkForbiddenCalls` (no `print`/`println`), every host-buildable test target, Kover (60% lines per
  KMP library module) and `lintDebug`, in every module. Nothing auto-corrects; run `spotlessApply`.
- Zero tolerance: detekt `maxIssues: 0` and `warningsAsErrors`, lint `warningsAsErrors`, no
  baselines, no suppressions without a comment saying why.
- After editing the catalog: `./gradlew verifyCatalog`.
- The detekt 1.23.8 `ReportingExtension.file` deprecation ("Deprecated Gradle features were used")
  is accepted until detekt 2.x is stable; see `docs/MAINTAINING.md`.
