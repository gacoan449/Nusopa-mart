# Nusopa-mart / Firebase R8 rules
# Firebase libraries normally provide consumer rules themselves.
# Keep these compatibility rules while release minification is disabled.
-keep public class com.google.firebase.** { *; }
-keep public class com.google.android.gms.** { *; }
