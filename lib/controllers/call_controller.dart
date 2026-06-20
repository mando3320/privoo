// lib/controllers/call_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cryptography/cryptography.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/verification_service.dart';
import '../main.dart';
import '../services/supabase_service.dart';

/// 📞 محرك المكالمات (WebRTC + E2EE Signaling) - Supabase Version
class CallController {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String? _callId;
  String? _callerId;
  late _SignalCrypto _crypto;

  bool micEnabled = true;
  bool camEnabled = true;
  bool speakerOn = false;

  // ✅ Supabase Streams
  StreamSubscription? _callDocSub;
  StreamSubscription? _callerIceSub;
  StreamSubscription? _calleeIceSub;

  // 🎵 مشغلات النغمات
  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _busyPlayer = AudioPlayer();
  final AudioPlayer _offlinePlayer = AudioPlayer();

  Timer? _offlineTimer;
  final int _offlineTimeoutSeconds = 20;
  bool _answered = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  // -------- التهيئة --------
  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _initCrypto(List<int> sharedSecretBytes) async {
    _crypto = await _SignalCrypto.fromSecret(sharedSecretBytes);
    logger.i("🔐 تم تهيئة نظام تشفير الإشارة بنجاح.");
  }

  Future<void> _startLocalStream({required bool isVideo}) async {
    try {
      final constraints = {
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': 720,
                'height': 1280,
                'frameRate': 30,
              }
            : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;
      logger.i("✅ تم الحصول على Local Stream.");
    } catch (e) {
      logger.e("❌ فشل الحصول على Local Stream: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    const config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
      'enableRtpDataChannels': true,
    };
    _pc = await createPeerConnection(config);
    logger.i("✅ تم إنشاء Peer Connection.");

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    _pc?.onTrack = (evt) {
      if (evt.streams.isNotEmpty && remoteRenderer.srcObject != evt.streams[0]) {
        remoteRenderer.srcObject = evt.streams[0];
        logger.i("✅ تم استقبال Remote Stream.");
      }
    };
  }

  // -------- النغمات --------
  Future<void> _playOutgoingTone() async {
    try {
      await _stopAllTones();
      await _ringPlayer.setAsset('assets/audio/privoo_ringing.wav');
      await _ringPlayer.setLoopMode(LoopMode.one);
      await _ringPlayer.play();
      logger.i("🔔 تشغيل نغمة المكالمات الصادرة.");
    } catch (e) {
      logger.w("⚠️ فشل تشغيل نغمة المكالمات الصادرة: $e");
    }
  }

  Future<void> _playIncomingTone() async {
    try {
      await _stopAllTones();
      await _ringPlayer.setAsset('assets/audio/privoo_call.wav');
      await _ringPlayer.setLoopMode(LoopMode.one);
      await _ringPlayer.play();
      logger.i("🔔 تشغيل نغمة المكالمات الواردة.");
    } catch (e) {
      logger.w("⚠️ فشل تشغيل نغمة المكالمات الواردة: $e");
    }
  }

  Future<void> _playBusyTone() async {
    try {
      await _stopAllTones();
      await _busyPlayer.setAsset('assets/audio/privoo_busy.wav');
      await _busyPlayer.setLoopMode(LoopMode.off);
      await _busyPlayer.play();
      logger.i("📵 تشغيل نغمة المشغول.");
    } catch (e) {
      logger.w("⚠️ فشل تشغيل نغمة المشغول: $e");
    }
  }

  Future<void> _playOfflineTone() async {
    try {
      await _stopAllTones();
      await _offlinePlayer.setAsset('assets/audio/privoo_offline.wav');
      await _offlinePlayer.setLoopMode(LoopMode.off);
      await _offlinePlayer.play();
      logger.i("📴 تشغيل نغمة غير متصل.");
    } catch (e) {
      logger.w("⚠️ فشل تشغيل نغمة غير متصل: $e");
    }
  }

  Future<void> _stopAllTones() async {
    try {
      await _ringPlayer.stop();
      await _busyPlayer.stop();
      await _offlinePlayer.stop();
    } catch (e) {
      logger.w("⚠️ فشل إيقاف النغمات: $e");
    }
  }

  void _startOfflineTimer() {
    _cancelOfflineTimer();
    _offlineTimer = Timer(Duration(seconds: _offlineTimeoutSeconds), () async {
      if (!_answered) {
        logger.i("⏱️ لم يصل رد خلال $_offlineTimeoutSeconds ثانية — تشغيل نغمة 'غير متصل'.");
        await _playOfflineTone();
      }
    });
  }

  void _cancelOfflineTimer() {
    if (_offlineTimer?.isActive ?? false) {
      _offlineTimer?.cancel();
      _offlineTimer = null;
    }
  }

  // -------- E2EE --------
  Future<Map<String, dynamic>> _wrapEnc(Map<String, dynamic> plain) async {
    final enc = await _crypto.encryptMap(plain);
    return {'enc': enc};
  }

  Future<Map<String, dynamic>> _unwrapEnc(dynamic maybeEncField) async {
    if (maybeEncField is Map && maybeEncField['enc'] is String) {
      try {
        return await _crypto.decryptToMap(maybeEncField['enc'] as String);
      } catch (e) {
        logger.e("❌ فشل فك تشفير الإشارة: $e");
        return {};
      }
    }
    if (maybeEncField is Map<String, dynamic>) return maybeEncField;
    return {};
  }

  // ==================== Fingerprint Verification ====================
  
  Future<String?> _getMyFingerprint() async {
    try {
      final user = SupabaseService().currentUser;
      if (user == null) return null;
      
      final verificationService = VerificationService();
      return await verificationService.getMyFingerprint();
    } catch (e) {
      logger.e('❌ فشل الحصول على البصمة: $e');
      return null;
    }
  }

  Future<String?> _getPeerFingerprint(String peerUserId) async {
    try {
      final verificationService = VerificationService();
      return await verificationService.getPeerFingerprint(peerUserId);
    } catch (e) {
      logger.e('❌ فشل الحصول على بصمة الطرف الآخر: $e');
      return null;
    }
  }

  Future<bool> _verifyPeerFingerprint(String peerUserId) async {
    try {
      final myFingerprint = await _getMyFingerprint();
      final peerFingerprint = await _getPeerFingerprint(peerUserId);
      
      if (myFingerprint == null || peerFingerprint == null) {
        logger.w('⚠️ تعذر الحصول على البصمات');
        return false;
      }
      
      final isMatch = myFingerprint == peerFingerprint;
      
      if (!isMatch) {
        logger.w('⚠️ بصمة الطرف الآخر غير مطابقة! هجوم MITM محتمل');
      } else {
        logger.i('✅ تم التحقق من هوية الطرف الآخر بنجاح');
      }
      
      return isMatch;
    } catch (e) {
      logger.e('❌ فشل التحقق من البصمة: $e');
      return false;
    }
  }

  // ==================== إنشاء مكالمة ====================
  
  Future<String?> startCallAsCaller({
    required String callerId,
    required String receiverId,
    required bool isVideo,
    required List<int> sharedSecretBytes,
  }) async {
    final isVerified = await _verifyPeerFingerprint(receiverId);
    if (!isVerified) {
      throw Exception('❌ فشل التحقق من هوية الطرف الآخر. المكالمة غير آمنة.');
    }
    
    await _initCrypto(sharedSecretBytes);
    await _initRenderers();
    await _startLocalStream(isVideo: isVideo);
    await _createPeerConnection();

    _pc?.onIceCandidate = (candidate) async {
      if (_callId == null) return;
      final candMap = {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };
      await _addIceCandidateToSupabase(
        callId: _callId!,
        senderId: _callerId ?? callerId,
        candidatePlain: candMap,
      );
    };

    final offer = await _pc!.createOffer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(offer);
    final wrappedOffer = await _wrapEnc(offer.toMap());

    _callerId = callerId;
    _callId = await _createCallInSupabase(
      callerId: callerId,
      receiverId: receiverId,
      offerPlain: wrappedOffer,
      isVideo: isVideo,
    );
    logger.i("📞 تم إنشاء مكالمة جديدة بمعرّف: $_callId");

    _answered = false;
    await _playOutgoingTone();
    _startOfflineTimer();

    _callDocSub = _callDocStream(_callId!).listen((data) async {
      if (data == null) return;

      final ansField = data['answer'];
      if (ansField != null && (await _pc!.getRemoteDescription()) == null) {
        final ansMap = await _unwrapEnc(ansField);
        if (ansMap.isNotEmpty) {
          final ans = RTCSessionDescription(ansMap['sdp'], ansMap['type']);
          await _pc!.setRemoteDescription(ans);
          logger.i("✅ تم استقبال Answer بنجاح.");

          _answered = true;
          _cancelOfflineTimer();
          await _stopAllTones();
        }
      }

      if (data['active'] == false && !_answered) {
        logger.w("📵 المستقبل رفض المكالمة قبل الرد.");
        _cancelOfflineTimer();
        await _stopAllTones();
        await _playBusyTone();
      }
    });

    _calleeIceSub = _candidatesStream(_callId!, false).listen((candidates) async {
      for (var c in candidates) {
        final encField = c['candidate'];
        final dec = await _unwrapEnc(encField);
        if (dec.isNotEmpty) {
          final ice = RTCIceCandidate(dec['candidate'], dec['sdpMid'], dec['sdpMLineIndex']);
          await _pc?.addCandidate(ice);
        }
      }
    });

    return _callId;
  }

  // -------- انضمام المستجيب --------
  Future<void> joinCallAsCallee({
    required String callId,
    required List<int> sharedSecretBytes,
    bool isVideo = true,
  }) async {
    _callId = callId;
    await _initCrypto(sharedSecretBytes);
    await _initRenderers();
    await _startLocalStream(isVideo: isVideo);
    await _createPeerConnection();

    _pc?.onIceCandidate = (candidate) async {
      if (_callId == null) return;
      final candMap = {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };
      final myId = SupabaseService().currentUser?.id ?? '';
      await _addIceCandidateToSupabase(
        callId: _callId!,
        senderId: myId,
        candidatePlain: candMap,
      );
    };

    await _playIncomingTone();

    // read call doc once to obtain callerId
    final callDoc = await _supabase
        .from('calls')
        .select()
        .eq('id', callId)
        .maybeSingle();
    _callerId = callDoc?['caller_id'] as String?;

    _callDocSub = _callDocStream(callId).listen((data) async {
      if (data == null) return;
      final offField = data['offer'];

      if (offField != null && (await _pc!.getRemoteDescription()) == null) {
        final offMap = await _unwrapEnc(offField);
        if (offMap.isNotEmpty) {
          final off = RTCSessionDescription(offMap['sdp'], offMap['type']);
          await _pc!.setRemoteDescription(off);
          logger.i("✅ تم استقبال Offer بنجاح.");

          final answer = await _pc!.createAnswer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
          await _pc!.setLocalDescription(answer);
          final wrappedAnswer = await _wrapEnc(answer.toMap());
          await _answerCallInSupabase(callId: callId, answer: wrappedAnswer);
          logger.i("📤 تم إرسال Answer للمتصل.");
        }
      }

      if (data['active'] == false) {
        logger.w("❌ المكالمة انتهت من طرف الخادم.");
      }
    });

    _callerIceSub = _candidatesStream(callId, true).listen((candidates) async {
      for (var c in candidates) {
        final encField = c['candidate'];
        final dec = await _unwrapEnc(encField);
        if (dec.isNotEmpty) {
          final ice = RTCIceCandidate(dec['candidate'], dec['sdpMid'], dec['sdpMLineIndex']);
          await _pc?.addCandidate(ice);
        }
      }
    });
  }

  // -------- إنهاء المكالمة --------
  Future<void> endCall() async {
    logger.i("🛑 جاري إنهاء المكالمة... $_callId");
    if (_callId != null) {
      await _endCallInSupabase(_callId!);
      await _clearCandidatesInSupabase(_callId!);
    }
    _cancelOfflineTimer();
    await _stopAllTones();
    await dispose();
  }

  // -------- تحكمات --------
  Future<void> toggleMic() async {
    micEnabled = !micEnabled;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = micEnabled);
    logger.d("🎙️ المايكروفون: ${micEnabled ? 'مفعّل' : 'مغلق'}");
  }

