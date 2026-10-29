package com.template.shared

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.waitUntilExactlyOneExists

/**
 * Shared body of the `App()` UI test. It lives in commonTest so jvmTest and iosTest run the same
 * assertions, but it carries no `@Test`: the android host test has no Compose UI test runtime
 * (that needs Robolectric), so a `@Test` here would fail there. Each platform's test class calls
 * [assertGreetingIsDisplayed].
 */
@OptIn(ExperimentalTestApi::class)
internal fun assertGreetingIsDisplayed() = runComposeUiTest {
    setContent { App() }

    val greeting = "Hello, ${getPlatformName()}!"
    // Resources load asynchronously, so wait for the text instead of asserting immediately.
    // Resources load asynchronously; allow for a cold simulator or a busy CI runner.
    waitUntilExactlyOneExists(hasText(greeting), timeoutMillis = 5_000)
    onNodeWithText(greeting).assertIsDisplayed()
}
