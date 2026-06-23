// lib/views/call/group_call_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/group_video_call_service.dart';
import '../../services/key_exchange_service.dart';
import '../../controllers/app_controller.dart';
import 'group_call_controls.dart';

class GroupCallScreen extends ConsumerStatefulWidget {
  final bool isInitiator;
  final String groupId;
  final String callId;
  final List<String> participantIds;
  final String currentUserId;
  final bool isVideo;

  const GroupCallScreen({
    super.key,
    required this.isInitiator,
    required this.groupId,
    required this.callId,
    required this.participantIds,
    required this.currentUserId,
    this.isVideo = true,
  });

  @override
  ConsumerState<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  final GroupVideoCallService _callService = GroupVideoCallService();
  bool _loading = true;
  bool _isMuted = false;
  bool _isCameraOff = false;
  int _participantCount = 0;
  String _callStatus = 'جاري الاتصال...';
  bool _isSpeakerOn = false;
  
  // ✅ متغيرات لعرض الفيديو
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      final chatId = widget.groupId;
      final keyService = KeyExchangeService();
      
      final peerId = widget.participantIds.isNotEmpty 
          ? widget.participantIds.first 
          : widget.currentUserId;
      
      final session = await keyService.establishSession(
        chatId: chatId,
        myUserId: widget.currentUserId,
        peerUserId: peerId,
      );
      final sharedSecretBytes = session.chatMasterKey;
      
      final app = ref.read(appControllerProvider);
      
      // ✅ تهيئة الـ Renderers
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      
      if (widget.isInitiator) {
        await _callService.startGroupCall(
          participantIds: widget.participantIds,
          sharedSecretBytes: sharedSecretBytes,
          currentUserId: widget.currentUserId,
          isVideo: widget.isVideo,
          currentUserIsPro: app.isPro,
        );
        setState(() {
          _participantCount = widget.participantIds.length + 1;
          _callStatus = 'المكالمة جارية';
        });
      } else {
        await _callService.joinGroupCall(
          callId: widget.callId,
          sharedSecretBytes: sharedSecretBytes,
          currentUserId: widget.currentUserId,
          isVideo: widget.isVideo,
        );
        setState(() {
          _participantCount = _callService.participants.length;
          _callStatus = 'انضممت إلى المكالمة';
        });
      }
      
      // ✅ ربط الـ Local Stream بالـ Renderer
      if (_callService.localStream != null) {
        _localRenderer!.srcObject = _callService.localStream;
      }
      
    } catch (e) {
      print('❌ خطأ في بدء المكالمة الجماعية: $e');
      setState(() {
        _callStatus = 'فشل الاتصال';
        _loading = false;
      });
    }
    
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _localRenderer?.dispose();
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    _remoteRenderers.clear();
    _callService.dispose();
    super.dispose();
  }

  String _formatParticipantCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// ✅ دالة مساعدة لبناء فيديو المشارك البعيد
  Widget _buildRemoteVideo(String participantId) {
    // ✅ إنشاء Renderer جديد إذا لم يكن موجوداً
    if (!_remoteRenderers.containsKey(participantId)) {
      final renderer = RTCVideoRenderer();
      renderer.initialize();
      final stream = _callService.remoteStreams[participantId];
      if (stream != null) {
        renderer.srcObject = stream;
      }
      _remoteRenderers[participantId] = renderer;
    }
    
    return RTCVideoView(
      _remoteRenderers[participantId]!,
      mirror: false,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _buildVideoGrid() {
    final participants = _callService.participants;
    final remoteStreams = _callService.remoteStreams;
    
    int crossAxisCount = 1;
    double childAspectRatio = 0.75;
    
    if (participants.length <= 2) {
      crossAxisCount = 1;
      childAspectRatio = 0.75;
    } else if (participants.length <= 6) {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
    } else if (participants.length <= 12) {
      crossAxisCount = 3;
      childAspectRatio = 0.65;
    } else if (participants.length <= 20) {
      crossAxisCount = 4;
      childAspectRatio = 0.6;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 0.55;
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participantId = participants[index];
        final isMe = participantId == widget.currentUserId;
        
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Stack(
            children: [
              // ✅ عرض الفيديو المحلي
              if (widget.isVideo && isMe && _localRenderer != null)
                RTCVideoView(
                  _localRenderer!,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              // ✅ عرض الفيديو البعيد - استخدام الدالة المساعدة
              else if (widget.isVideo && remoteStreams.containsKey(participantId))
                _buildRemoteVideo(participantId)
              // ✅ عرض أيقونة للمشاركين بدون فيديو
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: participants.length > 20 ? 30 : 50,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 8),
                      if (!widget.isVideo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'يتحدث',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isVideo && !isMe)
                        const Icon(Icons.mic, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        isMe ? 'أنت' : participantId.substring(0, 6),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe && _isMuted)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.mic_off, size: 16, color: Colors.white),
                  ),
                ),
              if (widget.isVideo && isMe && _isCameraOff)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.videocam_off, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioOnly() {
    final participants = _callService.participants;
    
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participantId = participants[index];
        final isMe = participantId == widget.currentUserId;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isMe ? Colors.green : Colors.blue,
            child: Text(
              isMe ? 'أنا' : participantId.substring(0, 2).toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            isMe ? 'أنت' : 'مستخدم',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            participantId,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          trailing: Icon(
            Icons.mic,
            color: Colors.green,
            size: 20,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final maxParticipants = GroupVideoCallService.effectiveMaxParticipants(
      isVideo: widget.isVideo, 
      isPro: app.isPro,
    );
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.isVideo ? 'مكالمة فيديو جماعية' : 'مكالمة صوتية جماعية',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '👥 ${_formatParticipantCount(_participantCount)} / ${_formatParticipantCount(maxParticipants)} مشارك',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VIP ${_participantCount > 1000 ? '1000+' : _participantCount}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري الاتصال...', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: widget.isVideo
                      ? _buildVideoGrid()
                      : _buildAudioOnly(),
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isVideo ? Icons.videocam : Icons.call,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _callStatus,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: GroupCallControls(
                    onToggleMic: () async {
                      await _callService.toggleMic();
                      setState(() => _isMuted = !_isMuted);
                    },
                    onToggleCam: () async {
                      if (widget.isVideo) {
                        await _callService.toggleCamera();
                        setState(() => _isCameraOff = !_isCameraOff);
                      }
                    },
                    onSwitchCamera: () => _callService.switchCamera(),
                    onShareScreen: () => _callService.shareScreen(),
                    onHangup: () async {
                      await _callService.endCall();
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ),
                if (!widget.isVideo && _participantCount > 100)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatParticipantCount(_participantCount)} مستمع',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}