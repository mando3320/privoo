// lib/controllers/app_controller.dart
// controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/subscription_service.dart';
import '../config/app_theme.dart';
import '../main.dart';

// 🔑 حالة التوكن
final userAuthTokenProvider = StateProvider<String>((ref) => 'UNINITIALIZED_AUTH_TOKEN');

// 🧠 الكنترولر الرئيسي
final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(ref);
});

class AppController extends ChangeNotifier {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 🌐 اللغة والثيم
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;
  
  // ✅ إضافة دعم الثيمات المتعددة
  String _themeName = 'Blue Light';
  ThemeData? _cachedTheme;

  // 👑 الاشتراك
  bool _isPro = false;
  bool _isLifetime = false;

  // 🔒 إعدادات الخصوصية
  bool _lockApp = false;
  bool _hideLastSeen = false;
  bool _hideOnlineStatus = false;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceipts = true;

  // 💬 إعدادات الدردشة
  String _chatWallpaper = "default";
  double _chatFontSize = 14.0;

  // ⚙️ توفير البيانات
  bool _dataSaverEnabled = false;

  // 📊 التقييد اليومي للمستخدم المجاني
  int _messagesToday = 0;
  String _lastMessageDate = "";
  int get dailyFreeLimit => 30;

  // 🔐 إعدادات الأمان (Privoo v2)
  String _myFingerprint = "";
  String _peerFingerprint = "";
  int _protocolVersion = 2;
  String _defaultAlgorithm = "AES-GCM-256";

  // ✅ المهمة 51: إعدادات المصادقة البيومترية
  bool _biometricEnabled = false;

  // =======================
  //       GETTERS
  // =======================
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

  AppController(this._ref) {
    _loadPreferences();
  }

  // ✅ دوال التخزين الآمن
  Future<void> _saveSecureBool(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }
  
  Future<bool> _loadSecureBool(String key, {bool defaultValue = false}) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  // =======================
  //   تحميل الإعدادات
  // =======================
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
      _locale = Locale(prefs.getString('language') ?? 'ar');
      
      // ✅ تحميل الثيم المختار مع التحقق من وجوده
      String savedTheme = prefs.getString('theme_name') ?? 'Blue Light';
      if (!AppTheme.isThemeAvailable(savedTheme, _isPro)) {
        savedTheme = 'Blue Light';
      }
      _themeName = AppTheme.allThemes.containsKey(savedTheme) ? savedTheme : 'Blue Light';
      
      _themeMode = (prefs.getBool('darkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
      
      _chatWallpaper = prefs.getString('chatWallpaper') ?? "default";
      _chatFontSize = prefs.getDouble('chatFontSize') ?? 14.0;
      _protocolVersion = prefs.getInt('protocolVersion') ?? 2;
      _defaultAlgorithm = prefs.getString('defaultAlgorithm') ?? "AES-GCM-256";
      _myFingerprint = prefs.getString('myFingerprint') ?? "";
      _peerFingerprint = prefs.getString('peerFingerprint') ?? "";

      await _loadMessageCount();

      notifyListeners();
      logger.d("✅ إعدادات التطبيق تم تحميلها بنجاح. الثيم الحالي: $_themeName (isPro: $_isPro)");

      final token = _ref.read(userAuthTokenProvider);
      if (token != 'UNINITIALIZED_AUTH_TOKEN') {
        await fetchAndVerifyUserStatus(token);
      }
    } catch (e) {
      logger.e("❌ خطأ أثناء تحميل الإعدادات: $e");
    }
  }

  // =======================
  //   عداد الرسائل اليومية
  // =======================
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

  // =======================
  //   الاشتراك / التحقق
  // =======================
  Future<void> fetchAndVerifyUserStatus(String token) async {
    logger.i("🔄 التحقق من حالة اشتراك المستخدم...");

    if (token == 'UNINITIALIZED_AUTH_TOKEN') {
      logger.w("⚠️ لا يمكن التحقق: رمز المصادقة غير جاهز.");
      return;
    }

    try {
      // ✅ استخدام SubscriptionService المعدل (بدون constructor)
      final status = await SubscriptionService.checkUserStatus();
      
      await _updateSubscriptionStatus(
        isPro: status['isPro'] ?? false,
        isLifetime: status['isLifetime'] ?? false,
      );
    } catch (e) {
      logger.e("❌ فشل التحقق من الاشتراك: $e");
    }
  }

