// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_theme.dart';
import '../config/theme_engine.dart';
import '../main.dart';

final userAuthTokenProvider = StateProvider<String>((ref) => 'UNINITIALIZED_AUTH_TOKEN');

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(ref);
});

class AppController extends ChangeNotifier {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;
  String _themeName = 'Privoo Premium';

  bool _isPro = false;
  bool _isLifetime = false;

  bool _lockApp = false;
  bool _hideLastSeen = false;
  bool _hideOnlineStatus = false;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceipts = true;

  String _chatWallpaper = "default";
  double _chatFontSize = 14.0;
  bool _dataSaverEnabled = false;

  int _messagesToday = 0;
  String _lastMessageDate = "";
  int get dailyFreeLimit => 30;

  String _myFingerprint = "";
  String _peerFingerprint = "";
  int _protocolVersion = 2;
  String _defaultAlgorithm = "AES-GCM-256";
  bool _biometricEnabled = false;

  // ============================================================
  // ✅ Getters
  // ============================================================
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String get themeName => _themeName;
  bool get isPro => _isPro;
  bool get isLifetime => _isLifetime;
  bool get lockApp => _lockApp;
  bool get hideLastSeen => _hideLastSeen;
  bool get hideOnlineStatus => _hideOnlineStatus;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get readReceipts => _readReceipts;
  String get chatWallpaper => _chatWallpaper;
  double get chatFontSize => _chatFontSize;
  bool get dataSaverEnabled => _dataSaverEnabled;
  int get messagesToday => _messagesToday;
  bool get canSendMessage => (_isPro || _isLifetime) || (_messagesToday < dailyFreeLimit);
  String get myFingerprint => _myFingerprint;
  String get peerFingerprint => _peerFingerprint;
  int get protocolVersion => _protocolVersion;
  String get defaultAlgorithm => _defaultAlgorithm;
  bool get biometricEnabled => _biometricEnabled;

  // ✅ الحصول على الثيم الحالي مباشرة من ThemeEngine
  ThemeData get currentTheme {
    return ThemeEngine.getTheme(
      themeName: _themeName,
      themeMode: _themeMode,
    );
  }

  // ✅ التحقق من دعم الوضع الفاتح
  bool get supportsLightMode {
    return ThemeEngine.supportsLightMode(_themeName);
  }

  AppController(this._ref) {
    _loadPreferences();
  }

