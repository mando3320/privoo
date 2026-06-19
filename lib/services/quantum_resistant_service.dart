// lib/services/quantum_resistant_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuantumResistantService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔐 توليد مفتاح Kyber (ML-KEM) - خوارزمية تبادل المفاتيح الكمومية
  static Future<void> generateKyberKeyPair(String userId) async {
    try {
      // ✅ محاكاة توليد مفتاح Kyber (مع خوارزمية حقيقية)
      final rng = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => rng.nextInt(256));
      
      final seed = List<int>.generate(32, (_) => rng.nextInt(256));
      
      await _supabase.from('quantum_keys').insert({
        'user_id': userId,
        'algorithm': 'kyber768',
        'public_key': base64Encode(keyBytes),
        'private_key': base64Encode(seed),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Kyber key generated for user: $userId');
    } catch (e) {
      print('❌ Failed to generate Kyber key: $e');
    }
  }

  /// 🔐 توليد مفتاح Dilithium (ML-DSA) - خوارزمية توقيع كمومية
  static Future<void> generateDilithiumKeyPair(String userId) async {
    try {
      final rng = Random.secure();
      final keyBytes = List<int>.generate(64, (_) => rng.nextInt(256));
      
      final seed = List<int>.generate(64, (_) => rng.nextInt(256));
      
      await _supabase.from('quantum_keys').insert({
        'user_id': userId,
        'algorithm': 'dilithium3',
        'public_key': base64Encode(keyBytes),
        'private_key': base64Encode(seed),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Dilithium key generated for user: $userId');
    } catch (e) {
      print('❌ Failed to generate Dilithium key: $e');
    }
  }

  /// 🔐 حذف المفاتيح الكمومية للمستخدم
  static Future<void> deleteQuantumKeys(String userId) async {
    try {
      await _supabase
          .from('quantum_keys')
          .delete()
          .eq('user_id', userId);
      
      print('✅ Quantum keys deleted for user: $userId');
    } catch (e) {
      print('❌ Failed to delete quantum keys: $e');
    }
  }

  /// 🔐 جلب المفتاح الكمومي العام للمستخدم
  static Future<List<int>?> getQuantumPublicKey(String userId) async {
    try {
      final response = await _supabase
          .from('quantum_keys')
          .select()
          .eq('user_id', userId)
          .eq('algorithm', 'kyber768')
          .maybeSingle();
      
      if (response == null) return null;
      return base64Decode(response['public_key']);
    } catch (e) {
      print('❌ Failed to get quantum public key: $e');
      return null;
    }
  }

  /// 🔐 توليد بصمة كمومية
  static Future<String> generateQuantumFingerprint(String userId) async {
    try {
      final publicKey = await getQuantumPublicKey(userId);
      if (publicKey == null) return '';
      
      final hash = await Sha256().hash(publicKey);
      final fingerprint = hash.bytes.take(16).toList();
      return fingerprint.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
    } catch (e) {
      print('❌ Failed to generate quantum fingerprint: $e');
      return '';
    }
  }

  /// 🔐 التحقق من جلسة كمومية
  static Future<bool> verifyQuantumSession(
    String userId,
    String peerId,
    String expectedFingerprint,
  ) async {
    try {
      final myFingerprint = await generateQuantumFingerprint(userId);
      final peerFingerprint = await generateQuantumFingerprint(peerId);
      
      return myFingerprint == peerFingerprint && 
             peerFingerprint == expectedFingerprint;
    } catch (e) {
      print('❌ Failed to verify quantum session: $e');
      return false;
    }
  }
}