  Future<void> _updateSubscriptionStatus({
    required bool isPro,
    required bool isLifetime,
  }) async {
    final wasPro = _isPro;
    _isPro = isPro;
    _isLifetime = isLifetime;

    await _saveSecureBool('isPro_cached', isPro);
    await _saveSecureBool('isLifetime_cached', isLifetime);

    if (wasPro && !isPro) {
      if (!AppTheme.isThemeAvailable(_themeName, false)) {
        _themeName = 'Blue Light';
        _cachedTheme = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme_name', _themeName);
        logger.w("⚠️ تم تغيير الثيم إلى الافتراضي لأن المستخدم أصبح مجانياً");
      }
    }

    notifyListeners();
    logger.d("🔐 تحديث الاشتراك: Pro=$isPro, Lifetime=$isLifetime");
  }

  Future<void> updateSubscriptionStatus({
    required bool isPro,
    required bool isLifetime,
  }) async {
    await _updateSubscriptionStatus(isPro: isPro, isLifetime: isLifetime);
  }

  // =======================
  //       الأمان
  // =======================
  Future<void> updateMyFingerprint(String fp) async {
    _myFingerprint = fp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myFingerprint', fp);
    notifyListeners();
    logger.d("🔐 بصمة المستخدم تم تحديثها.");
  }

  Future<void> updatePeerFingerprint(String fp) async {
    _peerFingerprint = fp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('peerFingerprint', fp);
    notifyListeners();
    logger.d("🔐 بصمة الطرف الآخر تم تحديثها.");
  }

  Future<void> setProtocolVersion(int v) async {
    _protocolVersion = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('protocolVersion', v);
    notifyListeners();
  }

  Future<void> setDefaultAlgorithm(String alg) async {
    _defaultAlgorithm = alg;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultAlgorithm', alg);
    notifyListeners();
  }

  Future<void> toggleBiometricLock(bool value) async {
    _biometricEnabled = value;
    await _saveSecureBool('biometricEnabled', value);
    notifyListeners();
    logger.d("🔐 المصادقة البيومترية: ${value ? 'مفعّلة' : 'معطلة'}");
  }

  // ============================================================
  // 🎨 إدارة الثيمات المتعددة
  // ============================================================
  
  Future<void> setTheme(String themeName) async {
    if (!AppTheme.isThemeAvailable(themeName, _isPro)) {
      logger.w("⚠️ محاولة تغيير ثيم غير متاح للمستخدم: $themeName (isPro: $_isPro)");
      return;
    }
    
    if (AppTheme.allThemes.containsKey(themeName)) {
      _themeName = themeName;
      _cachedTheme = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_name', themeName);
      notifyListeners();
      logger.d("🎨 تم تغيير الثيم إلى: $themeName");
    } else {
      logger.w("⚠️ محاولة تغيير ثيم غير موجود: $themeName");
    }
  }
  
  ThemeData getCurrentTheme() {
    _cachedTheme ??= AppTheme.getTheme(_themeName);
    return _cachedTheme!;
  }
  
  List<String> getAvailableThemes() {
    return AppTheme.getAvailableThemesForUser(_isPro);
  }
  
  int getLockedThemesCount() {
    return AppTheme.lockedThemesCount;
  }

  // =======================
  //    الإعدادات العامة
  // =======================
  Future<void> updateLanguage(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    notifyListeners();
  }

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

  // =======================
  //      أدوات الإدارة
  // =======================
  Future<void> clearCache() async {
    logger.i("🧹 جاري مسح كاش التطبيق...");
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final secureKeys = [
      'isPro_cached', 'isLifetime_cached', 'lockApp', 'hideLastSeen',
      'hideOnlineStatus', 'notificationsEnabled', 'vibrationEnabled',
      'readReceipts', 'dataSaverEnabled', 'biometricEnabled',
    ];
    
    final normalKeys = [
      'language', 'darkMode', 'theme_name', 'chatWallpaper', 'chatFontSize',
      'protocolVersion', 'defaultAlgorithm', 'myFingerprint', 'peerFingerprint',
    ];

    logger.i("♻️ إعادة ضبط جميع الإعدادات…");

    for (var key in secureKeys) {
      await _secureStorage.delete(key: key);
    }
    for (var key in normalKeys) {
      await prefs.remove(key);
    }

    _themeName = 'Blue Light';
    _cachedTheme = null;
    _themeMode = ThemeMode.system;
    _locale = const Locale('ar');

    await _loadPreferences();
    logger.i("✅ تمت إعادة ضبط الإعدادات بنجاح.");
  }
}
