# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
-renamesourcefileattribute SourceFile

# Kotlin
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Kotlinx Serialization (kept for template users who add serialization from the
# version catalog — ProGuard silently ignores rules for absent classes)
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.template.**$$serializer { *; }
-keepclassmembers class com.template.** {
    *** Companion;
}
-keepclasseswithmembers class com.template.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.atomicfu.**

# Kermit logging — keep Logger subclass names for readable crash reports
-keepnames class co.touchlab.kermit.**
-dontwarn co.touchlab.kermit.**