package com.template.desktop

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.template.shared.App

fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "KMP Template") {
        App()
    }
}
