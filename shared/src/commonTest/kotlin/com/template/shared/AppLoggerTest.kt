package com.template.shared

import co.touchlab.kermit.Logger
import co.touchlab.kermit.Severity
import co.touchlab.kermit.StaticConfig
import kotlin.test.Test
import kotlin.test.assertEquals

/** Pins the template's own logging configuration; Kermit's behavior is Kermit's to test. */
class AppLoggerTest {

    @Test
    fun usesKmpTemplateTag() {
        assertEquals("KmpTemplate", AppLogger.tag)
    }

    @Test
    fun minimumSeverityIsInfo() {
        assertEquals(Severity.Info, AppLogger.config.minSeverity)
    }

    @Test
    fun dropsMessagesBelowMinimumSeverity() {
        val writer = CapturingLogWriter()
        // AppLogger's real writer is the platform log, which a test cannot read, so apply
        // AppLogger's severity and tag to a capturing writer.
        val logger = Logger(
            config = StaticConfig(minSeverity = AppLogger.config.minSeverity, logWriterList = listOf(writer)),
            tag = AppLogger.tag,
        )

        logger.v { "verbose" }
        logger.d { "debug" }
        logger.i { "info" }

        assertEquals(listOf("info"), writer.entries.map { it.message })
    }
}