  Future<void> toggleCamera() async {
    camEnabled = !camEnabled;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = camEnabled);
    logger.d("📸 الكاميرا: ${camEnabled ? 'مفعّلة' : 'مغلقة'}");
  }

  Future<void> switchCamera() async {
    for (var t in _localStream?.getVideoTracks() ?? []) {
      await Helper.switchCamera(t);
    }
    logger.d("🔄 تم تبديل الكاميرا.");
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await Helper.setSpeakerphoneOn(speakerOn);
    logger.d("🔊 مكبر الصوت: ${speakerOn ? 'مفعّل' : 'مغلق'}");
  }

  Future<void> enableVideoDuringCall() async {
    try {
      if (_pc == null) return;
      if (_localStream == null) {
        await _startLocalStream(isVideo: true);
        for (var track in _localStream!.getTracks()) {
          await _pc!.addTrack(track, _localStream!);
        }
        localRenderer.srcObject = _localStream;
      } else {
        for (var t in _localStream!.getVideoTracks()) {
          t.enabled = true;
        }
      }
      camEnabled = true;
      logger.i('✅ تم تفعيل الفيديو أثناء المكالمة');
    } catch (e) {
      logger.e('❌ فشل تفعيل الفيديو: $e');
    }
  }

  Future<void> disableVideoDuringCall() async {
    try {
      for (var t in _localStream?.getVideoTracks() ?? []) {
        t.enabled = false;
      }
      camEnabled = false;
      logger.i('🔇 تم تعطيل الفيديو أثناء المكالمة');
    } catch (e) {
      logger.e('❌ فشل تعطيل الفيديو: $e');
    }
  }

  // ==================== Supabase Helper Methods ====================
  
  Future<String> _createCallInSupabase({
    required String callerId,
    required String receiverId,
    required Map<String, dynamic> offerPlain,
    required bool isVideo,
  }) async {
    final callId = DateTime.now().millisecondsSinceEpoch.toString();
    await _supabase.from('calls').insert({
      'id': callId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'offer': offerPlain,
      'is_video': isVideo,
      'active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
    return callId;
  }

  Future<void> _answerCallInSupabase({
    required String callId,
    required Map<String, dynamic> answer,
  }) async {
    await _supabase
        .from('calls')
        .update({'answer': answer})
        .eq('id', callId);
  }

  Future<void> _endCallInSupabase(String callId) async {
    await _supabase
        .from('calls')
        .update({
          'active': false,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);
  }

  Future<void> _addIceCandidateToSupabase({
    required String callId,
    required String senderId,
    required Map<String, dynamic> candidatePlain,
  }) async {
    await _supabase.from('ice_candidates').insert({
      'call_id': callId,
      'sender_id': senderId,
      'candidate': candidatePlain,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _clearCandidatesInSupabase(String callId) async {
    await _supabase
        .from('ice_candidates')
        .delete()
        .eq('call_id', callId);
  }

  Stream<Map<String, dynamic>?> _callDocStream(String callId) {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((data) => data.isEmpty ? null : data.first);
  }

  Stream<List<Map<String, dynamic>>> _candidatesStream(
    String callId,
    bool isCaller,
  ) {
    final myId = SupabaseService().currentUser?.id ?? '';
    return _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .neq('sender_id', myId)  // ✅ اصلاح: استخدم neq بدلاً من filter
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // -------- تنظيف --------
  Future<void> dispose() async {
    await _callDocSub?.cancel();
    await _callerIceSub?.cancel();
    await _calleeIceSub?.cancel();

    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (e) {
      logger.d("⚠️ خطأ أثناء التخلص من Renderers: $e");
    }

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    await _pc?.close();

    try {
      await _stopAllTones();
      await _ringPlayer.dispose();
      await _busyPlayer.dispose();
      await _offlinePlayer.dispose();
    } catch (e) {
      logger.d("⚠️ خطأ أثناء تنظيف مشغلات الصوت: $e");
    }

    _pc = null;
    _callId = null;
    logger.i("🧹 تم تنظيف موارد CallController.");
  }
}

// -------- تشفير الإشارات --------
class _SignalCrypto {
  _SignalCrypto._(this._algo, this._key);
  final AesGcm _algo;
  final SecretKey _key;
  static final _rand = Random.secure();

  static Future<_SignalCrypto> fromSecret(List<int> sharedSecretBytes) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final keyBytes = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      info: utf8.encode('privoo-signaling-e2ee'),
    );
    final algo = AesGcm.with256bits();
    return _SignalCrypto._(algo, keyBytes);
  }

  Future<String> encryptMap(Map<String, dynamic> data) async {
    final plaintext = utf8.encode(jsonEncode(data));
    final nonce = List<int>.generate(12, (_) => _rand.nextInt(256));
    final secretBox = await _algo.encrypt(plaintext, secretKey: _key, nonce: nonce);
    final combined = [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
    return base64Encode(combined);
  }

  Future<Map<String, dynamic>> decryptToMap(String encryptedBase64) async {
    final combined = base64Decode(encryptedBase64);
    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final decryptedBytes = await _algo.decrypt(secretBox, secretKey: _key);
    return jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
  }
}