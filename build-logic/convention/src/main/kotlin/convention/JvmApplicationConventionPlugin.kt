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

/**
 * The installer version is the leading `major.minor.patch` of `app.versionName`, so `1.2.0-beta`
 * packages as `1.2.0`. Compose validates it for each format (Msi: major and minor at most 255).
 */
private val PACKAGE_VERSION_PREFIX = Regex("""^\d+\.\d+\.\d+""")

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
        val packageVersion = PACKAGE_VERSION_PREFIX.find(versionName)?.value ?: versionName

        val packageName = requiredGradleProperty("app.packageName")
        val applicationId = requiredGradleProperty("app.applicationId")
        extensions.configure<ComposeExtension> {
            (this as ExtensionAware).extensions.configure<DesktopExtension>("desktop") {
                application {
                    nativeDistributions {
                        targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
                        this.packageName = packageName
                        this.packageVersion = packageVersion
                        // Deb package names must be lowercase.
                        linux {
                            this.packageName = packageName.lowercase()
                        }
                        // A stable per-app UUID lets a new MSI upgrade the installed one; the
                        // application ID keeps it unique across projects that share a name.
                        windows {
                            upgradeUuid = UUID.nameUUIDFromBytes(applicationId.toByteArray()).toString()
                        }
                    }
                }
            }
        }
    }

    private fun Project.requiredGradleProperty(name: String): String =
        providers.gradleProperty(name).orNull ?: error("Missing '$name' in gradle.properties")
}
