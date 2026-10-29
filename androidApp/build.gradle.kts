plugins {
    id("convention.android.application")
    id("convention.compose")
    alias(libs.plugins.androidx.baselineprofile)
}

android {
    namespace = "com.template.android"

    defaultConfig {
        applicationId = "com.template.android"
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
        }
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

    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)

    "baselineProfile"(project(":baselineprofile"))
    implementation(libs.androidx.profileinstaller)

    constraints {
        // androidx.lifecycle is an atomic group, so this aligns every lifecycle artifact.
        implementation(libs.androidx.lifecycle.runtime) {
            because("lifecycle 2.9.x lint checks use an API removed in lint 9.5 (ObsoleteLintCustomCheck)")
        }
    }
}

baselineProfile {
    dexLayoutOptimization = true
}
