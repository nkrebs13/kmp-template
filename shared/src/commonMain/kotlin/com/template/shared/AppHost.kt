package com.template.shared

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.DpSize

/**
 * Cross-platform Compose entry point.
 *
 * Derives the window container size in dp from Compose's [LocalWindowInfo] (the recommended
 * API across Android and iOS — see Jetpack Compose's `ConfigurationScreenWidthHeight` lint
 * rule) and threads it into [App]. Platform hosts (`MainActivity` on Android,
 * `MainViewController` on iOS) just call `AppHost()` — they don't compute size themselves.
 */
@Composable
fun AppHost() {
    val sizePx = LocalWindowInfo.current.containerSize
    val sizeDp = with(LocalDensity.current) {
        DpSize(sizePx.width.toDp(), sizePx.height.toDp())
    }
    App(windowSize = sizeDp)
}
