// lib/services/verification_service.dart
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/verification_model.dart';
import '../services/encryption_service.dart';
import '../services/key_exchange_service.dart';
import '../services/ratchet_service.dart';
import '../services/supabase_service.dart';

class VerificationService {
  final SupabaseService _supabase = SupabaseService();
  final KeyExchangeService _kx = KeyExchangeService();
  final logger = Logger();

  Future<String?> getMyFingerprint() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;
      final fingerprint = user.id.hashCode.toRadixString(16).toUpperCase();
      return fingerprint;
    } catch (e) {
      logger.e("❌ فشل الحصول على البصمة: $e");
      return null;
    }
  }

  Future<String?> getPeerFingerprint(String peerUserId) async {
    try {
      final user = await _supabase.getUser(peerUserId);
      if (user != null) {
        return user.authId.hashCode.toRadixString(16).toUpperCase();
      }
      return peerUserId.hashCode.toRadixString(16).toUpperCase();
    } catch (e) {
      logger.e("❌ فشل الحصول على بصمة الطرف الآخر: $e");
      return null;
    }
  }

  Future<String?> createVerification({
    required String userId,
    required String peerId,
    String? fingerprint,
  }) async {
    try {
      final verificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final ts = DateTime.now().millisecondsSinceEpoch;

      final sessionKey = await _kx.establishSession(
        chatId: verificationId,
        myUserId: userId,
        peerUserId: peerId,
      );

      await RatchetService.initRatchet(
        chatId: verificationId,
        myUserId: userId,
        peerUserId: peerId,
        sessionKey32: sessionKey.chatMasterKey,
      );

      final ratchetData = await RatchetService.nextSendingKey(
        chatId: verificationId,
        myUserId: userId,
      );

      final aad = utf8.encode(
        'verification:$verificationId;sender:$userId;recv:$peerId;n:${ratchetData.n};ts:$ts',
      );

      String? encFingerprint;
      if (fingerprint != null) {
        encFingerprint = await EncryptionService.encrypt(
          plaintext: fingerprint,
          keyBytes: ratchetData.mk,
          aad: aad,
          algorithm: 'AES-GCM-256',
        );
      }

      final verification = VerificationModel(
        id: verificationId,
        userId: userId,
        peerId: peerId,
        fingerprint: encFingerprint,
        isVerified: false,
      );

      // ✅ حفظ في Supabase بدلاً من Firestore
      await _supabase.client.from('verifications').insert(verification.toJson());
      
      logger.i("✅ تم إنشاء Verification: $verificationId");
      return verificationId;
    } catch (e) {
      logger.e("❌ فشل إنشاء Verification: $e");
      return null;
    }
  }

  Future<bool> markVerified({
    required String verificationId,
    String? peerFingerprint,
  }) async {
    try {
      final userId = await _supabase.currentUser?.id ?? '';
      
      final ratchetData = await RatchetService.nextSendingKey(
        chatId: verificationId,
        myUserId: userId,
      );

      String? encPeerFingerprint;
      if (peerFingerprint != null) {
        final aad = utf8.encode('verification:$verificationId;peerFingerprint');
        encPeerFingerprint = await EncryptionService.encrypt(
          plaintext: peerFingerprint,
          keyBytes: ratchetData.mk,
          aad: aad,
          algorithm: 'AES-GCM-256',
        );
      }

      await _supabase.client
          .from('verifications')
          .update({
            'isVerified': true,
            if (encPeerFingerprint != null) 'peerFingerprint': encPeerFingerprint,
          })
          .eq('id', verificationId);

      logger.i("✅ Verification $verificationId تم التحقق منه بنجاح");
      return true;
    } catch (e) {
      logger.e("❌ فشل تحديث Verification $verificationId: $e");
      return false;
    }
  }

  Future<void> deleteVerification(String verificationId) async {
    try {
      await _supabase.client
          .from('verifications')
          .delete()
          .eq('id', verificationId);
      logger.i("✅ تم حذف Verification: $verificationId");
    } catch (e) {
      logger.e("❌ فشل حذف Verification $verificationId: $e");
    }
  }
}