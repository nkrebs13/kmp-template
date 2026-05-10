package com.template.shared

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import org.jetbrains.compose.ui.tooling.preview.Preview

/**
 * Root Composable — renders a greeting with the current [getPlatformName].
 *
 * [windowSize] is the container size in dp, threaded in from the platform host
 * so downstream code can branch on form-factor (phone / foldable / tablet)
 * without retro-fitting the entry point. The skeleton does not use it yet.
 */
@Composable
@Preview
fun App(windowSize: DpSize) {
    MaterialTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background,
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = "Hello, ${getPlatformName()}!",
                    style = MaterialTheme.typography.headlineMedium,
                )
            }
        }
    }
}
