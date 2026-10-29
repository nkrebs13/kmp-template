package com.template.desktop

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.template.shared.App

/** Window title fallback for runs that do not go through the `compose.desktop.application` task. */
private const val DEFAULT_TITLE = "KMP Template"

/** `app.displayName` from `gradle.properties`, handed over as a JVM system property by the build. */
private val windowTitle: String = System.getProperty("app.displayName") ?: DEFAULT_TITLE

fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = windowTitle) {
        App()
    }
}
