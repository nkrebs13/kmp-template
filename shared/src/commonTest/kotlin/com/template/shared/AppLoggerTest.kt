package com.template.shared

import co.touchlab.kermit.Severity
import kotlin.test.Test
import kotlin.test.assertEquals

/** Pins the app's own logging configuration; Kermit's behavior is Kermit's to test. */
class AppLoggerTest {

    @Test
    fun usesKmpTemplateTag() {
        assertEquals("KmpTemplate", AppLogger.tag)
    }

    @Test
    fun minimumSeverityIsInfo() {
        assertEquals(Severity.Info, AppLogger.config.minSeverity)
    }
}
