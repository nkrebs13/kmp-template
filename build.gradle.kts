plugins {
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.androidLibrary) apply false
    alias(libs.plugins.androidKotlinMultiplatformLibrary) apply false
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.jetbrainsCompose) apply false
    alias(libs.plugins.detekt)
    alias(libs.plugins.spotless)
    alias(libs.plugins.androidx.baselineprofile) apply false
}

subprojects {
    apply(plugin = "com.diffplug.spotless")
    configure<com.diffplug.gradle.spotless.SpotlessExtension> {
        kotlin {
            target("**/*.kt")
            targetExclude("**/build/**/*.kt", "**/.*")
            ktlint("1.8.0")
                .editorConfigOverride(
                    mapOf(
                        // Google & Kotlin style guide settings
                        "indent_size" to "4",
                        "continuation_indent_size" to "4",
                        "max_line_length" to "120",
                        
                        // Trailing commas (Kotlin best practice)
                        "ij_kotlin_allow_trailing_comma" to "true",
                        "ij_kotlin_allow_trailing_comma_on_call_site" to "true",
                        
                        // Import organization
                        "ij_kotlin_packages_to_use_import_on_demand" to "java.util.*,kotlinx.android.synthetic.**",
                        "ij_kotlin_imports_layout" to "*,java.**,javax.**,kotlin.**,^",
                        
                        // Wrapping
                        "ij_kotlin_parameter_annotation_wrap" to "off",
                        "ij_kotlin_variable_annotation_wrap" to "off",
                        
                        // Spacing
                        "ij_kotlin_space_before_type_colon" to "false",
                        "ij_kotlin_space_after_type_colon" to "true",
                        "ij_kotlin_space_before_extend_colon" to "true",
                        "ij_kotlin_space_after_extend_colon" to "true",
                        
                        // Disable rules that conflict with Android/Google style or common patterns
                        "ktlint_standard_no-wildcard-imports" to "disabled",
                        "ktlint_function_naming_ignore_when_annotated_with" to "Composable",
                        "disabled_rules" to "package-name,filename,import-ordering"
                    )
                )
        }
        
        kotlinGradle {
            target("**/*.gradle.kts")
            targetExclude("**/build/**/*.gradle.kts", "**/.*")
            ktlint("1.8.0")
        }
        
        format("xml") {
            target("**/*.xml")
            targetExclude("**/build/**/*.xml", "**/.*")
            eclipseWtp(com.diffplug.spotless.extra.wtp.EclipseWtpFormatterStep.XML)
        }
        
        format("misc") {
            target("**/*.md", "**/.gitignore", "**/*.yaml", "**/*.yml")
            targetExclude("**/build/**", "**/.*/**")
            trimTrailingWhitespace()
            endWithNewline()
        }
    }
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom("$projectDir/detekt-config.yml")
    parallel = true
    autoCorrect = true
    source.setFrom(
        "androidApp/src",
        "shared/src",
    )
}

