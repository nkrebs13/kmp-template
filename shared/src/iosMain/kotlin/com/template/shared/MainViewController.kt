package com.template.shared

import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.window.ComposeUIViewController

@Suppress("FunctionName")
fun MainViewController() = ComposeUIViewController {
    LaunchedEffect(Unit) {
        AppLogger.d { "MainViewController created" }
    }
    App()
}
