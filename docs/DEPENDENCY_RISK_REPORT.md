# Dependency Risk Report

**Generated:** 2026-02-19
**Commit:** as of this PR
**Branch:** nightshift/dependency-risk-scan

---

## Executive Summary

This report audits all 28 active dependencies in the KMP Template project across Gradle build files, the version catalog (`gradle/libs.versions.toml`), the Gradle wrapper, and CI workflows. Dependencies were checked against OSV.dev, GitHub Advisory Database, NVD, and Maven Central/Gradle Plugin Portal.

**Key findings:**

- **0 active CVEs** affect the current dependency versions in use
- **2 historical CVEs** in Kotlin stdlib (pre-2.x) and 1 in detekt (pre-1.20) are fully patched
- **2 alpha/pre-release dependencies** flagged for stability risk
- **10 dependencies** are behind the latest stable release
- **3 GitHub Actions** use mutable tag references (`@v4`) instead of SHA-pinned commits — the highest supply-chain risk identified
- **Gradle 9.3.0** already contains fixes for CVE-2026-22816 and CVE-2026-22865

**Risk level: LOW** — No urgent security action required. Recommended improvements are preventive.

---

## Critical Vulnerabilities

**None affecting current versions.**

All historical CVEs identified during the audit are already patched in the versions used by this project:

| CVE | Package | Severity | Affected Versions | Fixed In | Project Version | Status |
|-----|---------|----------|-------------------|----------|-----------------|--------|
| CVE-2020-29582 | kotlin-stdlib | Medium (5.3) | < 1.4.21 | 1.4.21 | 2.3.0 | Not affected |
| CVE-2022-24329 | kotlin-stdlib | Medium (5.3) | < 1.6.0 | 1.6.0 | 2.3.0 | Not affected |
| GHSA-2cfc-865j-gm4w | detekt-core | High (7.3) | < 1.20.0 | 1.20.0 | 1.23.8 | Not affected |
| CVE-2019-9843 | spotless-plugin | Medium | < 3.20.0 | 3.20.0 | 8.1.0 | Not affected |
| CVE-2026-22816 | Gradle | High (8.6) | 9.0.0–9.2.1 | 9.3.0 | 9.3.0 | Not affected |
| CVE-2026-22865 | Gradle | High (8.6) | 9.0.0–9.2.1 | 9.3.0 | 9.3.0 | Not affected |

**Navigation deep-link bypass** (no CVE assigned): AndroidX Navigation 2.8.1 fixed a vulnerability allowing deep links to bypass destination access control. The project uses 2.9.7, which inherits this fix.

---

## Outdated Dependencies

| Dependency | Current | Latest Stable | Delta | Update Priority |
|------------|---------|---------------|-------|-----------------|
| `kotlin` | 2.3.0 | 2.3.10 | 1 patch | Medium — race condition fix |
| `agp` | 9.0.0 | 9.0.1 | 1 patch | Low — 50+ bug fixes |
| `compose` / `compose-plugin` | 1.10.0 | 1.10.1 | 1 patch | Low — stability improvements |
| `ksp` | 2.3.3 | 2.3.6 | 3 patches | **Medium — AGP 9.0 compat fix in 2.3.5** |
| `androidx-activity` / `androidx-activity-compose` | 1.12.2 | 1.12.4 | 2 patches | **Medium — URI security compat fix** |
| `androidx-navigation-compose` | 2.9.0 | 2.9.7 | 7 patches | Medium — accumulated bug fixes |
| `androidx-compose-bom` | 2026.01.00 | 2026.02.00 | 1 BOM rev | Low |
| `spotless` | 8.1.0 | 8.2.1 | 2 patches | Low — OOM fix for large builds |
| `kotlinx-datetime` | 0.6.2 | 0.7.1 | 2 minor | Low — **breaking API changes**, requires migration |
| `androidx-test-uiautomator` | 2.4.0-alpha05 | 2.4.0-alpha07 | 2 alpha | Low — test-only dependency |

> **Note:** The **Current** column in the table above reflects dependency versions *before* applying the changes in this PR. Several of these dependencies are updated as part of this PR; see the **Version Bumps Applied** section for post-PR versions. After merge, updated dependencies will no longer be considered outdated.

