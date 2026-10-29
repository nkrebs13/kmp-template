package convention

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * A `print(`/`println(` call, bare or as `kotlin.io.println(`; `logger.println(` or `myprintln(`
 * do not match.
 */
private val FORBIDDEN_CALL = Regex("""(?<![\w.$])print(ln)?\s*\(|\bkotlin\.io\.print(ln)?\s*\(""")

/** A single-line string literal, so text such as `"avoid println("` is not mistaken for a call. */
private val STRING_LITERAL = Regex(""""(?:\\.|[^"\\])*"""")

/** The code part of a line: string literal contents and a trailing `//` comment removed. */
private fun codeOf(line: String): String = line.replace(STRING_LITERAL, "\"\"").substringBefore("//")

/**
 * Fails when production Kotlin sources call `print`/`println`: log through `AppLogger` instead.
 * detekt's `ForbiddenMethodCall` needs type resolution, which `check` does not run, so this
 * line-based check enforces the rule. Comment lines, trailing comments and single-line string
 * literals are skipped; a multi-line raw string mentioning `println(` would be a false positive.
 */
@CacheableTask
abstract class CheckForbiddenCallsTask : DefaultTask() {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val sources: ConfigurableFileCollection

    /** Empty marker file, so the task is up to date when no source changed. */
    @get:OutputFile
    abstract val marker: RegularFileProperty

    @TaskAction
    fun check() {
        val hits = sources.files.sorted().flatMap { file ->
            file.readLines().mapIndexedNotNull { index, line ->
                val code = line.trimStart()
                val isComment = code.startsWith("//") || code.startsWith("*") || code.startsWith("/*")
                if (!isComment &&
                    FORBIDDEN_CALL.containsMatchIn(codeOf(line))
                ) {
                    "${file.path}:${index + 1}: ${code.trim()}"
                } else {
                    null
                }
            }
        }
        if (hits.isNotEmpty()) {
            throw GradleException(
                "print/println in production code; log with AppLogger instead:\n" + hits.joinToString("\n"),
            )
        }
        marker.get().asFile.writeText("")
    }
}
