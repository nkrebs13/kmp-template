package com.template.shared

import co.touchlab.kermit.Severity
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppLoggerTest {
    @Test
    fun loggerTagIsKmpTemplate() {
        assertEquals("KmpTemplate", AppLogger.tag, "Logger tag should be 'KmpTemplate'")
    }

    @Test
    fun loggerMinSeverityIsAtMostInfo() {
        assertTrue(
            AppLogger.config.minSeverity <= Severity.Info,
            "Logger min severity should be Info or lower, got ${AppLogger.config.minSeverity}",
        )
    }

    @Test
    fun loggerHasLogWriters() {
        assertTrue(
            AppLogger.config.logWriterList.isNotEmpty(),
            "Logger should have at least one log writer configured",
        )
    }

    @Test
    fun loggerCanLogWithoutCrash() {
        AppLogger.i { "Test info message" }
        AppLogger.d { "Test debug message" }
        AppLogger.w { "Test warning message" }
    }
}
