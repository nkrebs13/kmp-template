package com.template.shared

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.waitUntilExactlyOneExists

/**
 * Shared body of the `App()` UI test, so every platform with a Compose UI test runtime runs the same
 * assertions. It carries no `@Test`: the android host test has no Compose UI test runtime (that
 * needs Robolectric), so a `@Test` here would fail there. Each platform's test class calls
 * [assertGreetingIsDisplayed].
 */
@OptIn(ExperimentalTestApi::class)
internal fun assertGreetingIsDisplayed() = runComposeUiTest {
    setContent { App() }

    val greeting = "Hello, ${getPlatformName()}!"
    // Resources load asynchronously, so wait for the text instead of asserting immediately; the
    // timeout allows for a cold simulator or a busy CI runner.
    waitUntilExactlyOneExists(hasText(greeting), timeoutMillis = 5_000)
    onNodeWithText(greeting).assertIsDisplayed()
}
