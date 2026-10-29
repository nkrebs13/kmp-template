plugins {
    id("convention.kmp.library")
    id("convention.compose")
}

kotlin {
    android {
        namespace = "com.template.shared"
        // Without this the KMP Android library does not package composeResources into the APK.
        androidResources { enable = true }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.ui)
            implementation(libs.compose.components.resources)
            implementation(libs.compose.ui.tooling.preview)
            implementation(libs.kotlinx.coroutines.core)
            api(libs.kermit)
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.compose.ui.test)
        }

        // region desktop
        // Desktop needs the Skiko runtime to host a headless Compose window in tests.
        jvmTest.dependencies {
            implementation(compose.desktop.currentOs)
        }
        // endregion desktop
    }
}

compose.resources {
    // Keep the generated Res class in a predictable package that setup.sh renames with the rest.
    packageOfResClass = "com.template.shared.generated.resources"
    publicResClass = false
}
