package convention

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction
import org.gradle.kotlin.dsl.register
import org.gradle.work.DisableCachingByDefault
import java.io.StringReader
import java.util.Properties

/** Release packaging tasks that must not run with a partial signing configuration. */
private val RELEASE_PACKAGING_TASKS = setOf("packageRelease", "bundleRelease")

/** A credential, as an environment variable and as a `local.properties` key. */
private enum class SigningKey(val env: String, val property: String) {
    STORE_FILE("SIGNING_STORE_FILE", "signing.storeFile"),
    STORE_PASSWORD("SIGNING_STORE_PASSWORD", "signing.storePassword"),
    KEY_ALIAS("SIGNING_KEY_ALIAS", "signing.keyAlias"),
    KEY_PASSWORD("SIGNING_KEY_PASSWORD", "signing.keyPassword"),
}

/**
 * Signs the release build type when one source holds the whole credential set:
 *
 * 1. the `SIGNING_*` environment variables, if any of them is set, else
 * 2. the `signing.*` keys in `local.properties`, else
 * 3. nothing: the release build is unsigned.
 *
 * Sources are never mixed, and blank values count as absent. A partial set in the chosen source
 * (some values, but not all) does not break configuration, so debug builds, lint, tests and `clean`
 * keep working. Instead `verifyReleaseSigning` fails release packaging, naming the missing keys
 * (never their values). `storeFile` is absolute, or relative to the repository root.
 */
internal fun Project.configureReleaseSigning(android: ApplicationExtension) {
    val env = SigningKey.entries.associateWith { providers.environmentVariable(it.env).orNull.nonBlank() }
    val local = localProperties().let { props ->
        SigningKey.entries.associateWith { props.getProperty(it.property).nonBlank() }
    }

    // Any SIGNING_* variable makes the environment the source; local.properties is consulted only
    // when none is set. A partial environment never falls back to a local keystore.
    val fromEnv = env.values.any { it != null }
    val source = if (fromEnv) env else local
    val credentials = source.complete()
    if (credentials != null) {
        val release = android.signingConfigs.create("release") {
            storeFile = isolated.rootProject.projectDirectory.file(credentials.getValue(SigningKey.STORE_FILE)).asFile
            storePassword = credentials.getValue(SigningKey.STORE_PASSWORD)
            keyAlias = credentials.getValue(SigningKey.KEY_ALIAS)
            keyPassword = credentials.getValue(SigningKey.KEY_PASSWORD)
        }
        android.buildTypes.getByName("release").signingConfig = release
        return
    }

    val missing = source.missingKeys(if (fromEnv) SigningKey::env else SigningKey::property)
        ?: return // Nothing configured: an unsigned release build is intended.
    val sourceName = if (fromEnv) "environment variables" else "local.properties"

    val verify = tasks.register<VerifyReleaseSigningTask>("verifyReleaseSigning") {
        message.set(
            "Release signing is partially configured ($sourceName: missing $missing). " +
                "Set all four in one place, or none for an unsigned build.",
        )
    }
    tasks.named { it in RELEASE_PACKAGING_TASKS }.configureEach { dependsOn(verify) }
}

private fun Project.localProperties(): Properties = Properties().apply {
    val file = isolated.rootProject.projectDirectory.file("local.properties")
    providers.fileContents(file).asText.orNull?.let { load(StringReader(it)) }
}

private fun String?.nonBlank(): String? = this?.takeIf { it.isNotBlank() }

private fun Map<SigningKey, String?>.complete(): Map<SigningKey, String>? =
    if (values.all { it != null }) mapValues { checkNotNull(it.value) } else null

/** The names of the absent keys, or null when this source is empty (or complete). */
private fun Map<SigningKey, String?>.missingKeys(name: (SigningKey) -> String): String? {
    val absent = filterValues { it == null }.keys
    return if (absent.isEmpty() || absent.size == size) null else absent.joinToString(transform = name)
}

/** Fails release packaging when signing is partially configured. */
@DisableCachingByDefault(because = "Only fails the build; produces no output")
abstract class VerifyReleaseSigningTask : DefaultTask() {
    @get:Input
    abstract val message: Property<String>

    @TaskAction
    fun fail(): Unit = throw GradleException(message.get())
}
