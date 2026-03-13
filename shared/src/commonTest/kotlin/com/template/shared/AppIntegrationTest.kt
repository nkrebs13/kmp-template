package com.template.shared

import co.touchlab.kermit.LogWriter
import co.touchlab.kermit.Logger
import co.touchlab.kermit.Severity
import co.touchlab.kermit.StaticConfig
import kotlin.test.Test
import kotlin.test.assertTrue

class AppIntegrationTest {

    @Test
    fun loggerCanInterpolatePlatformName() {
        val captured = mutableListOf<String>()
        val logger = Logger(
            config = StaticConfig(
                minSeverity = Severity.Debug,
                logWriterList = listOf(
                    object : LogWriter() {
                        override fun log(severity: Severity, message: String, tag: String, throwable: Throwable?) {
                            captured.add(message)
                        }
                    },
                ),
            ),
            tag = "Integration",
        )

        val platformName = getPlatformName()
        logger.i { "Running on $platformName" }

        assertTrue(captured.isNotEmpty(), "Logger should have captured at least one message")
        assertTrue(
            captured[0].contains(platformName),
            "Log message should contain platform name '$platformName', got '${captured[0]}'",
        )
    }

    @Test
    fun platformNameAndLoggerTagAreIndependent() {
        val platformName = getPlatformName()
        assertTrue(
            platformName != AppLogger.tag,
            "Platform name ('$platformName') and logger tag ('${AppLogger.tag}') should differ",
        )
    }
}
