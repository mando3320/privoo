// services/call_service_signal.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../services/encryption_service.dart';
import '../services/key_exchange_service.dart';
import '../services/ratchet_service.dart';
import '../services/verification_service.dart';

/// 📞 خدمة الإشارات (Signaling) متوافقة مع E2EE + Double Ratchet + Verification
class CallServiceSignal {
  final _db = FirebaseFirestore.instance;
  final _kx = KeyExchangeService();
  final _verification = VerificationService();
  final logger = Logger();

  List<int> _buildSignalingAad({
    required String callId,
    required String senderId,
    required String receiverId,
    required String kind,
    required int version,
    required int timestamp,
    required int msgN,
    required List<int> dhPub,
    String transport = 'webrtc',
  }) {
    return utf8.encode(
      'call:$callId;sender:$senderId;recv:$receiverId;'
      'kind:$kind;v:$version;ts:$timestamp;msgN:$msgN;'
      'dh:${base64Encode(dhPub)};transport:$transport'
    );
  }

  Future<Map<String, dynamic>> _encryptPayload({
    required Map<String, dynamic> payload,
    required List<int> mk,
    required List<int> aad,
    String algorithm = 'AES-GCM-256',
  }) async {
    final plaintext = jsonEncode(payload);
    final enc = await EncryptionService.encrypt(
      plaintext: plaintext,
      keyBytes: mk,
      aad: aad,
      algorithm: algorithm,
    );
    return {'enc': enc, 'v': 2, 'alg': algorithm};
  }

  Future<Map<String, dynamic>> decryptPayload({
    required Map<String, dynamic> encrypted,
    required List<int> mk,
    required List<int> aad,
  }) async {
    final enc = encrypted['enc'] as String;
    final clear = await EncryptionService.decrypt(
      encrypted: enc,
      keyBytes: mk,
      aad: aad,
    );
    return jsonDecode(clear) as Map<String, dynamic>;
  }

  Future<String?> createCallAsCaller({
    required String callerId,
    required String receiverId,
    required Map<String, dynamic> offerPlain,
    required bool isVideo,
  }) async {
    try {
      final doc = _db.collection('calls').doc();
      final callId = doc.id;
      final ts = DateTime.now().millisecondsSinceEpoch;

      final session = await _kx.establishSession(
        chatId: callId,
        myUserId: callerId,
        peerUserId: receiverId,
      );
      final sessionKey = session.chatMasterKey;
      
      await RatchetService.initRatchet(
        chatId: callId,
        myUserId: callerId,
        peerUserId: receiverId,
        sessionKey32: sessionKey,
      );

      final ratchetData = await RatchetService.nextSendingKey(
        chatId: callId,
        myUserId: callerId,
      );

      final aad = _buildSignalingAad(
        callId: callId,
        senderId: callerId,
        receiverId: receiverId,
        kind: 'offer',
        version: 2,
        timestamp: ts,
        msgN: ratchetData.n,
        dhPub: ratchetData.myDhPub,
      );

      final offer = await _encryptPayload(
        payload: offerPlain,
        mk: ratchetData.mk,
        aad: aad,
      );

      final callerVerificationId =
          await _verification.createVerification(userId: callerId, peerId: receiverId);
      final receiverVerificationId =
          await _verification.createVerification(userId: receiverId, peerId: callerId);

      await doc.set({
        'callId': callId,
        'callerId': callerId,
        'receiverId': receiverId,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'isVideo': isVideo,
        'offer': offer,
        'answer': null,
        'active': true,
        'protocolVersion': 2,
        'offerTimestamp': ts,
        'ratchetN': ratchetData.n,
        'dhPub': base64Encode(ratchetData.myDhPub),
        'callerVerificationId': callerVerificationId,
        'receiverVerificationId': receiverVerificationId,
      });

      logger.i("✅ تم إنشاء غرفة مكالمة Signal-Style: $callId");
      return callId;
    } catch (e) {
      logger.e("❌ فشل إنشاء مكالمة Signal-Style: $e");
      return null;
    }
  }

