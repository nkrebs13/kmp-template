package convention

import com.diffplug.spotless.extra.wtp.EclipseWtpFormatterStep
import io.gitlab.arturbosch.detekt.extensions.DetektExtension
import kotlinx.kover.gradle.plugin.dsl.KoverProjectExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.register

/**
 * Formatting (Spotless: ktlint for Kotlin, Eclipse WTP for XML), static analysis (detekt + Compose
 * rules), a print/println check (`checkForbiddenCalls`) and coverage (Kover) for one module. Applied by every other convention plugin, so each
 * module checks its own sources and `./gradlew check` covers them all.
 *
 * ktlint settings live in the root `.editorconfig`; detekt settings in `config/detekt/detekt.yml`.
 * Nothing auto-corrects during `check`: run `./gradlew spotlessApply` to format.
 */
class QualityConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("detekt"))
        pluginManager.apply(libs.pluginId("kover"))

        configureSpotless(kotlinTargets = listOf("src/**/*.kt"), kotlinGradleTargets = listOf("*.gradle.kts")) {
            format("xml") {
                target("src/**/*.xml")
                eclipseWtp(EclipseWtpFormatterStep.XML)
            }
        }
        configureDetekt()
        configureKover()
        configureForbiddenCalls()
    }

    private fun Project.configureForbiddenCalls() {
        val checkForbiddenCalls = tasks.register<CheckForbiddenCallsTask>("checkForbiddenCalls") {
            group = "verification"
            description = "Fails on print/println in production Kotlin sources (use AppLogger)."
            // Production source sets only: src/main, src/commonMain, src/androidMain, ...
            sources.from(fileTree("src") { include("main/**/*.kt", "*Main/**/*.kt") })
            marker.set(layout.buildDirectory.file("checkForbiddenCalls/ok"))
        }
        pluginManager.withPlugin("base") { tasks.named("check") { dependsOn(checkForbiddenCalls) } }
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
