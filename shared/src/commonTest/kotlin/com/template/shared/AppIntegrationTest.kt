package com.template.shared

import kotlin.test.Test

class AppIntegrationTest {
    @Test
    fun loggerEmitsPlatformSpecificMessageWithoutCrash() {
        val platformName = getPlatformName()
        // Verify cross-component interaction: logger + platform function work together
        AppLogger.i { "Running on $platformName" }
    }
}
