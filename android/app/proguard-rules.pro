# Add project specific ProGuard rules here.

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep all data classes (used for serialization)
-keep class com.wealthwise.android.data.** { *; }
-keep class com.wealthwise.android.domain.** { *; }

# Retrofit
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.wealthwise.android.**$$serializer { *; }
-keepclassmembers class com.wealthwise.android.** {
    *** Companion;
}
-keepclasseswithmembers class com.wealthwise.android.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ViewComponentManager$FragmentContextWrapper

# Compose
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# R8 optimizations
-allowaccessmodification
-repackageclasses
