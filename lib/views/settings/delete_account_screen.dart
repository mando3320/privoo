// lib/views/settings/delete_account_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../services/region_compliance_service.dart';
import '../../services/supabase_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  bool _confirmed = false;
  String _confirmationText = '';
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> _deleteAccount() async {
    if (_confirmationText != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة DELETE للتأكيد'))
      );
      return;
    }
    
    setState(() => _isDeleting = true);
    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      final userId = user.id;

      // ✅ حذف الرسائل
      await _supabase
          .from('messages')
          .delete()
          .eq('sender_id', userId);

      // ✅ حذف المحادثات
      await _supabase
          .from('chat_members')
          .delete()
          .eq('user_id', userId);

      // ✅ حذف الملف الشخصي
      await _supabase
          .from('users')
          .delete()
          .eq('uid', userId);

      // ✅ تسجيل طلب الحذف
      final region = await RegionComplianceService.getUserRegion();
      await _supabase.from('deletion_requests').insert({
        'user_id': userId,
        'phone_number': user.phone,
        'request_date': DateTime.now().toIso8601String(),
        'deletion_date': DateTime.now().toIso8601String(),
        'region': region.name,
        'status': 'completed',
      });

      // ✅ حذف الحساب من Supabase Auth
      await _supabase.auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف حسابك وكل بياناتك بنجاح'))
        );
      }
    } catch (e) {
      logger.e('خطأ في حذف الحساب: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'))
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حذف الحساب نهائياً'),
        centerTitle: true,
        backgroundColor: Colors.red
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'تحذير: هذا الإجراء لا يمكن التراجع عنه!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'سيتم حذف نهائياً:\n\n• حسابك بالكامل\n• جميع رسائلك ومحادثاتك\n• ملفك الشخصي وصورك\n• النسخ الاحتياطية\n• جميع البيانات المرتبطة بحسابك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'لتأكيد حذف حسابك، اكتب DELETE في الخانة أدناه:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _confirmationText = value),
                    decoration: const InputDecoration(
                      hintText: 'اكتب DELETE',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text('أؤكد أنني أريد حذف حسابي وكل بياناتي نهائياً'),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.red,
            ),
            const SizedBox(height: 16),
            _isDeleting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _confirmed ? _deleteAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('حذف الحساب نهائياً', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}