### Dependencies at latest stable

These 11 dependencies are current and require no action:

- `androidx-core` 1.17.0, `androidx-appcompat` 1.7.1, `androidx-lifecycle` 2.10.0
- `androidx-splashscreen` 1.2.0, `androidx-compose-material3` 1.4.0
- `androidx-profileinstaller` 1.4.1, `androidx-test-ext-junit` 1.3.0
- `androidx-test-espresso` 3.7.0, `androidx-test-runner` 1.7.0, `androidx-test-core` 1.7.0
- `kotlinx-coroutines` 1.10.2, `kotlinx-serialization` 1.10.0, `ktlint` 1.8.0, `detekt` 1.23.8

---

## Pre-release / Alpha Risks

Two active dependencies use pre-release versions:

### 1. `androidx-benchmark` 1.5.0-alpha03

- **Latest stable:** 1.4.1
- **Risk:** Alpha APIs may change without notice. Benchmark macro-junit4 is only used for baseline profile generation, limiting blast radius.
- **Justification:** 1.5.x alpha is required for KMP baseline profile support and UiAutomator 2.4 integration features not available in 1.4.x stable.
- **Mitigation:** Pin to specific alpha version (already done). Monitor for beta/RC promotions.

### 2. `androidx-test-uiautomator` 2.4.0-alpha07

- **Latest stable:** 2.3.0
- **Risk:** Alpha APIs may change. Used only in instrumented test infrastructure.
- **Justification:** Required by benchmark-macro-junit4 1.5.x alpha for UiAutomator 2.4 features.
- **Mitigation:** Test-only dependency with no production impact. Pinned to 2.4.0-alpha07 to align with latest alpha.

### General alpha risk assessment

Both alpha dependencies are confined to the `baselineprofile` module's test infrastructure. They do not ship in the production APK or iOS framework. The stability risk is acceptable given their test-only scope.

---

## Maintenance Concerns

