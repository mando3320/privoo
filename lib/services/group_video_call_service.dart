// lib/services/group_video_call_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart';
import 'supabase_service.dart';

class GroupVideoCallService {
  // Global hard limits (absolute ceilings)
  static const int maxVideoParticipants = 50;
  static const int maxAudioParticipants = 1050;

  // Subscription-based effective limits
  static const int freeVideoMax = 3;
  static const int proVideoMax = 10;

  static int effectiveMaxParticipants({required bool isVideo, required bool isPro}) {
    if (isVideo) return isPro ? proVideoMax : freeVideoMax;
    return maxAudioParticipants;
  }
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, RTCRtpSender?> _senders = {};
  
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentCallId;
  String? _currentUserId;
  List<String> _participants = [];
  bool _isVideoCall = true;
  
  _GroupCallCrypto? _crypto;
  
  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _busyPlayer = AudioPlayer();
  bool _answered = false;
  Timer? _offlineTimer;
  
  StreamSubscription? _callDocSub;
  StreamSubscription? _offersSub;
  StreamSubscription? _answersSub;
  StreamSubscription? _iceSub;
  
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  List<String> get participants => _participants;
  bool get isInCall => _currentCallId != null;
  MediaStream? get localStream => _localStream;
  
  int getMaxParticipants(bool isVideo) {
    return isVideo ? maxVideoParticipants : maxAudioParticipants;
  }
  
  Future<void> _playIncomingTone() async {
    try {
      await _ringPlayer.setAsset('assets/audio/privoo_call.wav');
      await _ringPlayer.setLoopMode(LoopMode.one);
      await _ringPlayer.play();
      logger.i("🔔 تشغيل نغمة مكالمة جماعية واردة");
    } catch (e) {
      logger.w("⚠️ فشل تشغيل النغمة: $e");
    }
  }
  
  Future<void> _stopTones() async {
    try {
      await _ringPlayer.stop();
      await _busyPlayer.stop();
    } catch (e) {
      logger.w("⚠️ فشل إيقاف النغمات: $e");
    }
  }
  
  void _startOfflineTimer() {
    _offlineTimer = Timer(const Duration(seconds: 30), () async {
      if (!_answered) {
        await _stopTones();
        logger.i("⏱️ لم يرد أحد خلال 30 ثانية");
        await endCall();
      }
    });
  }
  
