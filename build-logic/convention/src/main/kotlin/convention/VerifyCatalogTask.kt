package convention

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.provider.ListProperty
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import java.io.IOException
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

private val REQUEST_TIMEOUT: Duration = Duration.ofSeconds(10)
private const val ATTEMPTS = 2
private const val PARALLEL_REQUESTS = 8
private const val HTTP_OK = 200
private const val HTTP_NOT_FOUND = 404

/**
 * Fails when a catalog coordinate is not published, naming the alias, so a typo or a version
 * that never shipped cannot sit unnoticed in an entry nothing references.
 *
 * Each entry's POM is requested (HTTP HEAD) from [repositories] at execution time, every run: the
 * task never reads a stored result, so a configuration-cache hit still asks the repositories. A
 * POM exists for every published module (JVM, Android, iOS-only klibs) and for plugin markers.
 */
@DisableCachingByDefault(because = "Asks remote repositories; there is no file output to cache")
abstract class VerifyCatalogTask : DefaultTask() {
    /** `libs.<alias> -> group:name:version`. */
    @get:Input
    abstract val entries: ListProperty<String>

    /** Maven repository base URLs, tried in order. */
    @get:Input
    abstract val repositories: ListProperty<String>

    init {
        outputs.upToDateWhen { false }
    }

    @TaskAction
    fun verify() {
        val repos = repositories.get()
        val client = HttpClient.newBuilder()
            .connectTimeout(REQUEST_TIMEOUT)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build()
        val executor = Executors.newFixedThreadPool(PARALLEL_REQUESTS)
        val results = try {
            entries.get()
                .map { entry ->
                    val (alias, coordinate) = entry.split(" -> ", limit = 2)
                    executor.submit<Pair<String, Lookup>> {
                        "$alias -> $coordinate" to lookup(client, repos, coordinate)
                    }
                }.map { it.get() }
        } finally {
            executor.shutdown()
            executor.awaitTermination(1, TimeUnit.MINUTES)
        }

        val missing = results.filter { it.second is Lookup.Missing }.map { it.first }.sorted()
        val unreachable = results.mapNotNull { (it.second as? Lookup.Unreachable)?.reason }.toSortedSet()
        val unverified = results.filter { it.second is Lookup.Unreachable }.map { it.first }.sorted()
        if (missing.isEmpty() && unreachable.isEmpty()) {
            logger.lifecycle(
                "All ${results.size} version catalog coordinates resolve (checked ${repos.size} repositories).",
            )
            return
        }
        throw GradleException(
            buildString {
                if (missing.isNotEmpty()) {
                    appendLine("${missing.size} of ${results.size} version catalog entries do not resolve:")
                    missing.forEach { appendLine("  $it") }
                    appendLine("Fix the coordinate or version in gradle/libs.versions.toml.")
                }
                if (unreachable.isNotEmpty()) {
                    appendLine("${unverified.size} entries could not be checked:")
                    unreachable.forEach { appendLine("  could not reach $it") }
                    unverified.forEach { appendLine("  unverified: $it") }
                    append("This is a network problem, not a catalog error. Re-run when the repository is reachable.")
                }
            }.trimEnd(),
        )
    }

    private fun lookup(client: HttpClient, repos: List<String>, coordinate: String): Lookup {
        val (group, name, version) = coordinate.split(':')
        val path = "${group.replace('.', '/')}/$name/$version/$name-$version.pom"
        var unreachable: String? = null
        for (repo in repos) {
            when (val response = head(client, URI.create("$repo/$path"))) {
                is Response.Status -> when (response.code) {
                    HTTP_OK -> return Lookup.Found
                    HTTP_NOT_FOUND -> Unit
                    else -> unreachable = unreachable ?: "$repo (HTTP ${response.code})"
                }

                is Response.Failed -> unreachable = unreachable ?: "$repo (${response.reason})"
            }
        }
        return unreachable?.let(Lookup::Unreachable) ?: Lookup.Missing
    }

    /** One HEAD request, retried once on a network error or an unexpected status. */
    private fun head(client: HttpClient, uri: URI): Response {
        val request = HttpRequest.newBuilder(uri)
            .method("HEAD", HttpRequest.BodyPublishers.noBody())
            .timeout(REQUEST_TIMEOUT)
            .build()
        var last: Response = Response.Failed("no response")
        repeat(ATTEMPTS) {
            val response = try {
                Response.Status(client.send(request, HttpResponse.BodyHandlers.discarding()).statusCode())
            } catch (e: IOException) {
                Response.Failed(e::class.simpleName + (e.message?.let { ": $it" } ?: ""))
            }
            logger.info("verifyCatalog: HEAD {} -> {}", uri, response)
            if (response is Response.Status && response.code in setOf(HTTP_OK, HTTP_NOT_FOUND)) return response
            last = response
        }
        return last
    }

    private sealed interface Response {
        data class Status(val code: Int) : Response

        data class Failed(val reason: String) : Response
    }

    private sealed interface Lookup {
        data object Found : Lookup

        data object Missing : Lookup

        data class Unreachable(val reason: String) : Lookup
    }
}
