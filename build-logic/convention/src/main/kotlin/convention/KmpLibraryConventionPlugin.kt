package convention

import com.android.build.api.dsl.KotlinMultiplatformAndroidLibraryTarget
import kotlinx.kover.gradle.plugin.dsl.AggregationType
import kotlinx.kover.gradle.plugin.dsl.CoverageUnit
import kotlinx.kover.gradle.plugin.dsl.KoverProjectExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.gradle.dsl.KotlinMultiplatformExtension

/** Minimum line coverage `koverVerify` enforces on a shared library module. */
private const val MIN_LINE_COVERAGE_PERCENT = 60

/**
 * A Kotlin Multiplatform library for Android and iOS (device + Apple-silicon simulator).
 *
 * Each iOS target exports a static framework named after the module, with an explicit bundle ID
 * taken from the Android `namespace`. The module sets `kotlin { android { namespace = "…" } }`.
 */
class KmpLibraryConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("kotlin-multiplatform"))
        pluginManager.apply(libs.pluginId("android-kotlin-multiplatform-library"))
        apply<QualityConventionPlugin>()

        extensions.configure<KotlinMultiplatformExtension> {
            jvmToolchain(JDK_TOOLCHAIN_VERSION)
            configureAndroidTarget(this@with)
            configureIosTargets(this@with)
        }

        extensions.configure<KoverProjectExtension> {
            reports.verify.rule("Line coverage") {
                bound {
                    minValue.set(MIN_LINE_COVERAGE_PERCENT)
                    coverageUnits.set(CoverageUnit.LINE)
                    aggregationForGroup.set(AggregationType.COVERED_PERCENTAGE)
                }
            }
        }
    }

    private fun KotlinMultiplatformExtension.configureAndroidTarget(project: Project) {
        targets.withType<KotlinMultiplatformAndroidLibraryTarget>().configureEach {
            // Same values as configureAndroidCommon(); the KMP Android target has its own DSL type.
            compileSdk = project.libs.versionInt("android-compile-sdk")
            minSdk = project.libs.versionInt("android-min-sdk")
            compilerOptions.jvmTarget.set(KOTLIN_JVM_TARGET)
            withHostTest {}
        }
    }

    private fun KotlinMultiplatformExtension.configureIosTargets(project: Project) {
        val androidNamespace =
            project.provider {
                targets.withType<KotlinMultiplatformAndroidLibraryTarget>().single().namespace
                    ?: error("${project.path}: set kotlin { android { namespace = \"…\" } }")
            }
        listOf(iosArm64(), iosSimulatorArm64()).forEach { iosTarget ->
            iosTarget.binaries.framework {
                baseName = project.name
                isStatic = true
                linkTaskProvider.configure {
                    toolOptions.freeCompilerArgs.addAll(androidNamespace.map { listOf("-Xbinary=bundleId=$it") })
                }
            }
        }
    }
}