  Future<void> _initCrypto(List<int> sharedSecretBytes) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final keyBytes = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      info: utf8.encode('privoo-group-call-e2ee'),
    );
    _crypto = _GroupCallCrypto._(await keyBytes.extractBytes());
    logger.i("🔐 تم تهيئة تشفير المكالمة الجماعية");
  }
  
  Future<Map<String, dynamic>> _wrapEnc(Map<String, dynamic> plain) async {
    if (_crypto == null) return plain;
    final enc = await _crypto!.encryptMap(plain);
    return {'enc': enc};
  }
  
  Future<Map<String, dynamic>> _unwrapEnc(dynamic maybeEncField) async {
    if (_crypto == null) {
      if (maybeEncField is Map) return Map<String, dynamic>.from(maybeEncField.cast<String, dynamic>());
      return {};
    }
    if (maybeEncField is Map && maybeEncField['enc'] is String) {
      try {
        return await _crypto!.decryptToMap(maybeEncField['enc'] as String);
      } catch (e) {
        logger.e("❌ فشل فك التشفير: $e");
        return {};
      }
    }
    if (maybeEncField is Map) return Map<String, dynamic>.from(maybeEncField.cast<String, dynamic>());
    return {};
  }
  
  Future<void> _initLocalStream(bool isVideo) async {
    try {
      final constraints = {
        'audio': true,
        'video': isVideo ? {'facingMode': 'user', 'width': 480, 'height': 640} : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      logger.i("✅ تم الحصول على Local Stream (Video: $isVideo)");
    } catch (e) {
      logger.e("❌ فشل الحصول على Local Stream: $e");
      rethrow;
    }
  }
  
  Future<void> _createPeerConnection(bool isVideo) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
      if (!isVideo) 'videoReceiveEnabled': false,
    };
    
    _peerConnection = await createPeerConnection(config);
    
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        final sender = await _peerConnection!.addTrack(track, _localStream!);
        final key = track.id ?? sender.track?.id ?? track.hashCode.toString();
        _senders[key] = sender;
      }
    }
    
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty && isVideo) {
        final stream = event.streams[0];
        final streamId = stream.id;
        if (!_remoteStreams.containsKey(streamId)) {
          _remoteStreams[streamId] = stream;
          logger.i("✅ تم استقبال Remote Stream من ${event.track.id}");
        }
      }
    };
    
    _peerConnection!.onIceCandidate = (candidate) async {
      if (_currentCallId != null && candidate.candidate != null) {
        await _addIceCandidate(candidate);
      }
    };
    
    logger.i("✅ تم إنشاء Peer Connection (Video: $isVideo)");
  }
  
  Future<void> startGroupCall({
    required List<String> participantIds,
    required List<int> sharedSecretBytes,
    required String currentUserId,
    required bool isVideo,
    required bool currentUserIsPro,
  }) async {
    final maxParticipants = effectiveMaxParticipants(isVideo: isVideo, isPro: currentUserIsPro);

    if (participantIds.length + 1 > maxParticipants) {
      throw Exception('المكالمات الجماعية تدعم حتى $maxParticipants مشارك${isVideo ? " (فيديو)" : " (صوت)"}');
    }
    
    _currentUserId = currentUserId;
    _participants = [currentUserId, ...participantIds];
    _isVideoCall = isVideo;
    
    await _initCrypto(sharedSecretBytes);
    await _initLocalStream(isVideo);
    await _createPeerConnection(isVideo);
    
    _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
    await _supabase.from('group_calls').insert({
      'id': _currentCallId,
      'initiator_id': currentUserId,
      'participants': _participants,
      'is_video': isVideo,
      'active': true,
      'created_at': DateTime.now().toIso8601String(),
      'offer': null,
      'answers': {},
      'max_participants': maxParticipants,
    });
    
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    final wrappedOffer = await _wrapEnc(offer.toMap());
    
    await _supabase
        .from('group_calls')
        .update({'offer': wrappedOffer})
        .eq('id', _currentCallId!);
    
    _answersSub = _supabase
        .from('group_calls')
        .stream(primaryKey: ['id'])
        .eq('id', _currentCallId!)
        .listen((data) async {
      if (data.isEmpty) return;
      final doc = data.first;
      
      final answers = doc['answers'] as Map<String, dynamic>? ?? {};
      for (var entry in answers.entries) {
        final participantId = entry.key;
        if (participantId != currentUserId && !_senders.containsKey('answer_$participantId')) {
          final answerMap = await _unwrapEnc(entry.value);
          if (answerMap.isNotEmpty) {
            final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
            await _peerConnection!.setRemoteDescription(answer);
            _senders['answer_$participantId'] = null;
            logger.i("✅ تم استقبال Answer من $participantId");
          }
        }
      }
      
      if (doc['active'] == false) {
        await endCall();
      }
    });
    
    _iceSub = _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', _currentCallId!)
        .listen((data) async {
      for (var doc in data) {
        final fromId = doc['sender_id'] as String;
        if (fromId != currentUserId) {
          final candidateMap = await _unwrapEnc(doc['candidate']);
          if (candidateMap.isNotEmpty) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      }
    });
    
    logger.i("📹 بدأت المكالمة الجماعية $_currentCallId مع ${participantIds.length} مشارك (الحد الأقصى: $maxParticipants) - فيديو: $isVideo");
  }
  
  Future<void> joinGroupCall({
    required String callId,
    required List<int> sharedSecretBytes,
    required String currentUserId,
    required bool isVideo,
  }) async {
    _currentCallId = callId;
    _currentUserId = currentUserId;
    _isVideoCall = isVideo;
    
    await _initCrypto(sharedSecretBytes);
    await _initLocalStream(isVideo);
    await _createPeerConnection(isVideo);
    
    await _playIncomingTone();
    _startOfflineTimer();
    
    _callDocSub = _supabase
        .from('group_calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((data) async {
      if (data.isEmpty) return;
      final doc = data.first;
      
      _participants = List<String>.from(doc['participants'] ?? []);
      
      final offerField = doc['offer'];
      if (offerField != null) {
        final offerMap = await _unwrapEnc(offerField);
        if (offerMap.isNotEmpty) {
          final offer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
          await _peerConnection!.setRemoteDescription(offer);

          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          final wrappedAnswer = await _wrapEnc(answer.toMap());

          await _supabase
              .from('group_calls')
              .update({'answers.$currentUserId': wrappedAnswer})
              .eq('id', callId);

          _answered = true;
          _offlineTimer?.cancel();
          await _stopTones();
          logger.i("✅ تم الانضمام إلى المكالمة الجماعية $callId");
        }
      }
      
      if (doc['active'] == false) {
        await endCall();
      }
    });
    
    _iceSub = _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .listen((data) async {
      for (var doc in data) {
        final fromId = doc['sender_id'] as String;
        if (fromId != currentUserId) {
          final candidateMap = await _unwrapEnc(doc['candidate']);
          if (candidateMap.isNotEmpty) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      }
    });
  }
  
  Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
    if (_currentCallId == null || _currentUserId == null) return;
    
    final candidateMap = {
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
    
    final wrappedCandidate = await _wrapEnc(candidateMap);
    
    await _supabase.from('ice_candidates').insert({
      'call_id': _currentCallId,
      'sender_id': _currentUserId,
      'candidate': wrappedCandidate,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> toggleMic() async {
    final audioTrack = _localStream?.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      logger.d("🎙️ الميكروفون: ${audioTrack.enabled ? 'مفعّل' : 'مغلق'}");
    }
  }
  
  Future<void> toggleCamera() async {
    if (!_isVideoCall) return;
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      videoTrack.enabled = !videoTrack.enabled;
      logger.d("📸 الكاميرا: ${videoTrack.enabled ? 'مفعّلة' : 'مغلقة'}");
    }
  }
  
  Future<void> switchCamera() async {
    if (!_isVideoCall) return;
    for (var track in _localStream?.getVideoTracks() ?? []) {
      await Helper.switchCamera(track);
    }
    logger.d("🔄 تم تبديل الكاميرا");
  }
  
  Future<void> shareScreen() async {
    if (!_isVideoCall) return;
    try {
      final screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
      
      final videoTrack = screenStream.getVideoTracks().first;
      final sender = _senders.values.firstWhere(
        (s) => s?.track?.kind == 'video',
        orElse: () => null,
      );

      await sender?.replaceTrack(videoTrack);
      logger.i("🖥️ بدأت مشاركة الشاشة");
    } catch (e) {
      logger.e("❌ فشل مشاركة الشاشة: $e");
    }
  }
  
  Future<void> endCall() async {
    logger.i("🛑 إنهاء المكالمة الجماعية $_currentCallId");
    
    _offlineTimer?.cancel();
    await _stopTones();
    
    if (_currentCallId != null) {
      // ✅ تحقق من null قبل استخدام _currentCallId
      final callId = _currentCallId!;
      await _supabase
          .from('group_calls')
          .update({
            'active': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);
      await _clearCandidates();
    }
    
    await _callDocSub?.cancel();
    await _offersSub?.cancel();
    await _answersSub?.cancel();
    await _iceSub?.cancel();
    
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();
    
    _remoteStreams.clear();
    _senders.clear();
    _currentCallId = null;
    _participants.clear();
    
    logger.i("✅ تم إنهاء المكالمة الجماعية");
  }
  
  Future<void> _clearCandidates() async {
    if (_currentCallId == null) return;
    // ✅ تحقق من null قبل استخدام _currentCallId
    final callId = _currentCallId!;
    await _supabase
        .from('ice_candidates')
        .delete()
        .eq('call_id', callId);
  }
  
  Future<void> dispose() async {
    await endCall();
    await _ringPlayer.dispose();
    await _busyPlayer.dispose();
    logger.i("🧹 تم تنظيف GroupVideoCallService");
  }
}

class _GroupCallCrypto {
  final AesGcm _algo;
  final SecretKey _key;
  static final _rand = Random.secure();
  
  _GroupCallCrypto._(List<int> keyBytes) 
    : _algo = AesGcm.with256bits(),
      _key = SecretKey(keyBytes);
  
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