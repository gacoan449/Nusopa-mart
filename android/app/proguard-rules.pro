# Nusopa-mart / Firebase R8 rules
# Keep Firebase Auth and Google Play Services from being removed or renamed by R8.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.auth.**
