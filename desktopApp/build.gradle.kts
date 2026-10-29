plugins {
    id("convention.jvm.application")
}

dependencies {
    implementation(projects.shared)
    implementation(compose.desktop.currentOs)
}

compose.desktop {
    application {
        mainClass = "com.template.desktop.MainKt"
    }
}
