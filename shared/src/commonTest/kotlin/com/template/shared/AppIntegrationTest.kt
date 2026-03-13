package com.template.shared

import co.touchlab.kermit.Logger
import co.touchlab.kermit.Severity
import co.touchlab.kermit.StaticConfig
import kotlin.test.Test
import kotlin.test.assertTrue

class AppIntegrationTest {

    @Test
    fun loggerCanInterpolatePlatformName() {
        val writer = CapturingLogWriter()
        val logger = Logger(
            config = StaticConfig(minSeverity = Severity.Debug, logWriterList = listOf(writer)),
            tag = "Integration",
        )

        val platformName = getPlatformName()
        logger.i { "Running on $platformName" }

        assertTrue(writer.entries.isNotEmpty(), "Logger should have captured at least one message")
        assertTrue(
            writer.entries[0].message.contains(platformName),
            "Log message should contain platform name '$platformName', got '${writer.entries[0].message}'",
        )
    }
}
