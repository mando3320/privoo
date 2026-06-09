// lib/views/settings/encryption_info_screen.dart
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_theme_fixes.dart';

class EncryptionInfoScreen extends StatelessWidget {
  const EncryptionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'كيف نحمي بياناتك؟',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              icon: Icons.lock_outline,
              title: 'تشفير شامل (E2EE)',
              description: 'جميع رسائلك ومكالماتك مشفرة من طرف إلى طرف. لا يمكن لأي شخص، بما في ذلك Privoo، قراءة رسائلك.',
              color: AppTheme.privooBlue,
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.vpn_key,
              title: 'Double Ratchet Protocol',
              description: 'نستخدم بروتوكول Double Ratchet من Signal، الذي يغير مفاتيح التشفير كل رسالة لضمان أقصى أمان.',
              color: AppTheme.privooPurple,
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.fingerprint,
              title: 'مصادقة البصمة',
              description: 'يمكنك تفعيل مصادقة البصمة لفتح التطبيق، مما يمنع الوصول غير المصرح به.',
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.delete_sweep,
              title: 'الرسائل المختفية',
              description: 'إرسال رسائل تختفي تلقائياً بعد فترة زمنية محددة، مثل 5 ثوانٍ أو يوم.',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.verified_user,
              title: 'التحقق من الهوية',
              description: 'يمكنك التحقق من هوية جهة الاتصال الخاصة بك عن طريق مقارنة بصمة الأمان (Safety Number).',
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.privooBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.privooBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppTheme.privooBlue, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'خصوصيتك مسؤوليتنا',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'نحن لا نخزن مفاتيح التشفير الخاصة بك. أنت وحدك من يملك القدرة على قراءة رسائلك.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
