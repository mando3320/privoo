// lib/services/quantum_resistant_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';

class QuantumResistantService {
  static final _storage = FlutterSecureStorage();
  static final _firestore = FirebaseFirestore.instance;
  
  static const String _kyberPrivKey = 'quantum_kyber_private';
  static const String _kyberPubKey = 'quantum_kyber_public';
  static const String _dilithiumPrivKey = 'quantum_dilithium_private';
  static const String _dilithiumPubKey = 'quantum_dilithium_public';
  
  static Future<({
    List<int> publicKey,
    List<int> secretKey,
    String fingerprint,
  })> generateKyberKeyPair(String userId) async {
    try {
      final x25519 = X25519();
      final keyPair = await x25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final secretKeyBytes = await keyPair.extractPrivateKeyBytes();
      
      final fingerprint = await _generateFingerprint(publicKey.bytes);
      
      await _storage.write(key: '${_kyberPrivKey}_$userId', value: base64Encode(secretKeyBytes));
      await _storage.write(key: '${_kyberPubKey}_$userId', value: base64Encode(publicKey.bytes));
      
      await _firestore.collection('quantum_keys').doc(userId).set({
        'kyberPublicKey': base64Encode(publicKey.bytes),
        'kyberFingerprint': fingerprint,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      logger.i('🔐 تم توليد مفاتيح كمومية محاكاة للمستخدم $userId');
      
      return (
        publicKey: publicKey.bytes,
        secretKey: secretKeyBytes,
        fingerprint: fingerprint,
      );
    } catch (e) {
      logger.e('❌ فشل توليد المفاتيح الكمومية: $e');
      rethrow;
    }
  }
  
  static Future<List<int>> getPeerKyberPublicKey(String peerId) async {
    final doc = await _firestore.collection('quantum_keys').doc(peerId).get();
    if (!doc.exists || doc.data()?['kyberPublicKey'] == null) {
      throw Exception('Quantum public key not found for $peerId');
    }
    return base64Decode(doc.data()!['kyberPublicKey']);
  }
  
  static Future<({
    List<int> ciphertext,
    List<int> sharedSecret,
  })> encapsulate(List<int> recipientPublicKey) async {
    try {
      final x25519 = X25519();
      final ephemeralPair = await x25519.newKeyPair();
      final ephemeralPub = await ephemeralPair.extractPublicKey();
      
      final recipientPub = SimplePublicKey(recipientPublicKey, type: KeyPairType.x25519);
      final sharedSecret = await x25519.sharedSecretKey(
        keyPair: ephemeralPair,
        remotePublicKey: recipientPub,
      );
      
      final ciphertext = ephemeralPub.bytes;
      final sharedSecretBytes = await sharedSecret.extractBytes();
      
      return (
        ciphertext: ciphertext,
        sharedSecret: sharedSecretBytes,
      );
    } catch (e) {
      logger.e('❌ فشل التغليف الكمومي: $e');
      rethrow;
    }
  }
  
  static Future<List<int>> decapsulate(
    List<int> ciphertext,
    List<int> privateKey,
  ) async {
    try {
      final myPrivateKey = SimpleKeyPairData(
        privateKey,
        type: KeyPairType.x25519,
      );
      final ephemeralPub = SimplePublicKey(ciphertext, type: KeyPairType.x25519);
      
      final sharedSecret = await X25519().sharedSecretKey(
        keyPair: myPrivateKey,
        remotePublicKey: ephemeralPub,
      );
      
      return await sharedSecret.extractBytes();
    } catch (e) {
      logger.e('❌ فك التشفير الكمومي: $e');
      rethrow;
    }
  }
  
  static Future<({
    List<int> publicKey,
    List<int> secretKey,
  })> generateDilithiumKeyPair(String userId) async {
    try {
      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final secretKeyBytes = await keyPair.extractPrivateKeyBytes();
      
      await _storage.write(key: '${_dilithiumPrivKey}_$userId', value: base64Encode(secretKeyBytes));
      await _storage.write(key: '${_dilithiumPubKey}_$userId', value: base64Encode(publicKey.bytes));
      
      await _firestore.collection('quantum_keys').doc(userId).set({
        'dilithiumPublicKey': base64Encode(publicKey.bytes),
      }, SetOptions(merge: true));
      
      logger.i('✍️ تم توليد مفاتيح توقيع كمومية محاكاة للمستخدم $userId');
      
      return (
        publicKey: publicKey.bytes,
        secretKey: secretKeyBytes,
      );
    } catch (e) {
      logger.e('❌ فشل توليد مفاتيح التوقيع: $e');
      rethrow;
    }
  }
  
  static Future<String> signWithDilithium(
    String message,
    String userId,
  ) async {
    try {
      final secretKeyB64 = await _storage.read(key: '${_dilithiumPrivKey}_$userId');
      if (secretKeyB64 == null) {
        throw Exception('No Dilithium key found for user $userId');
      }
      
      final ed25519 = Ed25519();
      final keyPair = SimpleKeyPairData(
        base64Decode(secretKeyB64),
        type: KeyPairType.ed25519,
      );
      
      final signature = await ed25519.sign(utf8.encode(message), keyPair: keyPair);
      return base64Encode(signature.bytes);
    } catch (e) {
      logger.e('❌ فشل التوقيع: $e');
      rethrow;
    }
  }
  
  static Future<bool> verifyDilithiumSignature(
    String message,
    String signatureBase64,
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection('quantum_keys').doc(userId).get();
      final publicKeyB64 = doc.data()?['dilithiumPublicKey'] as String?;
      if (publicKeyB64 == null) {
        return false;
      }
      
      final ed25519 = Ed25519();
      final publicKey = SimplePublicKey(base64Decode(publicKeyB64), type: KeyPairType.ed25519);
      final signature = Signature(base64Decode(signatureBase64), publicKey: publicKey);
      
      return await ed25519.verify(utf8.encode(message), signature: signature);
    } catch (e) {
      logger.e('❌ فشل التحقق من التوقيع: $e');
      return false;
    }
  }
  
  static Future<List<int>> hybridKeyExchange({
    required List<int> classicSharedSecret,
    required List<int> quantumSharedSecret,
  }) async {
    final combined = [...classicSharedSecret, ...quantumSharedSecret];
    
    final salt = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(combined),
      info: utf8.encode('privoo:hybrid:quantum:v2'),
      nonce: salt,
    );
    
    final finalKey = await derived.extractBytes();
    logger.i('🔐 تم إنشاء مفتاح هجين (كلاسيكي + كمومي محاكاة)');
    
    return finalKey;
  }
  
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
  
