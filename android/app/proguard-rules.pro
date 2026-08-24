# 3ialna optimized evaluation build: retain only entry points that Flutter or
# Android resolves dynamically. R8 can otherwise remove unused application code
# and resources through the standard optimized Android rules.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class com.ialna.app.MainActivity { *; }

# Keep annotated JavaScript bridges should any installed plugin expose one.
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}

# Android restores Parcelable instances through this field by name.
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
