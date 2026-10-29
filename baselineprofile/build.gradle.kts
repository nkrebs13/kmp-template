plugins {
    id("convention.android.test")
    alias(libs.plugins.androidx.baselineprofile)
}

android {
    namespace = "com.template.baselineprofile"

    defaultConfig {
        // minSdk 28: required by androidx.benchmark.macro (Macrobenchmark APIs are API 28+).
        minSdk = 28
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    targetProjectPath = ":androidApp"

    // The producer runs as its own instrumentation, which the baseline profile plugin needs.
    experimentalProperties["android.experimental.self-instrumenting"] = true

    // Gradle Managed Device: `./gradlew :androidApp:generateBaselineProfile` boots it by itself.
    testOptions.managedDevices.localDevices.create("pixel6Api34") {
        device = "Pixel 6"
        apiLevel = 34
        systemImageSource = "aosp"
    }
}

baselineProfile {
    managedDevices += "pixel6Api34"
    useConnectedDevices = false
}

dependencies {
    implementation(libs.androidx.benchmark.macro)
    implementation(libs.androidx.test.ext.junit)
    implementation(libs.androidx.test.espresso.core)
    implementation(libs.androidx.test.uiautomator)
}
