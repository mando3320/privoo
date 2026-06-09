// lib/services/export_chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportChatService {
  static Future<void> exportToJson(String chatId, List<Map<String, dynamic>> messages) async {
    final exportData = {
      'chatId': chatId,
      'exportDate': DateTime.now().toIso8601String(),
      'messages': messages,
    };
    final jsonString = jsonEncode(exportData);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'privoo_chat_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(filePath)], text: 'تصدير محادثة Privoo');
    await file.delete();
  }
}
