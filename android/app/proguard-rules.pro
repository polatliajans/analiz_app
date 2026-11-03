# R8 rules for release. Flutter embedding, Firebase, Play services, Play Billing,
# UMP, Credential Manager and url_launcher ship their own consumer rules, so no
# blanket keeps are needed here (broad keeps previously left ~87% of classes
# unobfuscated).

# Crash reports (Crashlytics de-obfuscates with the uploaded mapping)
-keepattributes SourceFile, LineNumberTable, Signature, *Annotation*, InnerClasses, EnclosingMethod
-renamesourcefileattribute SourceFile

# flutter_local_notifications: scheduled notification models are persisted with
# Gson (reflection on field names) and read back via TypeToken.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }

# Flutter deferred components reference Play Core, which this app does not use.
-dontwarn com.google.android.play.core.**
