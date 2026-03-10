# Testing Conventions

- Tests in `commonTest/` run on all platforms (JVM host + iOS simulator)
- Platform-specific tests: `androidHostTest/` (Android), `iosTest/` (iOS)
- Use `kotlin.test` assertions — not JUnit directly
- Test class naming: `{ClassName}Test` in the same package as the source
- Coverage must stay above 60% line (enforced by Kover in `shared/build.gradle.kts`)
- Kover excludes: ComposableSingletons, generated resources, Android generated classes
- Run tests: `./gradlew :shared:allTests`
- Verify coverage: `./gradlew :shared:koverVerify`
