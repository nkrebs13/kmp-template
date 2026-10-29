package com.template.shared

import kotlin.test.Test
import kotlin.test.assertEquals

class PlatformJvmTest {
    @Test
    fun platformNameIsExactlyDesktop() {
        assertEquals("Desktop", getPlatformName())
    }
}
