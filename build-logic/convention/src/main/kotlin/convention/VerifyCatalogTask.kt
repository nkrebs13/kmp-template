package convention

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.provider.MapProperty
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault

/**
 * Fails when any catalog coordinate does not resolve, naming the alias, so a typo or a version
 * that was never published cannot sit unnoticed in an entry nothing references.
 */
@DisableCachingByDefault(because = "Checks remote repositories; there is no file output to cache")
abstract class VerifyCatalogTask : DefaultTask() {
    /** `libs.<alias>` to `group:name:version` (plugins are checked through their marker artifact). */
    @get:Input
    abstract val coordinates: MapProperty<String, String>

    /** `group:name:version` to the reason its POM could not be fetched. */
    @get:Input
    abstract val failures: MapProperty<String, String>

    init {
        outputs.upToDateWhen { false }
    }

    @TaskAction
    fun verify() {
        val failed = failures.get()
        val broken = coordinates.get().filterValues { it in failed }
        if (broken.isNotEmpty()) {
            throw GradleException(
                buildString {
                    appendLine("${broken.size} of ${coordinates.get().size} version catalog entries do not resolve:")
                    broken.toSortedMap().forEach { (alias, coordinate) ->
                        appendLine("  $alias -> $coordinate")
                        failed.getValue(coordinate).lineSequence().firstOrNull()?.let { appendLine("      $it") }
                    }
                    append("Fix the coordinate or version in gradle/libs.versions.toml.")
                },
            )
        }
        logger.lifecycle("All ${coordinates.get().size} version catalog coordinates resolve.")
    }
}
