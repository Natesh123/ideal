# ============================================================
# ProGuard / R8 rules for Flutter – Ideal Traders
# ============================================================

# ── Flutter core ─────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ── Firebase ─────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Facebook SDK ──────────────────────────────────────────────
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# ── PhonePe SDK ──────────────────────────────────────────────
-keep class com.phonepe.** { *; }
-dontwarn com.phonepe.**

# ── Google Maps ──────────────────────────────────────────────
-keep class com.google.maps.** { *; }
-dontwarn com.google.maps.**

# ── WorkManager / AndroidX ───────────────────────────────────
-keep class androidx.work.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.**

# ── Kotlin / Coroutines ──────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ── JSON / Gson ──────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep generic type information
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── OkHttp / Retrofit ────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Crash reporting / stack traces ───────────────────────────
# Preserve line numbers and source file names for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ── App-specific classes ─────────────────────────────────────
-keep class co.idealtraders.** { *; }
-keep class com.active_ecommerce_cms_demo_app.** { *; }
-keep class **.data_model.** { *; }
-keep class **.models.** { *; }
-keep class com.shared_value.** { *; }
-keep class com.store_box.** { *; }

