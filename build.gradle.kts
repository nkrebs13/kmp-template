// All configuration lives in the convention plugins under build-logic/: convention.root wires the
// root project (check, root-level formatting, verifyCatalog). `apply false` puts every plugin on
// one shared classpath without applying it here.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.android.kotlin.multiplatform.library) apply false
    alias(libs.plugins.kotlin.multiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.compose.multiplatform) apply false
    alias(libs.plugins.detekt) apply false
    alias(libs.plugins.kover) apply false
    alias(libs.plugins.spotless) apply false
    alias(libs.plugins.androidx.baselineprofile) apply false
    id("convention.root")
}
