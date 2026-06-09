// lib/views/settings/export_data_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../main.dart';
import '../../services/region_compliance_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _isExporting = false;
  String _exportStatus = '';
  
  Future<void> _exportUserData() async {
    setState(() { _isExporting = true; _exportStatus = 'جمع البيانات...'; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      setState(() => _exportStatus = 'جمع بيانات الملف الشخصي...');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() => _exportStatus = 'جمع المحادثات...');
      final chatsQuery = await FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: user.uid).get();
      final List<Map<String, dynamic>> allMessages = [];
      for (var chatDoc in chatsQuery.docs) {
        final messages = await chatDoc.reference.collection('messages').orderBy('timestamp').get();
        for (var msgDoc in messages.docs) { allMessages.add({ 'chatId': chatDoc.id, 'messageId': msgDoc.id, ...msgDoc.data() }); }
      }
      setState(() => _exportStatus = 'جمع النسخ الاحتياطية...');
      final backups = await FirebaseFirestore.instance.collection('backups').doc(user.uid).collection('versions').get();
      setState(() => _exportStatus = 'جمع الإعدادات...');
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final settings = <String, dynamic>{};
      for (var key in allKeys) { settings[key] = prefs.get(key); }
      setState(() => _exportStatus = 'إنشاء ملف التصدير...');
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'user': { 'uid': user.uid, 'phoneNumber': user.phoneNumber, 'email': user.email, 'profile': userDoc.data() },
        'chats': chatsQuery.docs.map((doc) => ({ 'chatId': doc.id, 'participants': doc.data()['participants'], 'createdAt': doc.data()['createdAt'] })).toList(),
        'messages': allMessages,
        'backups': backups.docs.map((doc) => doc.data()).toList(),
        'localSettings': settings,
        'region': (await RegionComplianceService.getUserRegion()).name,
      };
      final jsonString = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'privoo_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      await FirebaseFirestore.instance.collection('data_exports').add({ 'userId': user.uid, 'exportDate': FieldValue.serverTimestamp(), 'fileName': fileName, 'fileSize': jsonString.length });
      setState(() => _exportStatus = '✅ تم التصدير بنجاح!');
      await Share.shareXFiles([XFile(filePath)], text: 'تصدير بياناتي من Privoo بتاريخ ${DateTime.now().toLocal()}');
      await file.delete();
    } catch (e) {
      logger.e('خطأ في تصدير البيانات: $e');
      setState(() => _exportStatus = '❌ خطأ: $e');
    } finally { setState(() => _isExporting = false); }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصدير بياناتي'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.download_for_offline, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('تصدير جميع بياناتك الشخصية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('سيتم إنشاء ملف JSON يحتوي على:\n• معلومات حسابك الشخصية\n• سجل المحادثات (مشفر محلياً)\n• النسخ الاحتياطية\n• إعدادات التطبيق', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            if (_isExporting)
              Column(children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_exportStatus)])
            else
              ElevatedButton.icon(onPressed: _exportUserData, icon: const Icon(Icons.download), label: const Text('بدء التصدير'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green)),
            if (_exportStatus.isNotEmpty && !_isExporting) Padding(padding: const EdgeInsets.only(top: 24), child: Text(_exportStatus, textAlign: TextAlign.center, style: TextStyle(color: _exportStatus.contains('✅') ? Colors.green : Colors.red))),
          ],
        ),
      ),
    );
  }
}
