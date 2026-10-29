plugins {
    `kotlin-dsl`
}

kotlin {
    // Keep in sync with JDK_TOOLCHAIN_VERSION in ProjectExtensions.kt (this script cannot read it).
    jvmToolchain(21)
}

dependencies {
    // compileOnly: the root build puts these plugins on the classpath (`apply false`),
    // so the convention plugins only compile against them.
    compileOnly(libs.android.gradle.plugin)
    compileOnly(libs.kotlin.gradle.plugin)
    compileOnly(libs.compose.compiler.gradle.plugin)
    compileOnly(libs.compose.multiplatform.gradle.plugin)
    compileOnly(libs.detekt.gradle.plugin)
    compileOnly(libs.kover.gradle.plugin)
    compileOnly(libs.spotless.gradle.plugin)
}

tasks.validatePlugins {
    enableStricterValidation = true
    failOnWarning = true
}

gradlePlugin {
    plugins {
        register("kmpLibrary") {
            id = "convention.kmp.library"
            implementationClass = "convention.KmpLibraryConventionPlugin"
        }
        register("compose") {
            id = "convention.compose"
            implementationClass = "convention.ComposeConventionPlugin"
        }
        register("androidApplication") {
            id = "convention.android.application"
            implementationClass = "convention.AndroidApplicationConventionPlugin"
        }
        register("jvmApplication") {
            id = "convention.jvm.application"
            implementationClass = "convention.JvmApplicationConventionPlugin"
        }
        register("androidTest") {
            id = "convention.android.test"
            implementationClass = "convention.AndroidTestConventionPlugin"
        }
        register("quality") {
            id = "convention.quality"
            implementationClass = "convention.QualityConventionPlugin"
        }
        register("root") {
            id = "convention.root"
            implementationClass = "convention.RootConventionPlugin"
        }
    }
}