  Future<bool> answerCallAsCallee({
    required String callId,
    required String callerId,
    required String receiverId,
    required Map<String, dynamic> answerPlain,
  }) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;

      final ratchetData = await RatchetService.nextSendingKey(
        chatId: callId,
        myUserId: receiverId,
      );

      final aad = _buildSignalingAad(
        callId: callId,
        senderId: receiverId,
        receiverId: callerId,
        kind: 'answer',
        version: 2,
        timestamp: ts,
        msgN: ratchetData.n,
        dhPub: ratchetData.myDhPub,
      );

      final answer = await _encryptPayload(
        payload: answerPlain,
        mk: ratchetData.mk,
        aad: aad,
      );

      await _db.collection('calls').doc(callId).update({
        'answer': answer,
        'answerTime': FieldValue.serverTimestamp(),
        'answerTimestamp': ts,
        'ratchetN': ratchetData.n,
        'dhPub': base64Encode(ratchetData.myDhPub),
      });

      logger.i("✅ تم تحديث المكالمة بـ Answer مشفّر Signal-Style.");
      return true;
    } catch (e) {
      logger.e("❌ فشل تحديث المكالمة بـ Answer Signal-Style: $e");
      return false;
    }
  }

  Future<bool> addIceCandidate({
    required String callId,
    required String senderId,
    required String receiverId,
    required Map<String, dynamic> candidatePlain,
    required bool isCaller,
  }) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;

      final ratchetData = await RatchetService.nextSendingKey(
        chatId: callId,
        myUserId: senderId,
      );

      final aad = _buildSignalingAad(
        callId: callId,
        senderId: senderId,
        receiverId: receiverId,
        kind: 'ice',
        version: 2,
        timestamp: ts,
        msgN: ratchetData.n,
        dhPub: ratchetData.myDhPub,
      );

      final candEnc = await _encryptPayload(
        payload: candidatePlain,
        mk: ratchetData.mk,
        aad: aad,
      );

      final col = isCaller ? 'callerCandidates' : 'calleeCandidates';
      await _db.collection('calls').doc(callId).collection(col).add({
        'candidate': candEnc,
        'timestamp': FieldValue.serverTimestamp(),
        'candidateTimestamp': ts,
        'ratchetN': ratchetData.n,
        'dhPub': base64Encode(ratchetData.myDhPub),
      });

      return true;
    } catch (e) {
      logger.e("❌ فشل إضافة ICE Candidate Signal-Style: $e");
      return false;
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'endTime': FieldValue.serverTimestamp(),
        'active': false,
      });
      logger.i("✅ تم إنهاء المكالمة Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل إنهاء المكالمة Signal-Style: $e");
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> callDocStream(String callId) {
    return _db.collection('calls').doc(callId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> candidatesStream(
      String callId, bool isCaller) {
    final col = isCaller ? 'callerCandidates' : 'calleeCandidates';
    return _db
        .collection('calls')
        .doc(callId)
        .collection(col)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> clearCandidates(String callId) async {
    try {
      final callerSnap = await _db
          .collection('calls')
          .doc(callId)
          .collection('callerCandidates')
          .get();
      final calleeSnap = await _db
          .collection('calls')
          .doc(callId)
          .collection('calleeCandidates')
          .get();

      final batch = _db.batch();
      for (final d in [...callerSnap.docs, ...calleeSnap.docs]) {
        batch.delete(d.reference);
      }
      await batch.commit();
      logger.i("✅ تم حذف جميع ICE Candidates Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل تنظيف ICE Candidates Signal-Style: $e");
    }
  }

  Future<void> deleteCallRoom(String callId) async {
    await clearCandidates(callId);
    try {
      await _db.collection('calls').doc(callId).delete();
      logger.i("✅ تم حذف وثيقة المكالمة Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل حذف المكالمة Signal-Style: $e");
    }
  }

  Future<bool> isUserVerified(String verificationId) async {
    if (verificationId.isEmpty) return false;
    final snapshot = await _db.collection('verifications').doc(verificationId).get();
    if (!snapshot.exists) return false;
    final data = snapshot.data()!;
    return data['isVerified'] ?? false;
  }
}