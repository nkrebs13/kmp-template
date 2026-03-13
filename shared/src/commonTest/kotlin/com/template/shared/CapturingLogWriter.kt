package com.template.shared

import co.touchlab.kermit.LogWriter
import co.touchlab.kermit.Severity

/** Captures log entries for assertion in tests. */
internal class CapturingLogWriter : LogWriter() {
    data class Entry(val severity: Severity, val message: String, val tag: String, val throwable: Throwable?)
    val entries = mutableListOf<Entry>()

    override fun log(severity: Severity, message: String, tag: String, throwable: Throwable?) {
        entries.add(Entry(severity, message, tag, throwable))
    }
}
