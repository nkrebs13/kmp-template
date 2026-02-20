package com.template.shared

import co.touchlab.kermit.Logger
import co.touchlab.kermit.Severity
import co.touchlab.kermit.StaticConfig
import co.touchlab.kermit.platformLogWriter

/**
 * Application-wide logger backed by Kermit.
 *
 * Uses platform-native log writers (Logcat on Android, os_log on iOS).
 * Adjust [Severity] in the config for release builds.
 */
object AppLogger : Logger(
    config = StaticConfig(
        minSeverity = Severity.Info,
        logWriterList = listOf(platformLogWriter()),
    ),
    tag = "KmpTemplate",
)
