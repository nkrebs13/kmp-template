package com.template.shared

import kotlin.test.Test
import kotlin.test.assertTrue

class PlatformTest {

    /** The `expect` contract: every actual returns a non-blank alphanumeric name. */
    @Test
    fun platformNameIsNonBlankAlphanumeric() {
        val name = getPlatformName()
        assertTrue(name.isNotEmpty() && name.all { it.isLetterOrDigit() }, "Got '$name'")
    }
}
