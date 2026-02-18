## Summary

Brief description of the changes in this PR.

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Dependency update
- [ ] Refactoring (no functional changes)

## Testing Checklist

- [ ] `./gradlew spotlessCheck` passes
- [ ] `./gradlew detekt` passes
- [ ] `./gradlew :androidApp:assembleDebug` builds successfully
- [ ] `./gradlew :shared:linkDebugFrameworkIosSimulatorArm64` builds successfully
- [ ] Tested `./setup.sh` with standard package name (e.g., `com.example.myapp`)
- [ ] Verified no `com.template` references remain after setup
- [ ] (Optional) For `setup.sh` changes: Tested with edge cases (e.g., `io.company.product.app`, `app.short`)

## Related Issues

Fixes # (issue number)

## Additional Notes

Any additional information reviewers should know.
