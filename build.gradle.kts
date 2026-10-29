import convention.ktlintEditorConfigOverride

// Module configuration lives in the convention plugins under build-logic/.
// `apply false` puts every plugin on one shared classpath without applying it here.
plugins {
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.androidLibrary) apply false
    alias(libs.plugins.androidKotlinMultiplatformLibrary) apply false
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.jetbrainsCompose) apply false
    alias(libs.plugins.detekt) apply false
    alias(libs.plugins.kover) apply false
    alias(libs.plugins.androidx.baselineprofile) apply false
    alias(libs.plugins.spotless)
    id("convention.root")
}

// Root-only formatting: files that belong to no module. Each module formats its own sources
// (Kotlin, build script, XML) through the convention.quality plugin. Targets are explicit
// paths, never `**`, so Spotless never walks build/ directories that other tasks are writing.
spotless {
    // LF, as .gitattributes requires; see convention.quality for why it is explicit.
    lineEndings = com.diffplug.spotless.LineEnding.UNIX
    kotlin {
        target("build-logic/*/src/**/*.kt")
        ktlint(libs.versions.ktlint.get()).editorConfigOverride(ktlintEditorConfigOverride())
    }
    kotlinGradle {
        target("*.gradle.kts", "build-logic/*.gradle.kts", "build-logic/*/*.gradle.kts")
        ktlint(libs.versions.ktlint.get()).editorConfigOverride(ktlintEditorConfigOverride())
    }
    format("misc") {
        target("*.md", "docs/**/*.md", ".gitignore", "config/**/*.yml")
        trimTrailingWhitespace()
        endWithNewline()
    }
}
