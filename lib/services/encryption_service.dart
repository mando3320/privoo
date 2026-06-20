// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static final _algo = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static List<int> buildAAD({
    required String chatId,
    required String senderId,
    required String receiverId,
    required int ratchetN,
    required int timestamp,
    required String messageType,
    required int protocolVersion,
    required List<int> dhPub,
  }) {
    return utf8.encode(
      'chat:$chatId;sender:$senderId;recv:$receiverId;'
      'n:$ratchetN;ts:$timestamp;type:$messageType;'
      'v:$protocolVersion;dh:${base64Encode(dhPub)}'
    );
  }

  static Future<String> encrypt({
    required String plaintext,
    required List<int> keyBytes,
    List<int>? aad,
    String algorithm = 'AES-GCM-256',
  }) async {
    final secretKey = SecretKey(keyBytes);
    final nonce = _randomNonce(12);
    
    final secretBox = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
      aad: aad ?? [],
    );
    
    final combined = [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
    return base64Encode(combined);
  }

  static Future<String> decrypt({
    required String encrypted,
    required List<int> keyBytes,
    List<int>? aad,
  }) async {
    final combined = base64Decode(encrypted);
    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));
    
    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    
    final decrypted = await _algo.decrypt(
      secretBox,
      secretKey: secretKey,
      aad: aad ?? [],
    );
    return utf8.decode(decrypted);
  }

  static Future<List<int>> encryptBytes(
    List<int> bytes,
    List<int> keyBytes,
  ) async {
    final secretKey = SecretKey(keyBytes);
    final nonce = _randomNonce(12);
    
    final secretBox = await _algo.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    return [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
  }

  static Future<List<int>> decryptBytes(
    List<int> encrypted,
    List<int> keyBytes,
  ) async {
    final nonce = encrypted.sublist(0, 12);
    final cipherText = encrypted.sublist(12, encrypted.length - 16);
    final mac = Mac(encrypted.sublist(encrypted.length - 16));
    
    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    
    return await _algo.decrypt(secretBox, secretKey: secretKey);
  }

  static Future<String> encryptSupportMessage(String message) async {
    final key = utf8.encode('privoo_support_key_2024');
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(key),
      info: utf8.encode('privoo:support'),
    );
    final keyBytes = await derived.extractBytes();
    return await encrypt(plaintext: message, keyBytes: keyBytes);
  }

  static Future<String> hashEmail(String email) async {
    final hash = await Sha256().hash(utf8.encode(email));
    return base64Encode(hash.bytes);
  }

  static List<int> _randomNonce(int len) {
    final rnd = Random.secure();
    return List<int>.generate(len, (_) => rnd.nextInt(256));
  }
}