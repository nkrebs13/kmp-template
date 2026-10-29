package convention

import org.gradle.api.Action
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.ExtensionAware
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.jvm.toolchain.JavaLanguageVersion
import org.gradle.jvm.toolchain.JavaToolchainService
import org.gradle.jvm.toolchain.JavaToolchainSpec
import org.gradle.jvm.toolchain.JvmVendorSpec
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.getByType
import org.jetbrains.compose.ComposeExtension
import org.jetbrains.compose.desktop.DesktopExtension
import org.jetbrains.compose.desktop.application.dsl.TargetFormat
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
import java.util.UUID

/**
 * The installer version is the leading `major.minor.patch` of `app.versionName`, so `1.2.0-beta`
 * packages as `1.2.0`. Compose validates it for each format (Msi: major and minor at most 255).
 * A pre-release and its final release therefore share an installer version, and Windows will not
 * upgrade one to the other: ship pre-release installers under a lower patch number.
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

        // JetBrains Runtime for compiling, running and packaging: Compose packaging rejects some JDK
        // builds (Homebrew's, among others) and Hot Reload works best on it. Downloaded on first use.
        val jetBrainsRuntime: Action<JavaToolchainSpec> = Action {
            languageVersion.set(JavaLanguageVersion.of(JDK_TOOLCHAIN_VERSION))
            vendor.set(JvmVendorSpec.JETBRAINS)
        }
        extensions.configure<KotlinJvmProjectExtension> {
            jvmToolchain(jetBrainsRuntime)
            compilerOptions.jvmTarget.set(KOTLIN_JVM_TARGET)
        }
        // Packaging otherwise uses the Gradle daemon's JVM, whatever vendor that is.
        val packagingJdk = extensions.getByType<JavaToolchainService>().launcherFor(jetBrainsRuntime)
            .map { it.metadata.installationPath.asFile.absolutePath }

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
                    javaHome = packagingJdk.get()
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
