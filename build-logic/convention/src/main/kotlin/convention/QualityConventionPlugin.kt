package convention

import com.diffplug.gradle.spotless.SpotlessExtension
import com.diffplug.spotless.LineEnding
import com.diffplug.spotless.extra.wtp.EclipseWtpFormatterStep
import io.gitlab.arturbosch.detekt.extensions.DetektExtension
import kotlinx.kover.gradle.plugin.dsl.KoverProjectExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.dependencies

/**
 * Formatting (Spotless: ktlint for Kotlin, Eclipse WTP for XML), static analysis (detekt + Compose
 * rules) and coverage (Kover) for one module. Applied by every other convention plugin, so each
 * module checks its own sources and `./gradlew check` covers them all.
 *
 * ktlint settings live in the root `.editorconfig`; detekt settings in `config/detekt/detekt.yml`.
 * Nothing auto-corrects during `check`: run `./gradlew spotlessApply` to format.
 */
class QualityConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("spotless"))
        pluginManager.apply(libs.pluginId("detekt"))
        pluginManager.apply(libs.pluginId("kover"))

        configureSpotless()
        configureDetekt()
        configureKover()
    }

    private fun Project.configureSpotless() {
        val ktlintVersion = libs.versionString("ktlint")
        val ktlintSettings = ktlintEditorConfigOverride()
        extensions.configure<SpotlessExtension> {
            // Explicit LF (what .gitattributes asks for) instead of the default, which reads
            // .gitattributes through JGit at configuration time and makes the configuration cache
            // depend on the PATH environment variable.
            lineEndings = LineEnding.UNIX
            kotlin {
                target("src/**/*.kt")
                ktlint(ktlintVersion).editorConfigOverride(ktlintSettings)
            }
            kotlinGradle {
                target("*.gradle.kts")
                ktlint(ktlintVersion).editorConfigOverride(ktlintSettings)
            }
            format("xml") {
                target("src/**/*.xml")
                eclipseWtp(EclipseWtpFormatterStep.XML)
            }
        }
    }

    private fun Project.configureDetekt() {
        extensions.configure<DetektExtension> {
            buildUponDefaultConfig = true
            config.setFrom(isolated.rootProject.projectDirectory.file("config/detekt/detekt.yml"))
            source.setFrom(layout.projectDirectory.dir("src"))
        }
        dependencies {
            add("detektPlugins", libs.library("compose-rules-detekt"))
        }
    }

    private fun Project.configureKover() {
        extensions.configure<KoverProjectExtension> {
            reports {
                filters {
                    excludes {
                        androidGeneratedClasses()
                        // Compose previews are rendered by the IDE, never by tests
                        annotatedBy("androidx.compose.ui.tooling.preview.Preview")
                        classes(
                            // Compose compiler-generated singletons (not reachable from unit tests)
                            "*ComposableSingletons*",
                            // Compose Multiplatform generated resource accessors
                            "*.generated.resources.*",
                        )
                    }
                }
            }
        }
    }
}
