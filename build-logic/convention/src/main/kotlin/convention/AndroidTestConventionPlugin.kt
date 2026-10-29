package convention

import com.android.build.api.dsl.TestExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure

/**
 * An Android test module (`com.android.test`), such as the baseline profile producer: the same compile SDK,
 * bytecode level, toolchain and lint settings as the app (see `AndroidCommon.kt`).
 */
class AndroidTestConventionPlugin : Plugin<Project> {
    override fun apply(target: Project): Unit = with(target) {
        pluginManager.apply(libs.pluginId("android-test"))
        apply<QualityConventionPlugin>()

        extensions.configure<TestExtension> {
            configureAndroidCommon(this)
        }
    }
}
