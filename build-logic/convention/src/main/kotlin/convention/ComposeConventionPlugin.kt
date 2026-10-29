package convention

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.PathSensitivity
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.compose.compiler.gradle.ComposeCompilerGradlePluginExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompilationTask

/** Property that turns on Compose compiler reports and metrics (`-Pkmp.composeCompilerReports=true`). */
private const val COMPOSE_REPORTS_PROPERTY = "kmp.composeCompilerReports"

/**
 * Compose Multiplatform plus the Compose compiler.
 *
 * The compiler reads `config/compose/stability.conf`. With `-Pkmp.composeCompilerReports=true`
 * it also writes reports to `build/compose-reports/` and metrics to `build/compose-metrics/`.
 */
class ComposeConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("compose-multiplatform"))
        pluginManager.apply(libs.pluginId("compose-compiler"))

        val stabilityConfig = isolated.rootProject.projectDirectory.file("config/compose/stability.conf")
        extensions.configure<ComposeCompilerGradlePluginExtension> {
            stabilityConfigurationFiles.add(stabilityConfig)
            if (providers.gradleProperty(COMPOSE_REPORTS_PROPERTY).orNull.toBoolean()) {
                reportsDestination.set(layout.buildDirectory.dir("compose-reports"))
                metricsDestination.set(layout.buildDirectory.dir("compose-metrics"))
            }
        }

        // The Compose plugin passes the file's path to the compiler but does not fingerprint its
        // contents, so an edited stability.conf would leave compile tasks UP-TO-DATE (and reuse
        // build-cache entries) with the old stability inference. Track the contents explicitly.
        tasks.withType<KotlinCompilationTask<*>>().configureEach {
            inputs.file(stabilityConfig)
                .withPropertyName("composeStabilityConfiguration")
                .withPathSensitivity(PathSensitivity.NONE)
        }
    }
}
