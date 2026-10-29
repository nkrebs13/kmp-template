package convention

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure

/**
 * An Android application: SDK levels from `libs.versions.toml`, version from `gradle.properties`
 * (`app.applicationId`, `app.versionCode`, `app.versionName`; override with `-P`), lint warnings as errors, and release
 * signing when credentials are available (see `ReleaseSigning.kt`).
 */
class AndroidApplicationConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("android-application"))
        apply<QualityConventionPlugin>()

        extensions.configure<ApplicationExtension> {
            configureAndroidCommon(this)
            defaultConfig {
                targetSdk = libs.versionInt("android-target-sdk")
                applicationId = requiredGradleProperty("app.applicationId")
                versionCode = requiredGradleProperty("app.versionCode").toIntOrNull()
                    ?: error("app.versionCode must be an integer")
                versionName = requiredGradleProperty("app.versionName")
            }
            configureReleaseSigning(this)
        }

        // AGP 9.5 still reads this flag: it sets the IDE model's JETPACK_COMPOSE flag and registers
        // the Compose Preview task. Turning it on without the Compose compiler plugin fails the
        // build, so it follows that plugin (applied by convention.compose).
        pluginManager.withPlugin(libs.pluginId("compose-compiler")) {
            extensions.configure<ApplicationExtension> {
                buildFeatures.compose = true
            }
        }
    }

    private fun Project.requiredGradleProperty(name: String): String =
        providers.gradleProperty(name).orNull ?: error("Missing '$name' in gradle.properties")
}
