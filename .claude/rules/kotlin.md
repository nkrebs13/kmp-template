# Kotlin & KMP Conventions

- Log with `AppLogger`; never `println`/`print`. detekt's `ForbiddenMethodCall` for them needs type
  resolution, which `check` does not run, so review for it yourself.
- Shared public API lives in `shared/src/commonMain/`. Swift sees only the `shared` framework.
- Platform code uses `expect`/`actual`: declare in `commonMain`, implement in `androidMain`,
  `iosMain` and `jvmMain`, in files named `<Name>.android.kt`, `<Name>.ios.kt`, `<Name>.jvm.kt`.
- Formatting is ktlint via Spotless, configured in `.editorconfig` (IntelliJ style, 120-char lines,
  trailing commas, 4-space indent). Run `./gradlew spotlessApply`.
- detekt (`config/detekt/detekt.yml`): no `TODO:`/`FIXME:`/`STOPSHIP:` comments, no `TODO()`, at most
  2 returns, no magic numbers or wildcard imports outside tests, method length 60, cognitive and
  cyclomatic complexity 15.
- Prefer `require()`/`check()`/`error()` over manual throws.
- `@Composable` functions are PascalCase and take `modifier: Modifier = Modifier` (Compose rules).
