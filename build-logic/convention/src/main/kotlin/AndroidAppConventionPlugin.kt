import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import java.time.LocalDate
import java.util.Properties

class AndroidAppConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            val versionProps = Properties().apply {
                rootProject.file("version.properties").inputStream().use { load(it) }
            }
            val patch = versionProps.getProperty("VERSION_PATCH", "0").toInt()

            val ciYear = providers.environmentVariable("VERSION_YEAR")
            val ciMonth = providers.environmentVariable("VERSION_MONTH")

            val year = ciYear.orNull?.toIntOrNull() ?: LocalDate.now().year
            val month = ciMonth.orNull?.toIntOrNull() ?: LocalDate.now().monthValue

            // versionCode: YYYYMM00 + patch (max 99 patches per month)
            val versionCode = year * 10000 + month * 100 + patch
            val versionName = "$year.$month.$patch"

            extensions.configure(ApplicationExtension::class.java) {
                defaultConfig {
                    this.versionCode = versionCode
                    this.versionName = versionName
                }

                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }

            tasks.register("printVersion") {
                group = "versioning"
                description = "Prints the computed CalVer version"
                doLast {
                    println("VERSION_CODE=$versionCode")
                    println("VERSION_NAME=$versionName")
                }
            }
        }
    }
}
