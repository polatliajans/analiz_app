# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
# Flutter deferred components (Play Core is not used)
-dontwarn com.google.android.play.core.**

# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In (Credential Manager / Identity)
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn androidx.credentials.**

# in_app_purchase / Play Billing
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# flutter_local_notifications (Gson reflection on stored schedules)
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# web_socket_channel / http (OkHttp-free, but keep optional TLS providers quiet)
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep line numbers for crash reports
-keepattributes SourceFile, LineNumberTable