| Dependency | Last Release | Cadence | Concern |
|------------|-------------|---------|---------|
| `kotlinx-datetime` 0.6.2 | Dec 2023 | Irregular | 2 minor versions behind; 0.7.x is current but has breaking changes. Low release velocity. |
| `detekt` 1.23.8 | Feb 2025 | ~Monthly | Stable 1.x line is well maintained. 2.0 alpha in progress. Known false positives with Kotlin 2.3.0 metadata ([issue #8865](https://github.com/detekt/detekt/issues/8865)). |
| `ktlint` 1.8.0 | Nov 2024 | ~Quarterly | Active project, no concerns. |
| `spotless` 8.1.0 | Late 2025 | ~Monthly | Active project, 8.2.1 available. |

All other dependencies (JetBrains, Google, AndroidX) are backed by major organizations with regular release cadences and long-term support commitments. No orphaned or unmaintained dependencies were identified.

---

## CI Supply Chain Risks

### GitHub Actions — Mutable Tag References (HIGH RISK)

All three external actions in `.github/workflows/ci.yml` use mutable tag references:

```yaml
uses: actions/checkout@v4           # Mutable tag
uses: actions/setup-java@v4         # Mutable tag
uses: gradle/actions/setup-gradle@v4  # Mutable tag (third-party)
```

**Why this matters:** Mutable tags can be repointed to malicious commits. There have been real-world supply-chain attacks where attackers gained control of popular GitHub Actions and silently rewrote published tags to malicious commits that exfiltrated CI secrets from thousands of repositories. Security guidance from both GitHub and government agencies recommends pinning third-party actions to immutable commit SHAs instead of mutable tags.

**Recommended SHA-pinned versions:**

| Action | Current | Recommended | Version |
|--------|---------|-------------|---------|
| `actions/checkout` | `@v4` | `@34e114876b0b11c390a56381ad16ebd13914f8d5` | v4.3.1 |
| `actions/setup-java` | `@v4` | `@c1e323688fd81a25caa38c78aa6df2d33d3e20d9` | v4.8.0 |
| `gradle/actions/setup-gradle` | `@v4` | `@748248ddd2a24f49513d8f472f81c3a07d4d50e1` | v4.4.4 |

### Positive Findings

- **`permissions: contents: read`** — Properly scoped at workflow level. Restricts `GITHUB_TOKEN` to read-only, limiting blast radius of any compromised action.
- **`validate-wrappers: true`** — Correctly set on the `build` job. Validates `gradle-wrapper.jar` checksums against Gradle's published list, mitigating wrapper JAR substitution attacks.
- **`concurrency` with `cancel-in-progress`** — Prevents redundant builds and resource waste.

### Minor Gaps

- **`template-test` job** does not set `validate-wrappers: true` on its `setup-gradle` step. Lower risk since `setup.sh` restructures the project, but consistency is recommended.
- **Dependabot is configured** (`.github/dependabot.yml` with `github-actions` and `npm` ecosystems on weekly cadence), which will help automate future SHA pin updates once actions are pinned.

---

## Recommendations

### Immediate (apply now)

1. **Pin GitHub Actions to commit SHAs** — Replace `@v4` tags with full commit SHAs as listed above. This is the single highest-impact security improvement available.
2. **Add `validate-wrappers: true`** to the `template-test` job's `setup-gradle` step for consistency.

### Completed in this PR

Items 3–7 were applied as part of this PR (see **Version Bumps Applied** section below):

3. ~~**Update `ksp` 2.3.3 → 2.3.6**~~ — AGP 9.0 circular dependency fix. ✅ Applied.
4. ~~**Update `androidx-activity` 1.12.2 → 1.12.4**~~ — URI security compat fix. ✅ Applied.
5. ~~**Update `androidx-navigation-compose` 2.9.0 → 2.9.7**~~ — 7 accumulated patches. ✅ Applied.
6. ~~**Update `spotless` 8.1.0 → 8.2.1**~~ — OOM fix for large builds. ✅ Applied.
7. ~~**Update `androidx-test-uiautomator` 2.4.0-alpha05 → 2.4.0-alpha07**~~ — Latest alpha. ✅ Applied.

### Short-term (next release cycle)

8. **Update `Gradle wrapper` 9.3.0 → 9.3.1** — Stability patch, embedded Kotlin update. Not applied in this PR to keep changes scoped to `libs.versions.toml`.

### Medium-term (planned maintenance)

9. **Update `kotlin` 2.3.0 → 2.3.10** — Fixes race condition with kotlinx.serialization. Verify KSP compatibility first.
10. **Update `agp` 9.0.0 → 9.0.1** — 50+ accumulated bug fixes.
11. **Update `compose`/`compose-plugin` 1.10.0 → 1.10.1** — Stability improvements.
12. **Update `compose-bom` 2026.01.00 → 2026.02.00** — Align with latest BOM revision.

### Deferred (requires migration work)

13. **`kotlinx-datetime` 0.6.2 → 0.7.1** — Breaking API changes: `kotlinx.datetime.Instant`/`Clock` removed in favor of `kotlin.time.Instant`/`Clock`, property renames (`dayOfMonth` → `day`, `monthNumber` → `month`). Requires code migration.

### Infrastructure

14. **Dependabot already configured** — `.github/dependabot.yml` is present with `github-actions` and `npm` ecosystems set to weekly updates; continue to rely on it for automated SHA pin and dependency updates.

---

## Version Bumps Applied

The following safe patch-level bumps were applied to `gradle/libs.versions.toml` as part of this scan:

| Dependency | Before | After | Reason |
|------------|--------|-------|--------|
| `ksp` | 2.3.3 | 2.3.6 | AGP 9.0 compatibility fix |
| `androidx-activity` | 1.12.2 | 1.12.4 | URI security compat fix |
| `androidx-activity-compose` | 1.12.2 | 1.12.4 | URI security compat fix |
| `androidx-navigation-compose` | 2.9.0 | 2.9.7 | 7 accumulated bug fix patches |
| `spotless` | 8.1.0 | 8.2.1 | OOM fix for large builds |
| `androidx-test-uiautomator` | 2.4.0-alpha05 | 2.4.0-alpha07 | Latest alpha alignment |

---

*Report generated by Nightshift dependency-risk scanner.*
