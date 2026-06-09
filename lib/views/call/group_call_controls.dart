// lib/views/call/group_call_controls.dart
import 'package:flutter/material.dart';

class GroupCallControls extends StatefulWidget {
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCam;
  final VoidCallback onSwitchCamera;
  final VoidCallback onShareScreen;
  final VoidCallback onHangup;

  const GroupCallControls({
    super.key,
    required this.onToggleMic,
    required this.onToggleCam,
    required this.onSwitchCamera,
    required this.onShareScreen,
    required this.onHangup,
  });

  @override
  State<GroupCallControls> createState() => _GroupCallControlsState();
}

class _GroupCallControlsState extends State<GroupCallControls> {
  bool micOn = true;
  bool camOn = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 🎤 ميكروفون
          _controlButton(
            icon: micOn ? Icons.mic : Icons.mic_off,
            bgColor: micOn ? Colors.grey : Colors.red,
            onTap: () {
              setState(() => micOn = !micOn);
              widget.onToggleMic();
            },
          ),
          // 📹 كاميرا
          _controlButton(
            icon: camOn ? Icons.videocam : Icons.videocam_off,
            bgColor: camOn ? Colors.grey : Colors.red,
            onTap: () {
              setState(() => camOn = !camOn);
              widget.onToggleCam();
            },
          ),
          // 🔄 تبديل الكاميرا
          _controlButton(
            icon: Icons.cameraswitch,
            bgColor: Colors.grey,
            onTap: widget.onSwitchCamera,
          ),
          // 🖥️ مشاركة شاشة
          _controlButton(
            icon: Icons.screen_share,
            bgColor: Colors.grey,
            onTap: widget.onShareScreen,
          ),
          // 🔴 إنهاء
          _controlButton(
            icon: Icons.call_end,
            bgColor: Colors.red,
            onTap: widget.onHangup,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}