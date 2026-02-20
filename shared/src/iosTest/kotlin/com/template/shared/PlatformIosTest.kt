package com.template.shared

import kotlin.test.Test
import kotlin.test.assertEquals

class PlatformIosTest {
    @Test
    fun platformNameIsExactlyIos() {
        assertEquals("iOS", getPlatformName())
    }
}
