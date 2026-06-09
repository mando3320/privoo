// services/hive_storage_service.dart (بديل)
import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HiveStorageService {
  static const String _settingsBox = 'settings';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyKey = 'hive_encryption_key';
  static HiveAesCipher? _cachedCipher;
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    final cipher = await _getOrCreateCipher();
    _cachedCipher = cipher;
    
    // ✅ التصحيح: استخدام cipher مباشرة
    await Hive.openBox(
      _settingsBox,
      encryptionCipher: cipher,
    );
  }
  
  static Future<HiveAesCipher> _getOrCreateCipher() async {
    String? keyBase64 = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (keyBase64 == null) {
      // توليد مفتاح جديد
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final cipher = HiveAesCipher(keyBytes);
      keyBase64 = base64Encode(keyBytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: keyBase64);
      return cipher;
    }
    
    return HiveAesCipher(base64Decode(keyBase64));
  }
  
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }
  
  static dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }
  
  static Future<void> clearSettings() async {
    final box = Hive.box(_settingsBox);
    await box.clear();
  }
}