package convention

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.ExtensionAware
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.jetbrains.compose.ComposeExtension
import org.jetbrains.compose.desktop.DesktopExtension
import org.jetbrains.compose.desktop.application.dsl.TargetFormat
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
import java.util.UUID

/** `major.minor.patch` with major > 0: Dmg rejects a 0 major, and Msi needs numeric parts. */
private val PACKAGE_VERSION_PATTERN = Regex("""[1-9]\d*\.\d+\.\d+""")

/**
 * A Compose Multiplatform desktop (JVM) application.
 *
 * Installer name and version come from `gradle.properties` (`app.packageName`, `app.versionName`).
 * The module must set `compose.desktop { application { mainClass = "…" } }`; the plugin cannot
 * know the entry point.
 */
class JvmApplicationConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("kotlin-jvm"))
        apply<ComposeConventionPlugin>()
        apply<QualityConventionPlugin>()

        extensions.configure<KotlinJvmProjectExtension> {
            jvmToolchain(JDK_TOOLCHAIN_VERSION)
            compilerOptions.jvmTarget.set(KOTLIN_JVM_TARGET)
        }

        // The Kotlin plugin applies the java plugin; keep javac on the same bytecode level as kotlinc.
        extensions.configure<JavaPluginExtension> {
            sourceCompatibility = JVM_BYTECODE_VERSION
            targetCompatibility = JVM_BYTECODE_VERSION
        }

        val versionName = requiredGradleProperty("app.versionName")
        require(PACKAGE_VERSION_PATTERN.matches(versionName)) {
            "app.versionName '$versionName' must look like 1.0.0 (numeric major.minor.patch, major > 0) " +
                "so Dmg and Msi packaging accept it"
        }
        val packageName = requiredGradleProperty("app.packageName")
        extensions.configure<ComposeExtension> {
            (this as ExtensionAware).extensions.configure<DesktopExtension>("desktop") {
                application {
                    nativeDistributions {
                        targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
                        this.packageName = packageName
                        packageVersion = versionName
                        // Deb package names must be lowercase.
                        linux {
                            this.packageName = packageName.lowercase()
                        }
                        // A stable per-app UUID lets a new MSI upgrade the installed one.
                        windows {
                            upgradeUuid = UUID.nameUUIDFromBytes(packageName.toByteArray()).toString()
                        }
                    }
                }
            }
        }
    }

    private fun Project.requiredGradleProperty(name: String): String =
        providers.gradleProperty(name).orNull ?: error("Missing '$name' in gradle.properties")
}
