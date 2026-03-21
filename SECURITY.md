# Security Policy

## Supported Versions

This is a project template. Security updates apply to the template itself and generated projects.

| Version | Supported          |
| ------- | ------------------ |
| 3.x.x   | :white_check_mark: |
| < 3.0   | :x:                |

## Reporting a Vulnerability

If you discover a security issue in this template, please report it via [GitHub Security Advisories](https://github.com/nkrebs13/kmp-template/security/advisories/new) — do not open a public issue.

Include:
- Steps to reproduce the issue
- Affected versions
- Potential impact

## Security Best Practices for Generated Projects

When using this template to generate your project, consider these practices:

### Dependencies
- Regularly review `gradle/libs.versions.toml` and Dependabot PRs for security-related updates
- Review changelogs before upgrading libraries
- Use dependency scanning tools in your CI/CD pipeline

### Secrets Management
- Never commit API keys, passwords, or secrets to version control
- Use environment variables or secure secret management solutions
- Add sensitive files to `.gitignore`

### Code Signing
- Sign Android APKs/AABs for release builds
- Use proper iOS code signing with certificates from Apple Developer Program

### Network Security
- Use HTTPS for all network communications
- Implement certificate pinning for sensitive APIs
- Validate all server responses

## Template Security Measures

This template includes:
- `.gitignore` configured to exclude sensitive files
- Gradle configuration for secure dependency resolution
- Modern dependency versions with known security patches
