# Prevent Gson / flutter_local_notifications type parameter stripping in release build (R8)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-keep class com.google.gson.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Also keep Flutter plugin classes
-keep class class.to.keep.** { *; }
