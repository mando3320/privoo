// services/call_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../services/encryption_service.dart';
import '../services/key_exchange_service.dart';
import '../services/ratchet_service.dart';
import '../services/verification_service.dart';
import 'supabase_service.dart';

/// 📞 خدمة الإشارات (Signaling) متوافقة مع E2EE + Double Ratchet + Verification
class CallServiceSignal {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _kx = KeyExchangeService();
  final _verification = VerificationService();
  final logger = Logger();
  final _uuid = const Uuid();

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
      final callId = _uuid.v4();
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

      await _supabase.from('calls').insert({
        'id': callId,
        'caller_id': callerId,
        'receiver_id': receiverId,
        'is_video': isVideo,
        'offer': offer,
        'answer': null,
        'active': true,
        'protocol_version': 2,
        'offer_timestamp': ts,
        'ratchet_n': ratchetData.n,
        'dh_pub': base64Encode(ratchetData.myDhPub),
        'caller_verification_id': callerVerificationId,
        'receiver_verification_id': receiverVerificationId,
        'created_at': DateTime.now().toIso8601String(),
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

      await _supabase
          .from('calls')
          .update({
            'answer': answer,
            'answer_timestamp': ts,
            'ratchet_n': ratchetData.n,
            'dh_pub': base64Encode(ratchetData.myDhPub),
          })
          .eq('id', callId);

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

      await _supabase.from('ice_candidates').insert({
        'call_id': callId,
        'sender_id': senderId,
        'candidate': candEnc,
        'candidate_timestamp': ts,
        'ratchet_n': ratchetData.n,
        'dh_pub': base64Encode(ratchetData.myDhPub),
        'is_caller': isCaller,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      logger.e("❌ فشل إضافة ICE Candidate Signal-Style: $e");
      return false;
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _supabase
          .from('calls')
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'active': false,
          })
          .eq('id', callId);
      logger.i("✅ تم إنهاء المكالمة Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل إنهاء المكالمة Signal-Style: $e");
    }
  }

  Stream<Map<String, dynamic>?> callDocStream(String callId) {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((data) => data.isEmpty ? null : data.first);
  }

  Stream<List<Map<String, dynamic>>> candidatesStream(
      String callId, bool isCaller) {
    return _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .eq('is_caller', isCaller)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> clearCandidates(String callId) async {
    try {
      await _supabase
          .from('ice_candidates')
          .delete()
          .eq('call_id', callId);
      logger.i("✅ تم حذف جميع ICE Candidates Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل تنظيف ICE Candidates Signal-Style: $e");
    }
  }

  Future<void> deleteCallRoom(String callId) async {
    await clearCandidates(callId);
    try {
      await _supabase
          .from('calls')
          .delete()
          .eq('id', callId);
      logger.i("✅ تم حذف وثيقة المكالمة Signal-Style: $callId");
    } catch (e) {
      logger.e("❌ فشل حذف المكالمة Signal-Style: $e");
    }
  }

  Future<bool> isUserVerified(String verificationId) async {
    if (verificationId.isEmpty) return false;
    final snapshot = await _supabase
        .from('verifications')
        .select()
        .eq('id', verificationId)
        .maybeSingle();
    if (snapshot == null) return false;
    return snapshot['is_verified'] ?? false;
  }
}