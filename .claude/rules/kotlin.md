# Kotlin & KMP Conventions

- Use `AppLogger` for all logging — `println`/`print` are forbidden (detekt ForbiddenMethodCall)
- All shared public API lives in `shared/src/commonMain/`
- Platform-specific code uses `expect`/`actual` pattern
- Follow ktlint formatting: 120 char lines, trailing commas, 4-space indent
- No `TODO()` in production code (detekt NotImplementedDeclaration)
- Prefer `require()`/`check()`/`error()` over manual throws (detekt UseRequire/UseCheckOrError)
- Composable functions exempt from standard function naming rules
- Max cognitive complexity: 15, cyclomatic complexity: 15, method length: 60 lines
