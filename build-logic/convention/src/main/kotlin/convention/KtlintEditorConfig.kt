package convention

import org.gradle.api.Project

private const val KOTLIN_SECTION = "[*.{kt,kts}]"

/**
 * The `[*.{kt,kts}]` section of the root `.editorconfig`, for Spotless's `editorConfigOverride`.
 *
 * `.editorconfig` stays the single source that IntelliJ and ktlint read. Passing its values to
 * Spotless as well puts them in the step state: Spotless keeps ktlint engines alive in the daemon,
 * keyed by that state, and an engine caches the `.editorconfig` it parsed. Without this, an edited
 * `.editorconfig` would be formatted with the old settings and that result stored in the build
 * cache. (`setEditorConfigPath` would also key on the file, but as of Spotless 8.10.4 it throws a
 * NullPointerException whenever the configuration cache is reused.)
 */
fun Project.ktlintEditorConfigOverride(): Map<String, String> {
    val editorConfig = isolated.rootProject.projectDirectory.file(".editorconfig")
    val text = providers.fileContents(editorConfig).asText.orNull
        ?: error("Missing .editorconfig at the project root")
    var inSection = false
    val values = buildMap {
        text.lineSequence().map(String::trim).forEach { line ->
            when {
                line.startsWith("[") -> inSection = line == KOTLIN_SECTION

                inSection && line.isNotEmpty() && !line.startsWith("#") && !line.startsWith(";") -> {
                    val (key, value) = line.split("=", limit = 2).map(String::trim)
                    put(key, value)
                }
            }
        }
    }
    check(values.isNotEmpty()) { ".editorconfig has no $KOTLIN_SECTION section" }
    return values
}
