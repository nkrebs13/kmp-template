package com.template.shared

import co.touchlab.kermit.Logger
import co.touchlab.kermit.Severity
import co.touchlab.kermit.StaticConfig
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppLoggerTest {

    @Test
    fun appLoggerUsesKmpTemplateTag() {
        assertEquals("KmpTemplate", AppLogger.tag)
    }

    @Test
    fun appLoggerAcceptsInfoAndAbove() {
        assertTrue(
            AppLogger.config.minSeverity <= Severity.Info,
            "Min severity should be Info or lower, got ${AppLogger.config.minSeverity}",
        )
    }

    @Test
    fun loggerDeliversMessagesToWriters() {
        val writer = CapturingLogWriter()
        val logger = Logger(
            config = StaticConfig(minSeverity = Severity.Debug, logWriterList = listOf(writer)),
            tag = "Test",
        )

        logger.i { "hello" }

        assertEquals(1, writer.entries.size, "Expected exactly one log entry")
        assertEquals("hello", writer.entries[0].message)
        assertEquals(Severity.Info, writer.entries[0].severity)
        assertEquals("Test", writer.entries[0].tag)
    }

    @Test
    fun loggerFiltersMessagesBelowMinSeverity() {
        val writer = CapturingLogWriter()
        val logger = Logger(
            config = StaticConfig(minSeverity = Severity.Warn, logWriterList = listOf(writer)),
            tag = "Test",
        )

        logger.v { "verbose" }
        logger.d { "debug" }
        logger.i { "info" }
        logger.w { "warn" }
        logger.e { "error" }

        val severities = writer.entries.map { it.severity }
        assertEquals(listOf(Severity.Warn, Severity.Error), severities)
    }

    @Test
    fun loggerPassesThrowableToWriter() {
        val writer = CapturingLogWriter()
        val logger = Logger(
            config = StaticConfig(minSeverity = Severity.Debug, logWriterList = listOf(writer)),
            tag = "Test",
        )
        val exception = RuntimeException("boom")

        logger.e(exception) { "failed" }

        assertEquals("failed", writer.entries[0].message)
        assertEquals(exception, writer.entries[0].throwable)
    }

    @Test
    fun loggerDispatchesToMultipleWriters() {
        val writerA = CapturingLogWriter()
        val writerB = CapturingLogWriter()
        val logger = Logger(
            config = StaticConfig(minSeverity = Severity.Debug, logWriterList = listOf(writerA, writerB)),
            tag = "Test",
        )

        logger.i { "broadcast" }

        assertEquals(1, writerA.entries.size)
        assertEquals(1, writerB.entries.size)
        assertEquals("broadcast", writerA.entries[0].message)
        assertEquals("broadcast", writerB.entries[0].message)
    }
}
