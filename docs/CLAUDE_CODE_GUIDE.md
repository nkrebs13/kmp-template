# Claude Code Workflows

Agent-assisted workflows for template maintenance. See root `CLAUDE.md` for project overview.

## Specialized Agents

### dependency-updater
Updates all dependencies to latest stable versions with KMP compatibility focus.
- Location: `.claude/agents/dependency-updater.md`
- Use for: Monthly dependency updates, major version migrations

### template-verifier
Comprehensive automated template testing and validation.
- Location: `.claude/agents/template-verifier.md`
- Use for: Post-update validation, edge case testing, build verification

## Common Workflows

### Dependency Update Workflow
1. Run dependency-updater agent
2. Review changes to `gradle/libs.versions.toml`
3. Run template-verifier agent to validate

### Adding New Dependencies
1. Add version to `[versions]` section in `libs.versions.toml`
2. Add library to `[libraries]` section
3. Reference in `shared/build.gradle.kts` using `libs.new.library`
4. Test template generation

### Troubleshooting
```bash
# Find remaining template references
grep -r "com.template" . --exclude-dir=.git

# Check version catalog usage
grep -r "libs\." . --include="*.kts"

# Verify builds
./gradlew :androidApp:assembleDebug
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

## Testing Checklist
- [ ] Template generates without errors
- [ ] No "com.template" references in generated project
- [ ] Android debug/release builds succeed
- [ ] iOS framework builds successfully
- [ ] Unit tests pass

---
**Last Updated**: 2025-12-03
