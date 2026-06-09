// views/auth/invite_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteScreen extends StatelessWidget {
  final String phoneNumber;
  final String name;
  
  const InviteScreen({
    super.key,
    this.phoneNumber = '',
    this.name = '',
  });

  static const String inviteLink = 'https://privoo.app/download';

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : 'صديق';
    final message = 'انضم إلى Privoo لتتواصل مع $displayName: $inviteLink';
    
    return Scaffold(
      appBar: AppBar(title: const Text('دعوة مستخدم'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            
            // أيقونة
            const Icon(Icons.people_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            
            // نص الدعوة
            Text(
              'ادعُ $displayName إلى Privoo',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Text(
              phoneNumber.isNotEmpty ? 'رقم الهاتف: $phoneNumber' : '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // شرح
            const Text(
              'شارك هذا الرابط مع صديقك لتحميل التطبيق والانضمام إليك',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // رابط التحميل
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                inviteLink,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            
            // زر مشاركة الدعوة
            ElevatedButton.icon(
              onPressed: () => Share.share(message),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الدعوة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // زر إرسال رسالة نصية (إذا كان رقم الهاتف موجوداً)
            if (phoneNumber.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  final smsUri = Uri.parse('sms:$phoneNumber?body=$message');
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا يمكن إرسال رسالة نصية')),
                    );
                  }
                },
                icon: const Icon(Icons.message),
                label: const Text('إرسال رسالة نصية'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // زر رجوع
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}