# Improvy — R8 keep rules.
#
# Flutter's Gradle plugin already adds proguard-android-optimize.txt and its
# own flutter_proguard_rules.pro, and every native library this app uses ships
# consumer rules inside its AAR (RevenueCat, PostHog, Firebase, Gson,
# WorkManager, Room, Play In-App Review). What is here is the handful of things
# those rules do not cover, each with the failure it prevents. Add to this file
# only against a failure you have seen; a package-wide keep is a cost on every
# build.

# ── WorkManager's Room database (comes in through home_widget → Glance) ──────
# Room finds the generated implementation of a database by NAME
# (WorkDatabase → WorkDatabase_Impl) and instantiates it by reflection through
# its no-argument constructor. Room's own consumer rule keeps the class but, in
# R8 full mode, not that constructor — so the app died at launch, in release
# only, before any Dart ran:
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keepnames class androidx.work.impl.WorkDatabase

# ── flutter_local_notifications ──────────────────────────────────────────────
# Scheduled reminders are written to SharedPreferences as JSON by Gson, keyed
# by FIELD NAME, and read back by the boot receiver. Obfuscated field names
# would make every pending reminder unreadable after a reboot, silently. The
# plugin's README asks for exactly this rule.
-keep class com.dexterous.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-dontwarn sun.misc.**

# ── Flutter plugin registration ──────────────────────────────────────────────
# The embedding reaches the generated registrant by reflection.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
