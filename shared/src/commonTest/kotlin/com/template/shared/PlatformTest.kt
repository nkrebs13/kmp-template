package com.template.shared

import kotlin.test.Test
import kotlin.test.assertTrue

class PlatformTest {
    @Test
    fun platformNameIsNotBlank() {
        val name = getPlatformName()
        assertTrue(name.isNotBlank(), "Platform name should not be blank")
    }

    @Test
    fun platformNameIsKnownPlatform() {
        val name = getPlatformName()
        assertTrue(
            name in listOf("Android", "iOS"),
            "Platform name should be 'Android' or 'iOS', got '$name'",
        )
    }
}