  // ============================================================
  // ✅ دوال التخزين المساعدة
  // ============================================================
  Future<void> _saveSecureBool(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<bool> _loadSecureBool(String key, {bool defaultValue = false}) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  // ============================================================
  // ✅ تحميل الإعدادات
  // ============================================================
  Future<void> _loadPreferences() async {
    try {
      _isPro = await _loadSecureBool('isPro_cached');
      _isLifetime = await _loadSecureBool('isLifetime_cached');
      _lockApp = await _loadSecureBool('lockApp');
      _hideLastSeen = await _loadSecureBool('hideLastSeen');
      _hideOnlineStatus = await _loadSecureBool('hideOnlineStatus');
      _notificationsEnabled = await _loadSecureBool('notificationsEnabled');
      _vibrationEnabled = await _loadSecureBool('vibrationEnabled');
      _readReceipts = await _loadSecureBool('readReceipts');
      _dataSaverEnabled = await _loadSecureBool('dataSaverEnabled');
      _biometricEnabled = await _loadSecureBool('biometricEnabled');

      final prefs = await SharedPreferences.getInstance();
      
      // ✅ تحميل اللغة
      final savedLanguage = prefs.getString('language');
      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
      }
      
      // ✅ تحميل اسم الثيم
      String savedTheme = prefs.getString('theme_name') ?? 'Privoo Premium';
      if (!ThemeEngine.getAvailableThemes(_isPro).contains(savedTheme)) {
        savedTheme = 'Privoo Premium';
      }
      _themeName = savedTheme;
      
      // ✅ تحميل الوضع (Light/Dark/System)
      final savedThemeMode = prefs.getString('theme_mode');
      if (savedThemeMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedThemeMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      
      _chatWallpaper = prefs.getString('chatWallpaper') ?? "default";
      _chatFontSize = prefs.getDouble('chatFontSize') ?? 14.0;
      _protocolVersion = prefs.getInt('protocolVersion') ?? 2;
      _defaultAlgorithm = prefs.getString('defaultAlgorithm') ?? "AES-GCM-256";
      _myFingerprint = prefs.getString('myFingerprint') ?? "";
      _peerFingerprint = prefs.getString('peerFingerprint') ?? "";

      await _loadMessageCount();
      notifyListeners();
      
      logger.d("✅ إعدادات التطبيق تم تحميلها بنجاح. الثيم: $_themeName, الوضع: $_themeMode, Pro: $_isPro");
    } catch (e) {
      logger.e("❌ خطأ أثناء تحميل الإعدادات: $e");
    }
  }

  // ============================================================
  // ✅ إدارة الرسائل اليومية
  // ============================================================
  Future<void> _loadMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    _lastMessageDate = prefs.getString('lastMessageDate') ?? '';

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) {
      _messagesToday = 0;
      _lastMessageDate = today;
      await prefs.setString('lastMessageDate', today);
      await prefs.setInt('messagesToday', 0);
    } else {
      _messagesToday = prefs.getInt('messagesToday') ?? 0;
    }
  }

  Future<void> incrementMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) {
      _messagesToday = 1;
      _lastMessageDate = today;
      await prefs.setString('lastMessageDate', today);
    } else {
      _messagesToday++;
    }

    await prefs.setInt('messagesToday', _messagesToday);
    notifyListeners();
  }

  // ============================================================
  // ✅ إدارة اللغة
  // ============================================================
  Future<void> updateLanguage(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    notifyListeners();
    
    logger.i('🌐 تم تغيير اللغة إلى: $langCode');
  }

  // ============================================================
  // ✅ إدارة الثيمات (محسنة)
  // ============================================================
  
  /// ✅ تبديل الوضع (Light/Dark/System)
  Future<void> toggleThemeMode() async {
    // ✅ التحقق من دعم الوضع الفاتح
    if (!supportsLightMode && _themeMode != ThemeMode.dark) {
      // ✅ إذا كان الثيم لا يدعم Light، ارجع إلى Dark
      _themeMode = ThemeMode.dark;
    } else {
      // ✅ التبديل بين Light و Dark
      switch (_themeMode) {
        case ThemeMode.dark:
          _themeMode = ThemeMode.light;
          break;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.system:
          _themeMode = ThemeMode.dark;
          break;
      }
    }
    
    await _saveThemeSettings();
    notifyListeners();
    logger.d("🎨 تم تغيير وضع الثيم إلى: $_themeMode");
  }

  /// ✅ دالة للتوافق مع الكود القديم (تستخدم في setting_screen)
  Future<void> toggleTheme(bool isDark) async {
    // ✅ التحقق من دعم الوضع الفاتح
    if (!supportsLightMode && !isDark) {
      // ✅ إذا كان الثيم لا يدعم Light، اجبره على Dark
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    await _saveThemeSettings();
    notifyListeners();
    logger.d("🎨 تم تغيير وضع الثيم إلى: ${isDark ? 'Dark' : 'Light'}");
  }

  /// ✅ تغيير الثيم
  Future<void> setTheme(String themeName) async {
    // ✅ التحقق من توفر الثيم للمستخدم
    final availableThemes = ThemeEngine.getAvailableThemes(_isPro);
    if (!availableThemes.contains(themeName)) {
      logger.w("⚠️ محاولة تغيير ثيم غير متاح للمستخدم: $themeName (isPro: $_isPro)");
      return;
    }
    
    _themeName = themeName;
    
    // ✅ إذا كان الثيم لا يدعم Light Mode، اجبره على Dark
    if (!ThemeEngine.supportsLightMode(themeName)) {
      _themeMode = ThemeMode.dark;
    }
    
    await _saveThemeSettings();
    notifyListeners();
    logger.d("🎨 تم تغيير الثيم إلى: $themeName");
  }

  /// ✅ حفظ إعدادات الثيم
  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_name', _themeName);
    await prefs.setString('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// ✅ الحصول على الثيم الحالي (بدون Cache)
  ThemeData getCurrentTheme() {
    return currentTheme;
  }

  /// ✅ قائمة الثيمات المتاحة للمستخدم
  List<String> getAvailableThemes() {
    return ThemeEngine.getAvailableThemes(_isPro);
  }

  /// ✅ عدد الثيمات المقفلة
  int getLockedThemesCount() {
    return ThemeEngine.getAvailableThemes(false).length - ThemeEngine.getAvailableThemes(true).length;
  }

  // ============================================================
  // ✅ إدارة الاشتراك
  // ============================================================
  Future<void> updateSubscriptionStatus({
    required bool isPro,
    required bool isLifetime,
  }) async {
    _isPro = isPro;
    _isLifetime = isLifetime;
    await _saveSecureBool('isPro_cached', isPro);
    await _saveSecureBool('isLifetime_cached', isLifetime);
    notifyListeners();
    
    logger.i('💎 تم تحديث حالة الاشتراك: Pro=$isPro, Lifetime=$isLifetime');
  }

  // ============================================================
  // ✅ إعدادات التطبيق
  // ============================================================
  Future<void> toggleLockApp(bool value) async {
    _lockApp = value;
    await _saveSecureBool('lockApp', value);
    notifyListeners();
  }

  Future<void> toggleHideLastSeen(bool value) async {
    _hideLastSeen = value;
    await _saveSecureBool('hideLastSeen', value);
    notifyListeners();
  }

  Future<void> toggleHideOnlineStatus(bool value) async {
    _hideOnlineStatus = value;
    await _saveSecureBool('hideOnlineStatus', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _saveSecureBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> toggleVibration(bool value) async {
    _vibrationEnabled = value;
    await _saveSecureBool('vibrationEnabled', value);
    notifyListeners();
  }

  Future<void> toggleReadReceipts(bool value) async {
    _readReceipts = value;
    await _saveSecureBool('readReceipts', value);
    notifyListeners();
  }

  Future<void> setChatWallpaper(String value) async {
    _chatWallpaper = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatWallpaper', value);
    notifyListeners();
  }

  Future<void> setChatFontSize(double value) async {
    _chatFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chatFontSize', value);
    notifyListeners();
  }

  Future<void> toggleDataSaver(bool value) async {
    _dataSaverEnabled = value;
    await _saveSecureBool('dataSaverEnabled', value);
    notifyListeners();
  }

  // ============================================================
  // ✅ إعدادات الأمان
  // ============================================================
  Future<void> setFingerprints(String myFingerprint, String peerFingerprint) async {
    _myFingerprint = myFingerprint;
    _peerFingerprint = peerFingerprint;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myFingerprint', myFingerprint);
    await prefs.setString('peerFingerprint', peerFingerprint);
    notifyListeners();
  }

  Future<void> toggleBiometric(bool value) async {
    _biometricEnabled = value;
    await _saveSecureBool('biometricEnabled', value);
    notifyListeners();
  }

  // ============================================================
  // ✅ أدوات مساعدة
  // ============================================================
  Future<void> clearCache() async {
    logger.i("🧹 جاري مسح كاش التطبيق...");
    notifyListeners();
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final secureKeys = [
      'isPro_cached', 'isLifetime_cached', 'lockApp', 'hideLastSeen',
      'hideOnlineStatus', 'notificationsEnabled', 'vibrationEnabled',
      'readReceipts', 'dataSaverEnabled', 'biometricEnabled',
    ];
    
    final normalKeys = [
      'language', 'theme_name', 'theme_mode', 'chatWallpaper', 'chatFontSize',
      'protocolVersion', 'defaultAlgorithm', 'myFingerprint', 'peerFingerprint',
    ];

    logger.i("♻️ إعادة ضبط جميع الإعدادات…");

    for (var key in secureKeys) {
      await _secureStorage.delete(key: key);
    }
    for (var key in normalKeys) {
      await prefs.remove(key);
    }

    // ✅ إعادة تعيين القيم الافتراضية
    _themeName = 'Privoo Premium';
    _themeMode = ThemeMode.dark;
    _locale = const Locale('ar');
    _isPro = false;
    _isLifetime = false;

    await _loadPreferences();
    logger.i("✅ تمت إعادة ضبط الإعدادات بنجاح.");
  }
}
