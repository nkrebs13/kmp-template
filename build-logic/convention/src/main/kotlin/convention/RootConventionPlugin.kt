package convention

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalog
import org.gradle.api.artifacts.component.ModuleComponentIdentifier
import org.gradle.api.artifacts.result.ResolvedArtifactResult
import org.gradle.api.artifacts.result.UnresolvedArtifactResult
import org.gradle.api.artifacts.result.UnresolvedComponentResult
import org.gradle.api.plugins.BasePlugin
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.register
import org.gradle.maven.MavenModule
import org.gradle.maven.MavenPomArtifact

/**
 * Root-project wiring.
 *
 * - Applies `base`, so the root has the `check` lifecycle task. `./gradlew check` runs `check`
 *   in every project: Spotless, detekt, tests, Kover verification and lint.
 * - Registers `verifyCatalog`, which proves every coordinate in `libs.versions.toml` exists.
 *   It is not part of `check`, because it needs the network.
 */
class RootConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        check(path == ":") { "convention.root must be applied to the root project only" }
        apply<BasePlugin>()

        tasks.register<VerifyCatalogTask>("verifyCatalog") {
            group = "verification"
            description = "Resolves the POM of every library and plugin in libs.versions.toml."
            val catalogCoordinates = libs.coordinates()
            coordinates.set(catalogCoordinates)
            failures.set(provider { pomFailures(catalogCoordinates.values) })
        }
    }

    /** `libs.<alias>` to `group:name:version`. A plugin is checked through its marker artifact. */
    private fun VersionCatalog.coordinates(): Map<String, String> = buildMap {
        libraryAliases.forEach { alias ->
            val library = findLibrary(alias).get().get()
            put("libs.$alias", "${library.module}:${library.versionConstraint.requiredVersion}")
        }
        pluginAliases.forEach { alias ->
            val plugin = findPlugin(alias).get().get()
            val id = plugin.pluginId
            put("libs.plugins.$alias", "$id:$id.gradle.plugin:${plugin.version.requiredVersion}")
        }
    }

    /**
     * Fetches each module's POM through the project repositories. Asking for the POM directly
     * (rather than resolving a dependency) skips variant matching, so it works the same for JVM,
     * Android and iOS-only modules and for plugin markers. Returns coordinate to failure reason.
     */
    private fun Project.pomFailures(coordinates: Collection<String>): Map<String, String> {
        val query = dependencies.createArtifactResolutionQuery()
        coordinates.forEach { coordinate ->
            val (group, name, version) = coordinate.split(':')
            query.forModule(group, name, version)
        }
        val result = query.withArtifacts(MavenModule::class.java, MavenPomArtifact::class.java).execute()
        val failures = mutableMapOf<String, String>()
        result.components.forEach { component ->
            val coordinate = (component.id as ModuleComponentIdentifier).displayName
            when (component) {
                is UnresolvedComponentResult -> failures[coordinate] = component.failure.message.orEmpty()

                else -> {
                    val poms = result.resolvedComponents.single { it.id == component.id }
                        .getArtifacts(MavenPomArtifact::class.java)
                    if (poms.none { it is ResolvedArtifactResult }) {
                        failures[coordinate] = poms.filterIsInstance<UnresolvedArtifactResult>()
                            .joinToString { it.failure.message.orEmpty() }
                            .ifEmpty { "no POM published" }
                    }
                }
            }
        }
        return failures
    }
}
