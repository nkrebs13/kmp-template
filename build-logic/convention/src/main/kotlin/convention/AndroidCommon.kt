package convention

import com.android.build.api.dsl.CommonExtension
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension

/**
 * What every Android module with a `com.android.*` plugin shares: SDK levels from
 * `libs.versions.toml`, Java/Kotlin bytecode level, the JDK toolchain and lint warnings as errors.
 * Used by `convention.android.application` and `convention.android.test`.
 */
internal fun Project.configureAndroidCommon(android: CommonExtension) {
    android.apply {
        compileSdk = libs.versionInt("android-compile-sdk")
        defaultConfig.minSdk = libs.versionInt("android-min-sdk")
        compileOptions.sourceCompatibility = JVM_BYTECODE_VERSION
        compileOptions.targetCompatibility = JVM_BYTECODE_VERSION
        lint.warningsAsErrors = true
        // Version-upgrade notices are informational, not bugs; Dependabot handles upgrades.
        lint.disable +=
            setOf("AndroidGradlePluginVersion", "GradleDependency", "NewerVersionAvailable", "OldTargetApi")
    }

    extensions.configure<KotlinAndroidProjectExtension> {
        jvmToolchain(JDK_TOOLCHAIN_VERSION)
        compilerOptions.jvmTarget.set(KOTLIN_JVM_TARGET)
    }
}
