package convention

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalog
import org.gradle.api.plugins.BasePlugin
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.register

/** Repositories `verifyCatalog` looks in, in order: the ones settings.gradle.kts resolves from. */
private val CATALOG_REPOSITORIES = listOf(
    "https://repo.maven.apache.org/maven2",
    "https://dl.google.com/dl/android/maven2",
    "https://plugins.gradle.org/m2",
)

/**
 * Root-project wiring.
 *
 * - Applies `base`, so the root has the `check` lifecycle task. `./gradlew check` runs `check`
 *   in every project: Spotless, detekt, tests, Kover verification and lint.
 * - Formats files that belong to no module: root build scripts, `build-logic/`, docs and config.
 *   Targets are explicit paths, never a bare `**`, so Spotless never walks `build/` directories
 *   that other tasks are writing to.
 * - Registers `verifyCatalog`, which proves every coordinate in `libs.versions.toml` exists.
 *   It is not part of `check`, because it needs the network.
 */
class RootConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        check(path == ":") { "convention.root must be applied to the root project only" }
        apply<BasePlugin>()

        configureSpotless(
            kotlinTargets = listOf("build-logic/*/src/**/*.kt"),
            kotlinGradleTargets = listOf("*.gradle.kts", "build-logic/*.gradle.kts", "build-logic/*/*.gradle.kts"),
        ) {
            format("misc") {
                target("*.md", "docs/**/*.md", ".gitignore", "config/**/*.yml")
                trimTrailingWhitespace()
                endWithNewline()
            }
        }

        val catalog = libs
        tasks.register<VerifyCatalogTask>("verifyCatalog") {
            group = "verification"
            description = "Checks that the POM of every library and plugin in libs.versions.toml is published."
            entries.set(catalog.coordinates())
            repositories.set(CATALOG_REPOSITORIES)
        }
    }

    /** `libs.<alias> -> group:name:version`. A plugin is checked through its marker artifact. */
    private fun VersionCatalog.coordinates(): List<String> = libraryAliases.map { alias ->
        val library = findLibrary(alias).get().get()
        "libs.$alias -> ${library.module}:${library.versionConstraint.requiredVersion}"
    } +
        pluginAliases.map { alias ->
            val plugin = findPlugin(alias).get().get()
            val id = plugin.pluginId
            "libs.plugins.$alias -> $id:$id.gradle.plugin:${plugin.version.requiredVersion}"
        }
}
