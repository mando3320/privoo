// lib/views/call/call_controls.dart
import 'package:flutter/material.dart';

class CallControls extends StatelessWidget {
  final bool micOn;
  final bool camOn;
  final bool speakerOn;
  final bool isVideoCall;
  
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCam;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final VoidCallback? onDisableVideo;
  final VoidCallback onHangup;

  const CallControls({
    super.key,
    required this.micOn,
    required this.camOn,
    required this.speakerOn,
    required this.isVideoCall,
    required this.onToggleMic,
    required this.onToggleCam,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    this.onDisableVideo,
    required this.onHangup,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    const inactiveColor = Colors.grey;
    const backgroundColor = Colors.white24;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 🎤 الميكروفون
          _controlButton(
            icon: micOn ? Icons.mic : Icons.mic_off,
            color: activeColor,
            bg: micOn ? backgroundColor : Colors.red,
            onTap: onToggleMic,
          ),
          
          // 📹 الكاميرا (تشغيل/إيقاف)
          _controlButton(
            icon: camOn ? Icons.videocam : Icons.videocam_off,
            color: activeColor,
            bg: camOn ? backgroundColor : Colors.red,
            onTap: onToggleCam,
          ),

          // 🔄 تبديل الكاميرا (يظهر فقط في مكالمات الفيديو)
          if (isVideoCall)
            _controlButton(
              icon: Icons.cameraswitch,
              color: activeColor,
              bg: backgroundColor,
              onTap: onSwitchCamera,
            ),
          
          // 🔇 إيقاف الفيديو (يظهر فقط في مكالمات الفيديو)
          if (isVideoCall && onDisableVideo != null)
            _controlButton(
              icon: Icons.videocam_off,
              color: Colors.red,
              bg: backgroundColor,
              onTap: onDisableVideo!,
            ),
          
          // 🔊 مكبر الصوت
          _controlButton(
            icon: speakerOn ? Icons.volume_up : Icons.volume_down,
            color: speakerOn ? activeColor : inactiveColor,
            bg: speakerOn ? backgroundColor : Colors.white10,
            onTap: onToggleSpeaker,
          ),
          
          // 🛑 إنهاء المكالمة
          _controlButton(
            icon: Icons.call_end,
            color: Colors.white,
            bg: Colors.red.shade700,
            onTap: onHangup,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    Color? bg,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 30,
          child: CircleAvatar(
            backgroundColor: bg ?? Colors.white10,
            radius: 30,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}