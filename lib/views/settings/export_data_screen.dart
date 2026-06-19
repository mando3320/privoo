// lib/views/settings/export_data_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../main.dart';
import '../../services/region_compliance_service.dart';
import '../../services/supabase_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _isExporting = false;
  String _exportStatus = '';
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> _exportUserData() async {
    setState(() { _isExporting = true; _exportStatus = 'جمع البيانات...'; });
    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      
      setState(() => _exportStatus = 'جمع بيانات الملف الشخصي...');
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle();
      
      setState(() => _exportStatus = 'جمع المحادثات...');
      final chatsResponse = await _supabase
          .from('chats')
          .select()
          .contains('participants', user.id);
      
      final allMessages = <Map<String, dynamic>>[];
      for (var chat in chatsResponse) {
        final messages = await _supabase
            .from('messages')
            .select()
            .eq('chat_id', chat['id'])
            .order('timestamp', ascending: true);
        for (var msg in messages) {
          allMessages.add({
            'chatId': chat['id'],
            'messageId': msg['id'],
            ...msg,
          });
        }
      }
      
      setState(() => _exportStatus = 'جمع النسخ الاحتياطية...');
      final backups = await _supabase
          .from('backups')
          .select()
          .eq('user_id', user.id);
      
      setState(() => _exportStatus = 'جمع الإعدادات...');
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final settings = <String, dynamic>{};
      for (var key in allKeys) { settings[key] = prefs.get(key); }
      
      setState(() => _exportStatus = 'إنشاء ملف التصدير...');
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'user': {
          'uid': user.id,
          'phoneNumber': user.phone,
          'email': user.email,
          'profile': userResponse,
        },
        'chats': chatsResponse,
        'messages': allMessages,
        'backups': backups,
        'localSettings': settings,
        'region': (await RegionComplianceService.getUserRegion()).name,
      };
      
      final jsonString = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'privoo_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      await _supabase.from('data_exports').insert({
        'user_id': user.id,
        'export_date': DateTime.now().toIso8601String(),
        'file_name': fileName,
        'file_size': jsonString.length,
      });
      
      setState(() => _exportStatus = '✅ تم التصدير بنجاح!');
      await Share.shareXFiles([XFile(filePath)], text: 'تصدير بياناتي من Privoo بتاريخ ${DateTime.now().toLocal()}');
      await file.delete();
    } catch (e) {
      logger.e('خطأ في تصدير البيانات: $e');
      setState(() => _exportStatus = '❌ خطأ: $e');
    } finally {
      setState(() => _isExporting = false);
    }
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
              ElevatedButton.icon(
                onPressed: _exportUserData,
                icon: const Icon(Icons.download),
                label: const Text('بدء التصدير'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            if (_exportStatus.isNotEmpty && !_isExporting)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _exportStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _exportStatus.contains('✅') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}