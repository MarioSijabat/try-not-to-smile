# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# TFLite Flutter
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# General
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
