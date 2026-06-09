# ===================================================================
# قواعد ProGuard/R8 لتطبيق Privoo - الخصوصية المطلقة: بدون Analytics أو Crashlytics
# الإصدار: 2.0
# ===================================================================

# ========== 1. قواعد Flutter الأساسية ==========
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn java.lang.invoke.*
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**

# منع حذف أي منشئ أو طريقة تستخدمها Flutter عبر الانعكاس (Reflection)
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler <methods>;
    @io.flutter.plugin.common.EventChannel$StreamHandler <methods>;
}

-keep @interface androidx.annotation.Keep
-keep @interface io.flutter.plugin.common.MethodChannel$MethodCallHandler
-keep @interface io.flutter.plugin.common.EventChannel$StreamHandler

# ========== 2. Firebase (بدون Analytics أو Crashlytics) ==========
# الحفاظ على جميع كلاسات Firebase مع منع إزالة أي شيء
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }

# الحفاظ على خدمة FirebaseMessaging (ضروري للإشعارات الخلفية)
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class com.google.firebase.messaging.RemoteMessage { *; }
-keep class com.google.firebase.messaging.RemoteMessage$Notification { *; }

# تجنب التحذيرات لعدم استخدام Analytics/Crashlytics
-dontwarn com.google.firebase.analytics.**
-dontwarn com.google.firebase.crashlytics.**
-dontwarn com.google.firebase.crashlytics.**
-dontnote com.google.firebase.analytics.**
-dontnote com.google.firebase.crashlytics.**

# ========== 3. التشفير والأمان ==========
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-keep class java.security.** { *; }
-keep class java.security.spec.** { *; }
-dontwarn javax.crypto.**
-dontwarn java.security.**

# FlutterSecureStorage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.it_nomads.fluttersecurestorage.FlutterSecureStorage { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# الحفاظ على Serializable للمفاتيح والنماذج
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    private void readObjectNoData();
    private <init>(***);
}

# Encrypt library (PointyCastle)
-keep class org.pointycastle.** { *; }
-dontwarn org.pointycastle.**

# ========== 4. WebRTC + ميديا (صوت/فيديو) ==========
-keep class org.webrtc.** { *; }
-keep class org.webrtc.PeerConnectionFactory { *; }
-keep class org.webrtc.PeerConnection { *; }
-keep class org.webrtc.MediaStream { *; }
-keep class org.webrtc.VideoTrack { *; }
-keep class org.webrtc.AudioTrack { *; }
-keep class org.webrtc.DataChannel { *; }
-keep class org.webrtc.SdpObserver { *; }
-dontwarn org.webrtc.**

# JustAudio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.just_audio.**

# FlutterSound / Record
-keep class com.dooboolab.fluttersound.** { *; }
-keep class com.dooboolab.record.** { *; }
-dontwarn com.dooboolab.fluttersound.**
-dontwarn com.dooboolab.record.**

# VideoPlayer
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# ImagePicker + Camera
-keep class com.fluttercandies.** { *; }
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**
-keep class com.yalantis.ucrop** { *; }
-dontwarn com.yalantis.ucrop**

# TTS
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ========== 5. الأذونات والعناصر الجغرافية ==========
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.permissionhandler.**
-dontwarn com.baseflow.geolocator.**

# ========== 6. Gemini API (Generative AI) ==========
-keep class com.google.ai.generativeai.** { *; }
-dontwarn com.google.ai.generativeai.**

# ========== 7. مكتبات المساعدة والمتنوعات ==========
# Provider + Riverpod
-keep class **.provider.** { *; }
-keep class **.riverpod.** { *; }
-keep class **.flutter_riverpod.** { *; }

# Device & Package Info
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keep class dev.fluttercommunity.plus.package_info.** { *; }
-dontwarn dev.fluttercommunity.plus.**

# Logger
-keep class **.logger.** { *; }

# PathProvider
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# HTTP + Dio + Network
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.squareup.okhttp.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# SharedPreferences
-keep class android.content.SharedPreferences { *; }

# RestartApp
-keep class com.hanzo.** { *; }
-keep class **.restart_app.** { *; }

# URL Launcher
-keep class androidx.browser.** { *; }
-dontwarn androidx.browser.**

# ========== 8. JNI/Native Methods ==========
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== 9. قواعد إضافية لمنع حذف الـ Annotations و Reflection ==========
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile
-keepattributes LineNumberTable
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ========== 10. حماية الموارد ==========
-keepresources *.xml,*.json,*.properties,*.wav,*.ttf,*.jpeg,*.png,*.jpg

# ========== 11. إعدادات عامة ==========
-dontnote
-dontwarn
-ignorewarnings

# منع إزالة أي كلاس يستخدم عبر الـ Reflection بواسطة أي مكتبة
-keepclassmembers class * {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}