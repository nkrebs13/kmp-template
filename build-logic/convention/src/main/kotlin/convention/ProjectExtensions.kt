package convention

import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalog
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.kotlin.dsl.getByType
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

/** JDK that compiles everything (Gradle toolchain; foojay provisions it when missing). */
const val JDK_TOOLCHAIN_VERSION = 21

/** Bytecode level every JVM/Android compilation emits. The one place it is defined. */
val JVM_BYTECODE_VERSION: JavaVersion = JavaVersion.VERSION_17

/** Kotlin's view of [JVM_BYTECODE_VERSION]. */
val KOTLIN_JVM_TARGET: JvmTarget = JvmTarget.fromTarget(JVM_BYTECODE_VERSION.toString())

internal val Project.libs: VersionCatalog
    get() = extensions.getByType<VersionCatalogsExtension>().named("libs")

internal fun VersionCatalog.versionString(alias: String): String = findVersion(alias)
    .orElseThrow { IllegalStateException("Missing [versions] entry '$alias' in libs.versions.toml") }
    .requiredVersion

internal fun VersionCatalog.versionInt(alias: String): Int = versionString(alias).toIntOrNull()
    ?: error("[versions] entry '$alias' in libs.versions.toml must be an integer")

internal fun VersionCatalog.library(alias: String) =
    findLibrary(alias).orElseThrow { IllegalStateException("Missing [libraries] entry '$alias' in libs.versions.toml") }

internal fun VersionCatalog.pluginId(alias: String): String = findPlugin(alias)
    .orElseThrow { IllegalStateException("Missing [plugins] entry '$alias' in libs.versions.toml") }
    .get()
    .pluginId
