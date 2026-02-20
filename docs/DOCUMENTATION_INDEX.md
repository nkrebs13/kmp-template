# Template Documentation Index

This file provides a complete overview of all documentation for this Kotlin Multiplatform template.

## 📚 Documentation Structure

### For Template Maintainers
- **[TEMPLATE_DEVELOPMENT.md](./TEMPLATE_DEVELOPMENT.md)** - Comprehensive maintenance guide
  - Template structure and critical components
  - Update workflows and maintenance checklists
  - Testing strategies and troubleshooting
  - Related documentation cross-references

### For Template Users
- **[README_TEMPLATE.md](./README_TEMPLATE.md)** - Complete user guide (becomes README.md)
  - Features overview and prerequisites
  - Getting started and build instructions
  - Project structure and architecture
  - Dependencies and deployment guides

- **[CONFIGURATION.md](./CONFIGURATION.md)** - Configuration reference
  - Version catalog system documentation
  - Available features and dependencies
  - Customization options and build configuration
  - Architecture details: `expect`/`actual` pattern, iOS/Compose bridge, baseline profiles
  - Compose stability configuration (`compose-stability.conf`)
  - Scripts reference (`build-ios-framework.sh`)
  - Code quality configuration (Detekt rules, Spotless formatting)

### For Contributors
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guide
  - Prerequisites, development workflow, testing guidelines
  - Commit conventions and PR process
  - CI pipeline details (Build & Lint, Template Generation jobs)

### CI/CD Testing
The GitHub Actions workflow (`.github/workflows/ci.yml`) provides:
- **Build & Lint**: Formatting, static analysis, Android/iOS builds, shared tests
- **Template Generation**: End-to-end validation of `setup.sh` output

## 🔄 Documentation Cross-References

### Self-Referencing System
All documentation files reference each other to ensure continuity:

```
TEMPLATE_DEVELOPMENT.md ←→ CONFIGURATION.md
        ↓                        ↓
README_TEMPLATE.md      ←→   CI/CD Testing
```

### File Relationships
- **TEMPLATE_DEVELOPMENT.md** references all other files for context
- **README_TEMPLATE.md** links to CONFIGURATION.md for detailed setup
- **CONFIGURATION.md** cross-references TEMPLATE_DEVELOPMENT.md for maintenance

## 📋 Documentation Maintenance

### When to Update
- **After dependency updates**: Update README_TEMPLATE.md and CONFIGURATION.md
- **After structural changes**: Update TEMPLATE_DEVELOPMENT.md
- **After adding features**: Update all user-facing documentation
- **After CI changes**: Update workflow documentation

### Update Checklist
- [ ] Update version numbers across all files
- [ ] Verify cross-references are still valid
- [ ] Update setup.sh to exclude new template-only files
- [ ] Test template generation to ensure documentation exclusion
- [ ] Update "Last Updated" dates in all files

## 🚨 Template vs Generated Project Documentation

### Template-Only Files (Excluded from Generated Projects)
These files are automatically removed by `setup.sh`:
- `docs/` directory (TEMPLATE_DEVELOPMENT.md, CONFIGURATION.md, etc.)
- Template-specific scripts and configuration

### Generated Project Files
These files are included in generated projects:
- `README.md` (generated from docs/README_TEMPLATE.md)
- Standard project documentation (build configs, etc.)

### Verification
Test exclusion with:
```bash
cp -r template test-project
cd test-project
./setup.sh
# Verify only README.md remains as documentation
```

## 🎯 Quality Standards

### Documentation Requirements
- **Completeness**: All features and processes documented
- **Accuracy**: Information matches current template state
- **Cross-references**: All related documentation linked
- **Examples**: Concrete examples for all workflows
- **Maintenance**: Regular updates with template changes

### Success Metrics
- ✅ New maintainers can understand and update template
- ✅ Users can successfully generate and build projects
- ✅ Generated projects contain no template-specific documentation
- ✅ CI tests pass for all package name variations
- ✅ Documentation stays current with template evolution

---

**Last Updated**: 2026-02-19
**Template Version**: 3.0.0 (Kotlin 2.3.0 | Compose 1.10.0 | AGP 9.0.0 | Gradle 9.3.0)