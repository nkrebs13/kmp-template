package convention

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension
import java.io.StringReader
import java.util.Properties

/**
 * An Android application: SDK levels from `libs.versions.toml`, version from `gradle.properties`
 * (`app.versionCode`, `app.versionName`; override with `-P`), zero-tolerance lint, and release
 * signing when credentials are available.
 *
 * Release signing is configured only when all four values are present, from environment variables
 * (`SIGNING_STORE_FILE`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`)
 * or from `local.properties` (`signing.storeFile`, `signing.storePassword`, `signing.keyAlias`,
 * `signing.keyPassword`). Environment variables win. Without them the release build is unsigned.
 */
class AndroidApplicationConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("androidApplication"))
        apply<QualityConventionPlugin>()

        extensions.configure<ApplicationExtension> {
            compileSdk = libs.versionInt("android-compileSdk")
            defaultConfig {
                minSdk = libs.versionInt("android-minSdk")
                targetSdk = libs.versionInt("android-targetSdk")
                versionCode = requiredGradleProperty("app.versionCode").toIntOrNull()
                    ?: error("app.versionCode must be an integer")
                versionName = requiredGradleProperty("app.versionName")
            }
            compileOptions {
                sourceCompatibility = JVM_BYTECODE_VERSION
                targetCompatibility = JVM_BYTECODE_VERSION
            }
            lint {
                warningsAsErrors = true
                abortOnError = true
                checkReleaseBuilds = true
                checkDependencies = false
                // Version-upgrade notices are informational, not bugs; Dependabot handles upgrades.
                disable +=
                    setOf("AndroidGradlePluginVersion", "GradleDependency", "NewerVersionAvailable", "OldTargetApi")
            }
            releaseSigning()?.let { signing ->
                val release =
                    signingConfigs.create("release") {
                        storeFile =
                            isolated.rootProject.projectDirectory
                                .file(signing.storeFile)
                                .asFile
                        storePassword = signing.storePassword
                        keyAlias = signing.keyAlias
                        keyPassword = signing.keyPassword
                    }
                buildTypes.getByName("release").signingConfig = release
            }
        }

        extensions.configure<KotlinAndroidProjectExtension> {
            jvmToolchain(JDK_TOOLCHAIN_VERSION)
            compilerOptions.jvmTarget.set(KOTLIN_JVM_TARGET)
        }
    }

    private fun Project.requiredGradleProperty(name: String): String =
        providers.gradleProperty(name).orNull ?: error("Missing '$name' in gradle.properties")

    private fun Project.releaseSigning(): SigningCredentials? {
        val localFile = isolated.rootProject.projectDirectory.file("local.properties")
        val local =
            Properties().apply {
                providers
                    .fileContents(localFile)
                    .asText.orNull
                    ?.let { load(StringReader(it)) }
            }
        val values =
            SIGNING_KEYS.map { (env, property) ->
                providers.environmentVariable(env).orNull ?: local.getProperty(property).orEmpty()
            }
        return when {
            values.all { it.isBlank() } -> {
                null
            }

            values.any { it.isBlank() } -> {
                error(
                    "Release signing is partially configured. Set all of " +
                        SIGNING_KEYS.joinToString { (env, property) -> "$env/$property" } + ", or none.",
                )
            }

            else -> {
                val (storeFile, storePassword, keyAlias, keyPassword) = values
                SigningCredentials(storeFile, storePassword, keyAlias, keyPassword)
            }
        }
    }

    private data class SigningCredentials(
        val storeFile: String,
        val storePassword: String,
        val keyAlias: String,
        val keyPassword: String,
    )

    private companion object {
        /** Environment variable to `local.properties` key, in [SigningCredentials] order. */
        val SIGNING_KEYS =
            listOf(
                "SIGNING_STORE_FILE" to "signing.storeFile",
                "SIGNING_STORE_PASSWORD" to "signing.storePassword",
                "SIGNING_KEY_ALIAS" to "signing.keyAlias",
                "SIGNING_KEY_PASSWORD" to "signing.keyPassword",
            )
    }
}
