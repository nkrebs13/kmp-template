plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.jetbrainsCompose)
    alias(libs.plugins.androidx.baselineprofile)
}

// --- Release Signing (uncomment all three sections below together) ---
// Step 1: Populate local.properties with signing.* keys (see README.md → Release Signing).
// val releaseKeystore = java.util.Properties().apply {
//     val f = rootProject.file("local.properties")
//     if (f.exists()) load(f.inputStream())
// }

android {
    namespace = "com.template.android"
    compileSdk = 36

    // // Step 2: Uncomment signingConfigs block
    // signingConfigs {
    //     create("release") {
    //         storeFile = releaseKeystore.getProperty("signing.storeFile")?.let { file(it) }
    //         storePassword = releaseKeystore.getProperty("signing.storePassword")
    //         keyAlias = releaseKeystore.getProperty("signing.keyAlias")
    //         keyPassword = releaseKeystore.getProperty("signing.keyPassword")
    //     }
    // }

    defaultConfig {
        applicationId = "com.template.android"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }

        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // signingConfig = signingConfigs.getByName("release") // Step 3
        }
    }

    // compileOptions sets Java target; kotlin.compilerOptions sets Kotlin target.
    // Both are required on AGP 9.x — JVM toolchain alone doesn't propagate to AGP's
    // Java compile task, and a mismatch fails compileDebugKotlin.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        compose = true
    }

    lint {
        warningsAsErrors = true
        abortOnError = true
        checkDependencies = false
        htmlReport = true
        xmlReport = true
        checkReleaseBuilds = true
        // Version-upgrade notices are informational, not bugs
        disable += setOf("AndroidGradlePluginVersion", "GradleDependency", "NewerVersionAvailable", "OldTargetApi")
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    // Disable language split so per-app locale APIs (LocaleManager / @xml/locales_config)
    // work correctly with App Bundles.
    bundle {
        language {
            enableSplit = false
        }
    }
}

dependencies {
    implementation(projects.shared)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.splashscreen)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.appcompat)

    // UI Tooling for Compose previews - using version from shared module's Compose plugin
    implementation(compose.components.uiToolingPreview)
    debugImplementation(compose.uiTooling)

    "baselineProfile"(project(":baselineprofile"))
    implementation(libs.androidx.profileinstaller)
}

baselineProfile {
    dexLayoutOptimization = true
}
