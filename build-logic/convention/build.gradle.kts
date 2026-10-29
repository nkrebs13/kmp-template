plugins {
    `kotlin-dsl`
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    // compileOnly: the root build puts these plugins on the classpath (`apply false`),
    // so the convention plugins only compile against them.
    compileOnly(libs.android.gradlePlugin)
    compileOnly(libs.kotlin.gradlePlugin)
    compileOnly(libs.compose.compiler.gradlePlugin)
    compileOnly(libs.compose.gradlePlugin)
    compileOnly(libs.detekt.gradlePlugin)
    compileOnly(libs.kover.gradlePlugin)
    compileOnly(libs.spotless.gradlePlugin)
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
