import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidKotlinMultiplatformLibrary)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.jetbrainsCompose)
    alias(libs.plugins.kover)
}

kotlin {
    // Auto-wires intermediate source sets (appleMain, iosMain, nativeMain, …)
    // so the three iOS targets share iosMain without manual dependsOn() plumbing.
    applyDefaultHierarchyTemplate()

    androidLibrary {
        namespace = "com.template.shared"
        compileSdk = 36
        minSdk = 24

        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }

        withHostTest {}
    }

    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64(),
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "shared"
            isStatic = true
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material3)
            implementation(compose.ui)
            implementation(compose.components.resources)
            implementation(compose.components.uiToolingPreview)
            implementation(libs.kotlinx.coroutines.core)
            api(libs.kermit)
        }

        androidMain.dependencies {
            implementation(libs.kotlinx.coroutines.android)
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.coroutines.test)
        }
    }
}

// Compose compiler metrics + stability reports — gated behind a project property.
// Enable with: ./gradlew -Pkmp.composeCompilerReports=true :shared:compileDebugKotlinAndroid
// Reports land under shared/build/compose-reports/
composeCompiler {
    if (providers.gradleProperty("kmp.composeCompilerReports").orNull == "true") {
        val dir = layout.buildDirectory.dir("compose-reports")
        reportsDestination.set(dir)
        metricsDestination.set(dir)
    }
}

kover {
    reports {
        filters {
            excludes {
                androidGeneratedClasses()
                classes(
                    // Compose compiler-generated singletons (not testable via unit tests)
                    "*ComposableSingletons*",
                    // Compose Multiplatform generated resource collectors
                    "*.generated.resources.*",
                )
            }
        }

        verify {
            rule("Line coverage") {
                bound {
                    minValue.set(60)
                    coverageUnits = kotlinx.kover.gradle.plugin.dsl.CoverageUnit.LINE
                    aggregationForGroup = kotlinx.kover.gradle.plugin.dsl.AggregationType.COVERED_PERCENTAGE
                }
            }
        }
    }
}
