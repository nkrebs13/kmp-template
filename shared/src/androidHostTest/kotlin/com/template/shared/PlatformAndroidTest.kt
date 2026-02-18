package com.template.shared

import kotlin.test.Test
import kotlin.test.assertEquals

class PlatformAndroidTest {
    @Test
    fun platformNameIsExactlyAndroid() {
        assertEquals("Android", getPlatformName())
    }
}
