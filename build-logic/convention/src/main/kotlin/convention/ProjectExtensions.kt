package convention

import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.artifacts.MinimalExternalModuleDependency
import org.gradle.api.artifacts.VersionCatalog
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.api.provider.Provider
import org.gradle.kotlin.dsl.getByType
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Optional

/**
 * JDK that compiles everything (Gradle toolchain; foojay provisions it when missing).
 * Keep in sync with the other places 21 must appear literally: `jvmToolchain` in
 * `build-logic/convention/build.gradle.kts`, `gradle/gradle-daemon-jvm.properties`
 * (regenerate with `./gradlew updateDaemonJvm --jvm-version=21`), `.tool-versions` and CI.
 */
const val JDK_TOOLCHAIN_VERSION: Int = 21

/** Bytecode level every Java/Android compilation emits. Keep equal to [KOTLIN_JVM_TARGET]. */
val JVM_BYTECODE_VERSION: JavaVersion = JavaVersion.VERSION_17

/** Bytecode level every Kotlin/JVM compilation emits. Keep equal to [JVM_BYTECODE_VERSION]. */
val KOTLIN_JVM_TARGET: JvmTarget = JvmTarget.JVM_17

internal val Project.libs: VersionCatalog
    get() = extensions.getByType<VersionCatalogsExtension>().named("libs")

internal fun VersionCatalog.versionString(alias: String): String =
    findVersion(alias).orFail("versions", alias).requiredVersion

internal fun VersionCatalog.versionInt(alias: String): Int = versionString(alias).toIntOrNull()
    ?: error("[versions] entry '$alias' in libs.versions.toml must be an integer")

internal fun VersionCatalog.library(alias: String): Provider<MinimalExternalModuleDependency> =
    findLibrary(alias).orFail("libraries", alias)

internal fun VersionCatalog.pluginId(alias: String): String = findPlugin(alias).orFail("plugins", alias).get().pluginId

private fun <T : Any> Optional<T>.orFail(section: String, alias: String): T =
    orElseThrow { IllegalStateException("Missing [$section] entry '$alias' in libs.versions.toml") }
