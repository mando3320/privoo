// views/incoming_call_screen.dart (النسخة النهائية والمعدلة)

import 'package:flutter/material.dart';

// 💡 تحويلها إلى ConsumerWidget (إذا أردت استخدام Providers للـ Call Controller مباشرة)
class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String callId;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callId,
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 استخدام ثيم داكن وواضح للمكالمات (غالباً ما تكون الشاشة سوداء/داكنة)
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface, // لون داكن
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Spacer(flex: 2),

            // 📢 نوع المكالمة والاسم
            Column(
              children: [
                Icon(
                  isVideo ? Icons.videocam : Icons.call, 
                  size: 90,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  callerName, 
                  style: const TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isVideo ? 'مكالمة فيديو واردة' : 'مكالمة صوتية واردة', 
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            
            const Spacer(flex: 3),

            // 📞 أزرار القبول والرفض
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 🛑 زر الرفض
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'reject_call',
                      backgroundColor: Colors.red,
                      onPressed: onReject,
                      child: const Icon(Icons.call_end, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('رفض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),

                // ✅ زر القبول
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'accept_call',
                      backgroundColor: Colors.green,
                      onPressed: onAccept,
                      child: const Icon(Icons.call, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('قبول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
