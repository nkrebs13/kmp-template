# Security Policy

## Supported Versions

This is a project template. Security updates apply to the template itself and generated projects.

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

If you discover a security issue in this template, please report it by:

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email the maintainer directly with details
3. Include steps to reproduce the issue if possible
4. Allow reasonable time for a response before public disclosure

## Security Best Practices for Generated Projects

When using this template to generate your project, consider these practices:

### Dependencies
- Regularly update dependencies using `./gradlew dependencyUpdates`
- Review changelogs for security-related updates
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
