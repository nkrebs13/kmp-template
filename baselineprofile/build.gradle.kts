import convention.JVM_BYTECODE_VERSION
import convention.KOTLIN_JVM_TARGET

plugins {
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.androidx.baselineprofile)
    id("convention.quality")
}

android {
    namespace = "com.template.baselineprofile"
    compileSdk =
        libs.versions.android.compileSdk
            .get()
            .toInt()

    defaultConfig {
        // minSdk 28: required by androidx.benchmark.macro (Macrobenchmark APIs are API 28+).
        minSdk = 28

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JVM_BYTECODE_VERSION
        targetCompatibility = JVM_BYTECODE_VERSION
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(KOTLIN_JVM_TARGET)
        }
    }
}

baselineProfile {
    // Uses connected devices for profile generation
}

dependencies {
    implementation(libs.androidx.benchmark.macro)
    implementation(libs.androidx.test.ext.junit)
    implementation(libs.androidx.test.espresso.core)
    implementation(libs.androidx.test.uiautomator)
}
