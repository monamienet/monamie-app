# R8 rules for the release build. The Flutter Gradle plugin adds this file
# when it exists.

# package:jni 1.1 (used by shared_preferences_android 2.5 and
# path_provider_android 2.3 through Pigeon JNI) looks Kotlin classes, fields
# and methods up from Dart by their exact JVM names and signatures, but only
# ships keep rules for its own classes. Without these, R8 renames them and the
# first plugin call fails (NoSuchMethodError / ClassNotFoundException), so the
# app hangs on the splash screen. Names from jni's lib/src/kotlin.dart and the
# plugins' generated *.g.dart bindings. Upstream: flutter/flutter#194649 (fixed
# in shared_preferences_android 2.5.2) and dart-lang/native#3732; remove these
# once both ship their own consumer rules.
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
-keep class kotlin.enums.EnumEntries { *; }
