// lib/views/call/call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../controllers/call_controller.dart';
import '../../services/key_exchange_service.dart';
import 'call_controls.dart';

class CallScreen extends StatefulWidget {
  final bool isCaller;
  final String callerId;
  final String receiverId;
  final String? callIdWhenCallee; 
  final bool isVideo;
  final String title;

  const CallScreen({
    super.key,
    required this.isCaller,
    required this.callerId,
    required this.receiverId,
    this.callIdWhenCallee,
    this.isVideo = true,
    this.title = 'Privoo Call',
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallController _ctrl = CallController();
  String? _callId;
  bool _loading = true;
  bool _isVideoEnabled = false;
  bool _isMicMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _isVideoEnabled = widget.isVideo;
    _boot();
  }

  Future<void> _boot() async {
    final chatId = widget.callIdWhenCallee ?? (widget.callerId + widget.receiverId);
    final myUserId = widget.isCaller ? widget.callerId : widget.receiverId;
    final peerUserId = widget.isCaller ? widget.receiverId : widget.callerId;
    
    final keyService = KeyExchangeService();
    
    final session = await keyService.establishSession(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );
    final sharedSecretBytes = session.chatMasterKey;
    
    if (widget.isCaller) {
      _callId = await _ctrl.startCallAsCaller(
        callerId: widget.callerId,
        receiverId: widget.receiverId,
        isVideo: _isVideoEnabled,
        sharedSecretBytes: sharedSecretBytes,
      );
    } else {
      if (widget.callIdWhenCallee == null) {
        throw ArgumentError('callIdWhenCallee is required for callee flow');
      }
      await _ctrl.joinCallAsCallee(
        callId: widget.callIdWhenCallee!,
        sharedSecretBytes: sharedSecretBytes,
      );
      _callId = widget.callIdWhenCallee;
    }
    setState(() => _loading = false);
  }

  /// ✅ تحويل المكالمة الصوتية إلى فيديو (مثل Messenger)
  Future<void> _enableVideo() async {
    try {
      await _ctrl.enableVideoDuringCall();
      setState(() => _isVideoEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📹 تم تشغيل الكاميرا'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل تشغيل الكاميرا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ تحويل المكالمة الفيديو إلى صوتية
  Future<void> _disableVideo() async {
    try {
      await _ctrl.disableVideoDuringCall();
      setState(() => _isVideoEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔇 تم إيقاف الكاميرا'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل إيقاف الكاميرا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _videoViews() {
    if (_isVideoEnabled) {
      if (_ctrl.remoteRenderer.textureId == null || _ctrl.localRenderer.textureId == null) {
         return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      return Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              _ctrl.remoteRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                child: RTCVideoView(
                  _ctrl.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.white70, size: 80),
          const SizedBox(height: 20),
          Text(
            widget.isCaller ? 'جاري الاتصال بـ ${widget.receiverId}' : 'مكالمة واردة من ${widget.callerId}',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          if (!_isVideoEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton.icon(
                onPressed: _enableVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('تشغيل الكاميرا'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (_callId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  'Call ID: #$_callId',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _videoViews(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: CallControls(
              micOn: _ctrl.micEnabled,
              camOn: _ctrl.camEnabled,
              speakerOn: _ctrl.speakerOn,
              isVideoCall: _isVideoEnabled,
              onToggleMic: () async {
                await _ctrl.toggleMic();
                setState(() => _isMicMuted = !_ctrl.micEnabled);
              },
              onToggleCam: () async {
                if (_isVideoEnabled) {
                  await _ctrl.toggleCamera();
                  setState(() {});
                } else {
                  await _enableVideo();
                }
              },
              onSwitchCamera: () async => _ctrl.switchCamera(),
              onToggleSpeaker: () async {
                await _ctrl.toggleSpeaker();
                setState(() => _isSpeakerOn = !_isSpeakerOn);
              },
              onDisableVideo: _isVideoEnabled ? _disableVideo : null,
              onHangup: () async {
                await _ctrl.endCall();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}