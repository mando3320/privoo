// services/encryption_service.dart
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../main.dart';

 

class EncryptionService {
  static final _aes = AesGcm.with256bits();
  static final _chacha = Chacha20.poly1305Aead();

  /// 🔐 تشفير رسالة
  static Future<String> encrypt({
    required String plaintext,
    required List<int> keyBytes,
    List<int>? aad,
    String algorithm = 'AES-GCM-256',
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError("يجب أن يكون مفتاح التشفير 32 بايت");
    }

    final key = SecretKey(keyBytes);
    final algo = (algorithm == 'ChaCha20-Poly1305') ? _chacha : _aes;
    final nonce = algo.newNonce();

    // ✅ إصلاح: تمرير aad فقط إذا كان غير null
    final secretBox = await algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
      aad: aad ?? const <int>[],
    );

    final payload = jsonEncode({
      'n': base64Encode(nonce),
      'c': base64Encode(secretBox.cipherText),
      't': base64Encode(secretBox.mac.bytes),
      'v': 2,
      'alg': algorithm,
    });

    return base64Encode(utf8.encode(payload));
  }

  /// 🔓 فك تشفير رسالة
  static Future<String> decrypt({
    required String encrypted,
    required List<int> keyBytes,
    List<int>? aad,
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError("مفتاح فك التشفير يجب أن يكون 32 بايت");
    }

    try {
      final decodedJson = utf8.decode(base64Decode(encrypted));
      final decoded = jsonDecode(decodedJson);

      final nonce = base64Decode(decoded['n']);
      final cipher = base64Decode(decoded['c']);
      final tag = base64Decode(decoded['t']);
      final alg = decoded['alg'] ?? 'AES-GCM-256';

      final box = SecretBox(cipher, nonce: nonce, mac: Mac(tag));
      final key = SecretKey(keyBytes);
      final algo = (alg == 'ChaCha20-Poly1305') ? _chacha : _aes;
      // ✅ إصلاح: تمرير aad فقط إذا كان غير null
      final clear = await algo.decrypt(box, secretKey: key, aad: aad ?? const <int>[]);
      return utf8.decode(clear);
    } catch (e) {
      logger.e('❌ فشل فك التشفير: $e');
      throw Exception('فشل التوثيق أو خطأ في المفتاح');
    }
  }

  /// 🔐 تشفير بيانات ثنائية (للملفات)
  static Future<List<int>> encryptBytes(List<int> plaintext, List<int> keyBytes) async {
    if (keyBytes.length != 32) {
      throw ArgumentError("يجب أن يكون مفتاح التشفير 32 بايت");
    }
    final key = SecretKey(keyBytes);
    final nonce = _aes.newNonce();
    final secretBox = await _aes.encrypt(plaintext, secretKey: key, nonce: nonce);
    final combined = [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
    return combined;
  }

  /// تشفير رسالة دعم مبسط (يُستخدم للرسائل غير الحساسة في واجهة الدعم)
  /// NOTE: This is intentionally lightweight; replace with real encryption if needed.
  static Future<String> encryptSupportMessage(String message) async {
    return base64Encode(utf8.encode(message));
  }

  /// Hash an email address to produce a pseudonymous identifier
  static Future<String> hashEmail(String email) async {
    final digest = await Sha256().hash(utf8.encode(email));
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 🔓 فك تشفير بيانات ثنائية (للملفات)
  static Future<List<int>> decryptBytes(List<int> encrypted, List<int> keyBytes) async {
    if (keyBytes.length != 32) {
      throw ArgumentError("مفتاح فك التشفير يجب أن يكون 32 بايت");
    }
    if (encrypted.length < 28) {
      throw ArgumentError("البيانات المشفرة غير صالحة");
    }
    final nonce = encrypted.sublist(0, 12);
    final cipherText = encrypted.sublist(12, encrypted.length - 16);
    final mac = Mac(encrypted.sublist(encrypted.length - 16));
    final box = SecretBox(cipherText, nonce: nonce, mac: mac);
    final key = SecretKey(keyBytes);
    final clear = await _aes.decrypt(box, secretKey: key);
    return clear;
  }
}