  static Future<List<int>?> getQuantumCiphertext(
    String chatId,
    String userId,
  ) async {
    final doc = await _firestore.collection('quantum_sessions').doc(chatId).get();
    final ciphertextB64 = doc.data()?['ciphertext_$userId'] as String?;
    if (ciphertextB64 == null) return null;
    return base64Decode(ciphertextB64);
  }
  
  static Future<void> deleteQuantumSession(String chatId) async {
    await _firestore.collection('quantum_sessions').doc(chatId).delete();
  }
  
  static Future<String> _generateFingerprint(List<int> publicKey) async {
    final digest = await Sha256().hash(publicKey);
    final fingerprint = digest.bytes
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
    return fingerprint;
  }
  
  static bool get isAvailable => true;
  
  static Future<void> deleteQuantumKeys(String userId) async {
    await _storage.delete(key: '${_kyberPrivKey}_$userId');
    await _storage.delete(key: '${_kyberPubKey}_$userId');
    await _storage.delete(key: '${_dilithiumPrivKey}_$userId');
    await _storage.delete(key: '${_dilithiumPubKey}_$userId');
    await _firestore.collection('quantum_keys').doc(userId).delete();
    logger.i('🗑️ تم حذف المفاتيح الكمومية للمستخدم $userId');
  }
}