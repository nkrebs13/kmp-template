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

/**
 * A Compose Multiplatform desktop (JVM) application.
 *
 * Name and version come from `gradle.properties` (`app.displayName`, `app.versionName`). The
 * display name reaches the running app as the `app.displayName` system property. The module sets
 * `compose.desktop { application { mainClass = "…" } }`.
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

        val displayName = requiredGradleProperty("app.displayName")
        val versionName = requiredGradleProperty("app.versionName")
        val packageName = requiredGradleProperty("app.packageName")
        extensions.configure<ComposeExtension> {
            (this as ExtensionAware).extensions.configure<DesktopExtension>("desktop") {
                application {
                    jvmArgs("-Dapp.displayName=$displayName")
                    nativeDistributions {
                        targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
                        this.packageName = packageName
                        packageVersion = versionName
                    }
                }
            }
        }
    }

    private fun Project.requiredGradleProperty(name: String): String =
        providers.gradleProperty(name).orNull ?: error("Missing '$name' in gradle.properties")
}
