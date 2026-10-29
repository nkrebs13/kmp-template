package convention

import com.diffplug.gradle.spotless.SpotlessExtension
import com.diffplug.spotless.LineEnding
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure

private const val KOTLIN_SECTION = "[*.{kt,kts}]"

/**
 * Applies Spotless with ktlint for [kotlinTargets] and [kotlinGradleTargets], then [extra] for
 * any other formats. Shared by `convention.quality` (a module's own sources) and
 * `convention.root` (files that belong to no module).
 */
internal fun Project.configureSpotless(
    kotlinTargets: List<String>,
    kotlinGradleTargets: List<String>,
    extra: SpotlessExtension.() -> Unit = {},
) {
    pluginManager.apply(libs.pluginId("spotless"))
    val ktlintVersion = libs.versionString("ktlint")
    val ktlintSettings = ktlintEditorConfigOverride()
    extensions.configure<SpotlessExtension> {
        // Explicit LF (what .gitattributes asks for) instead of the default, which reads
        // .gitattributes through JGit at configuration time and makes the configuration cache
        // depend on the PATH environment variable.
        lineEndings = LineEnding.UNIX
        kotlin {
            target(kotlinTargets)
            ktlint(ktlintVersion).editorConfigOverride(ktlintSettings)
        }
        kotlinGradle {
            target(kotlinGradleTargets)
            ktlint(ktlintVersion).editorConfigOverride(ktlintSettings)
        }
        extra()
    }
}

/**
 * The `[*.{kt,kts}]` section of the root `.editorconfig`, passed to Spotless as
 * `editorConfigOverride`.
 *
 * `.editorconfig` stays the single source that IntelliJ and ktlint read. Passing its values to
 * Spotless as well puts them in the step state: Spotless keeps ktlint engines alive in the daemon,
 * keyed by that state, and an engine caches the `.editorconfig` it parsed, so without this an
 * edited `.editorconfig` is formatted with the old settings and that result is stored in the
 * build cache. Spotless's `setEditorConfigPath` would key on the file instead, but in Spotless
 * 8.10.4 it throws `NullPointerException: ... "this.files" is null` whenever the configuration
 * cache is reused (no upstream issue as of 2026-10-29). Remove this once that is fixed: switch to
 * `setEditorConfigPath`, then run `./gradlew spotlessCheck` twice (the second run must print
 * "Reusing configuration cache") and edit `ktlint_code_style` in a warm daemon to see it apply.
 */
private fun Project.ktlintEditorConfigOverride(): Map<String, String> {
    val editorConfig = isolated.rootProject.projectDirectory.file(".editorconfig")
    val text = providers.fileContents(editorConfig).asText.orNull
        ?: error("Missing .editorconfig at the project root")
    var inSection = false
    val values = buildMap {
        text.lineSequence().map(String::trim).forEach { line ->
            when {
                line.startsWith("[") -> inSection = line == KOTLIN_SECTION

                inSection && line.isNotEmpty() && !line.startsWith("#") && !line.startsWith(";") -> {
                    val parts = line.split("=", limit = 2).map(String::trim)
                    check(parts.size == 2 && parts[0].isNotEmpty()) {
                        ".editorconfig: expected 'key = value' in $KOTLIN_SECTION, found '$line'"
                    }
                    put(parts[0], parts[1])
                }
            }
        }
    }
    check(values.isNotEmpty()) { ".editorconfig has no $KOTLIN_SECTION section" }
    return values
}
