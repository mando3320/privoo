// lib/services/verification_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/verification_model.dart';
import '../services/encryption_service.dart';
import '../services/key_exchange_service.dart';
import '../services/ratchet_service.dart';

class VerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final KeyExchangeService _kx = KeyExchangeService();
  final logger = Logger();

  Future<String?> getMyFingerprint() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final fingerprint = user.uid.hashCode.toRadixString(16).toUpperCase();
      return fingerprint;
    } catch (e) {
      logger.e("❌ فشل الحصول على البصمة: $e");
      return null;
    }
  }

  Future<String?> getPeerFingerprint(String peerUserId) async {
    try {
      final doc = await _db.collection('users').doc(peerUserId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['fingerprint'] ?? peerUserId.hashCode.toRadixString(16).toUpperCase();
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
      final doc = _db.collection('verifications').doc();
      final verificationId = doc.id;
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

      // ✅ التصحيح: استخدام userId الصحيح بدلاً من السلسلة الفارغة
      final ratchetData = await RatchetService.nextSendingKey(
        chatId: verificationId,
        myUserId: userId,  // ✅ تم التصحيح
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

      await doc.set(verification.toJson());
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
      final docRef = _db.collection('verifications').doc(verificationId);
      final doc = await docRef.get();
      final data = doc.data();
      final userId = data?['userId'] as String? ?? '';
      
      // ✅ التصحيح: استخدام userId الصحيح
      final ratchetData = await RatchetService.nextSendingKey(
        chatId: verificationId,
        myUserId: userId,  // ✅ تم التصحيح
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

      await docRef.update({
        'isVerified': true,
        if (encPeerFingerprint != null) 'peerFingerprint': encPeerFingerprint,
      });

      logger.i("✅ Verification $verificationId تم التحقق منه بنجاح");
      return true;
    } catch (e) {
      logger.e("❌ فشل تحديث Verification $verificationId: $e");
      return false;
    }
  }

  Stream<VerificationModel?> getVerificationStream(String verificationId) {
    return _db.collection('verifications').doc(verificationId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return VerificationModel.fromJson(doc.data()!);
      },
    );
  }

  Future<void> deleteVerification(String verificationId) async {
    try {
      await _db.collection('verifications').doc(verificationId).delete();
      logger.i("✅ تم حذف Verification: $verificationId");
    } catch (e) {
      logger.e("❌ فشل حذف Verification $verificationId: $e");
    }
  }
}