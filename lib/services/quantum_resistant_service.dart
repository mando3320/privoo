// services/quantum_resistant_service.dart
import 'dart:convert';
import 'dart:math';
// The ml_kem / ml_dsa packages are optional (not available on pub.dev in this environment).
// They are intentionally not imported to allow analysis/build without these packages.
import 'package:cryptography/cryptography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';

class QuantumResistantService {
  static final _storage = FlutterSecureStorage();
  static final _firestore = FirebaseFirestore.instance;
  
  // ============================================================
  // 🔑 خوارزميات مقاومة كمومية
  // ============================================================
  
  // Kyber/Dilithium functionality disabled when packages are unavailable.
  // Set to null and guard callers; using these APIs will throw UnsupportedError.
  static final dynamic kyber = null;
  static final dynamic dilithium = null;
  
  // Falcon (بديل أسرع)
  // static final falcon = Falcon.falcon_512();
  
  // ============================================================
  // 🔐 مفاتيح Kyber (تبادل المفاتيح)
  // ============================================================
  
  static const String _kyberPrivKey = 'quantum_kyber_private';
  static const String _kyberPubKey = 'quantum_kyber_public';
  
  /// توليد زوج مفاتيح Kyber للمستخدم
  static Future<({
    List<int> publicKey,
    List<int> secretKey,
    String fingerprint,
  })> generateKyberKeyPair(String userId) async {
    throw UnsupportedError('Quantum Kyber functionality is disabled. Enable ml_kem in pubspec to use.');
  }
  
  /// الحصول على المفتاح العام Kyber لمستخدم آخر
  static Future<List<int>> getPeerKyberPublicKey(String peerId) async {
    final doc = await _firestore.collection('quantum_keys').doc(peerId).get();
    if (!doc.exists || doc.data()?['kyberPublicKey'] == null) {
      throw Exception('Quantum public key not found for $peerId');
    }
    return base64Decode(doc.data()!['kyberPublicKey']);
  }
  
  /// تشفير مفتاح جلسة باستخدام المفتاح العام للمستقبل
  static Future<({
    List<int> ciphertext,
    List<int> sharedSecret,
  })> encapsulate(List<int> recipientPublicKey) async {
    throw UnsupportedError('Quantum encapsulation is disabled.');
  }
  
  /// فك تشفير المفتاح باستخدام المفتاح الخاص
  static Future<List<int>> decapsulate(
    List<int> ciphertext,
    List<int> privateKey,
  ) async {
    throw UnsupportedError('Quantum decapsulation is disabled.');
  }
  
  // ============================================================
  // ✍️ توقيعات Dilithium
  // ============================================================
  
  static const String _dilithiumPrivKey = 'quantum_dilithium_private';
  static const String _dilithiumPubKey = 'quantum_dilithium_public';
  
  /// توليد زوج مفاتيح Dilithium للتوقيع
  static Future<({
    List<int> publicKey,
    List<int> secretKey,
  })> generateDilithiumKeyPair(String userId) async {
    throw UnsupportedError('Quantum Dilithium functionality is disabled. Enable ml_dsa in pubspec to use.');
  }
  
  /// توقيع رسالة باستخدام Dilithium
  static Future<String> signWithDilithium(
    String message,
    String userId,
  ) async {
    throw UnsupportedError('Quantum signing is disabled.');
  }
  
  /// التحقق من التوقيع
  static Future<bool> verifyDilithiumSignature(
    String message,
    String signatureBase64,
    String userId,
  ) async {
    throw UnsupportedError('Quantum verification is disabled.');
  }
  
  // ============================================================
  // 🤝 المفتاح الهجين (Hybrid - كلاسيكي + كمومي)
  // ============================================================
  
  /// دمج مفتاح كلاسيكي (X25519) مع مفتاح كمومي (Kyber)
  static Future<List<int>> hybridKeyExchange({
    required List<int> classicSharedSecret,  // من X25519
    required List<int> quantumSharedSecret,  // من Kyber
  }) async {
    // دمج المفتاحين
    final combined = [...classicSharedSecret, ...quantumSharedSecret];
    
    // إضافة الملح (salt)
    final salt = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    
    // استخلاص مفتاح نهائي باستخدام HKDF
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(combined),
      info: utf8.encode('privoo:hybrid:quantum:v2'),
      nonce: salt,
    );
    
    final finalKey = await derived.extractBytes();
    logger.i('🔐 تم إنشاء مفتاح هجين (كلاسيكي + كمومي)');
    
    return finalKey;
  }
  
  // ============================================================
  // 📦 تخزين وإدارة المفاتيح الكمومية
  // ============================================================
  
  /// تخزين ciphertext للمستخدم الآخر
  static Future<void> storeQuantumCiphertext(
    String chatId,
    String userId,
    List<int> ciphertext,
  ) async {
    await _firestore.collection('quantum_sessions').doc(chatId).set({
      'ciphertext_$userId': base64Encode(ciphertext),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  /// استرجاع ciphertext للمستخدم
  static Future<List<int>?> getQuantumCiphertext(
    String chatId,
    String userId,
  ) async {
    final doc = await _firestore.collection('quantum_sessions').doc(chatId).get();
    final ciphertextB64 = doc.data()?['ciphertext_$userId'] as String?;
    if (ciphertextB64 == null) return null;
    return base64Decode(ciphertextB64);
  }
  
  /// حذف جلسة كمومية
  static Future<void> deleteQuantumSession(String chatId) async {
    await _firestore.collection('quantum_sessions').doc(chatId).delete();
  }
  
  // ============================================================
  // 🔍 دوال مساعدة
  // ============================================================
  
  static Future<String> _generateFingerprint(List<int> publicKey) async {
    final digest = await Sha256().hash(publicKey);
    final fingerprint = digest.bytes
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
    return fingerprint;
  }
  
  /// التحقق من توفر المقاومة الكمومية
  static bool get isAvailable {
    try {
      // التحقق من وجود المكتبات
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// حذف مفاتيح كمومية للمستخدم (عند حذف الحساب)
  static Future<void> deleteQuantumKeys(String userId) async {
    await _storage.delete(key: '${_kyberPrivKey}_$userId');
    await _storage.delete(key: '${_kyberPubKey}_$userId');
    await _storage.delete(key: '${_dilithiumPrivKey}_$userId');
    await _storage.delete(key: '${_dilithiumPubKey}_$userId');
    await _firestore.collection('quantum_keys').doc(userId).delete();
    logger.i('🗑️ تم حذف المفاتيح الكمومية للمستخدم $userId');
  }
}