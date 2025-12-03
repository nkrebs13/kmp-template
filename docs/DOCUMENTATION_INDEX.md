# Template Documentation Index

This file provides a complete overview of all documentation for this Kotlin Multiplatform template.

## 📚 Documentation Structure

### For Template Maintainers
- **[TEMPLATE_DEVELOPMENT.md](./TEMPLATE_DEVELOPMENT.md)** - Comprehensive maintenance guide
  - Template structure and critical components
  - Update workflows and maintenance checklists  
  - Testing strategies and troubleshooting
  - Related documentation cross-references

- **[CLAUDE_CODE_GUIDE.md](./CLAUDE_CODE_GUIDE.md)** - Claude Code specific guidance
  - Quick start instructions for Claude Code
  - Common task patterns and workflows
  - Code patterns and best practices
  - Troubleshooting workflows and testing strategies

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

### Template Testing System
Use the **template-verifier agent** in Claude Code for comprehensive template testing:
- Automated template generation with various configurations
- Android and iOS build verification
- Package name validation and structure checking
- Edge case testing and automatic issue fixing
- Performance and compatibility testing

## 🔄 Documentation Cross-References

### Self-Referencing System
All documentation files reference each other to ensure continuity:

```
TEMPLATE_DEVELOPMENT.md ←→ CLAUDE_CODE_GUIDE.md
        ↓                           ↓
CONFIGURATION.md        ←→   README_TEMPLATE.md
        ↓                           ↓  
Template Testing System ←→   User Documentation
```

### File Relationships
- **TEMPLATE_DEVELOPMENT.md** references all other files for context
- **CLAUDE_CODE_GUIDE.md** provides tool-specific workflows for all documentation
- **README_TEMPLATE.md** links to CONFIGURATION.md for detailed setup
- **CONFIGURATION.md** cross-references TEMPLATE_DEVELOPMENT.md for maintenance

## 📋 Documentation Maintenance

### When to Update
- **After dependency updates**: Update README_TEMPLATE.md and CONFIGURATION.md
- **After structural changes**: Update TEMPLATE_DEVELOPMENT.md and CLAUDE_CODE_GUIDE.md  
- **After adding features**: Update all user-facing documentation
- **After testing system changes**: Update template testing documentation

### Update Checklist
- [ ] Update version numbers across all files
- [ ] Verify cross-references are still valid
- [ ] Update setup.sh to exclude new template-only files
- [ ] Test template generation to ensure documentation exclusion
- [ ] Update "Last Updated" dates in all files

## 🚨 Template vs Generated Project Documentation

### Template-Only Files (Excluded from Generated Projects)
These files are automatically removed by `setup.sh`:
- `TEMPLATE_DEVELOPMENT.md`
- `CLAUDE_CODE_GUIDE.md`
- `CONFIGURATION.md`
- `README_TEMPLATE.md`
- `DOCUMENTATION_INDEX.md`
- All testing system files

### Generated Project Files
These files are included in generated projects:
- `README.md` (generated from README.md.template)
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
- ✅ Claude Code can effectively work with template
- ✅ Users can successfully generate and build projects
- ✅ Generated projects contain no template-specific documentation
- ✅ Documentation stays current with template evolution

---

**Last Updated**: 2025-09-02
**Template Version**: 2.1.0+ (Kotlin 2.1.0 | Compose 1.8.0 | AGP 8.12.1 | Gradle 9.0)
**Documentation Version**: 1.1.0