package com.template.shared

import androidx.compose.ui.window.ComposeUIViewController

/**
 * Factory for the root iOS view controller hosting Compose Multiplatform UI.
 *
 * Uses PascalCase naming to match the KMP convention for iOS entry-point factories
 * (mirrors UIKit's `UIViewController` naming, not Kotlin's typical camelCase).
 */
@Suppress("FunctionName")
fun MainViewController() = ComposeUIViewController { App() }
