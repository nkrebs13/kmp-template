# Testing Conventions

- Every test must exercise template code, not a library. Do not add tests that only re-test Kermit, Compose or the Kotlin stdlib.
- `commonTest/` runs on every target: jvm (desktop), android host and the iOS simulator
- `commonTest/` holds the contract tests (`PlatformTest`, `AppLoggerTest`) and the shared UI-test body (`AppUiTestBody.kt`)
- Per-platform `actual` tests: `androidHostTest/`, `jvmTest/`, `iosTest/` (`Platform<Name>Test`)
- Use `kotlin.test` assertions, not JUnit directly
- Test class naming: `{ClassName}Test` in the same package as the source
- Run tests: `./gradlew :shared:allTests` (iOS: `:shared:iosSimulatorArm64Test`, macOS only)

## Compose UI tests

- `App()` is tested with the multiplatform `androidx.compose.ui.test.v2.runComposeUiTest`
  (`libs.compose.ui.test`). The test class is `AppUiTest` in `jvmTest/` and `iosTest/`, and each
  calls `assertGreetingIsDisplayed()` from `commonTest/AppUiTestBody.kt`.
- The body is a plain function with no `@Test` in `commonTest/`. A `@Test` there would also run in
  `androidHostTest`, which has no Compose UI test runtime without Robolectric.
- jvmTest runs headless, so it works on Linux CI. `jvmTest` needs `compose.desktop.currentOs` for Skiko.
- Resources load asynchronously: wait with `waitUntilExactlyOneExists` before asserting.
- **Mutation-check habit:** after writing or changing a UI test, change the string it asserts in
  `shared/src/commonMain/composeResources/values/strings.xml`, confirm the test fails, then revert.
  A UI test that never failed has not been shown to test anything.
- Screenshot tests (Roborazzi) are not in the default gate: font rendering differs between macOS and Linux.

## Coverage

- Kover enforces 60% line coverage on `shared` (`./gradlew :shared:koverVerify`, part of `check`).
  Read the number with `./gradlew :shared:koverLog`.
- It measures the jvm and android host tests. Kover does not measure Kotlin/Native.
- Excludes live in `QualityConventionPlugin`: `ComposableSingletons*`
  (iOS entry point), the generated `*.generated.resources.*` package, `@Preview` functions and
  Android generated classes.
