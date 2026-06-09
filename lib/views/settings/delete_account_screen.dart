// lib/views/settings/delete_account_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/region_compliance_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  bool _confirmed = false;
  String _confirmationText = '';
  
  Future<void> _deleteAccount() async {
    if (_confirmationText != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة DELETE للتأكيد')));
      return;
    }
    setState(() => _isDeleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      final userId = user.uid;
      final chatsQuery = await FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: userId).get();
      for (var chatDoc in chatsQuery.docs) {
        final messages = await chatDoc.reference.collection('messages').where('senderId', isEqualTo: userId).get();
        for (var msgDoc in messages.docs) {
          await msgDoc.reference.delete();
        }
      }
      final backups = await FirebaseFirestore.instance.collection('backups').doc(userId).collection('versions').get();
      for (var doc in backups.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance.collection('keys').doc(userId).delete();
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      final region = await RegionComplianceService.getUserRegion();
      await FirebaseFirestore.instance.collection('deletion_requests').add({ 'userId': userId, 'phoneNumber': user.phoneNumber, 'requestDate': FieldValue.serverTimestamp(), 'deletionDate': DateTime.now(), 'region': region.name, 'status': 'completed' });
      await user.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حذف حسابك وكل بياناتك بنجاح')));
      }
    } catch (e) {
      logger.e('خطأ في حذف الحساب: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
    } finally { setState(() => _isDeleting = false); }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حذف الحساب نهائياً'), centerTitle: true, backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text('تحذير: هذا الإجراء لا يمكن التراجع عنه!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('سيتم حذف نهائياً:\n\n• حسابك بالكامل\n• جميع رسائلك ومحادثاتك\n• ملفك الشخصي وصورك\n• النسخ الاحتياطية\n• جميع البيانات المرتبطة بحسابك', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Column(
                children: [
                  const Text('لتأكيد حذف حسابك، اكتب DELETE في الخانة أدناه:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(onChanged: (value) => setState(() => _confirmationText = value), decoration: const InputDecoration(hintText: 'اكتب DELETE', border: OutlineInputBorder()), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CheckboxListTile(value: _confirmed, onChanged: (value) => setState(() => _confirmed = value ?? false), title: const Text('أؤكد أنني أريد حذف حسابي وكل بياناتي نهائياً'), controlAffinity: ListTileControlAffinity.leading, activeColor: Colors.red),
            const SizedBox(height: 16),
            _isDeleting ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _confirmed ? _deleteAccount : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('حذف الحساب نهائياً', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
