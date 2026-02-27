plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.jetbrainsCompose)
    alias(libs.plugins.androidx.baselineprofile)
    id("kmptemplate.android.app")
}

android {
    namespace = "com.template.android"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.template.android"
        minSdk = 24
        targetSdk = 36
        // versionCode and versionName set by kmptemplate.android.app convention plugin (CalVer)

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
            // Without a release signing config, the generated release APK is unsigned and
            // cannot be installed until it is signed. See:
            // https://developer.android.com/studio/publish/app-signing
        }
    }

    // compileOptions set by kmptemplate.android.app convention plugin

    buildFeatures {
        compose = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
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
