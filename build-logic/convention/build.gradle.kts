plugins {
    `kotlin-dsl`
}

dependencies {
    compileOnly(libs.android.gradlePlugin)
}

gradlePlugin {
    plugins {
        register("androidApp") {
            id = "kmptemplate.android.app"
            implementationClass = "AndroidAppConventionPlugin"
        }
    }
}
