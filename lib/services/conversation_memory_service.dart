// services/conversation_memory_encrypted_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/encryption_service.dart';
import '../main.dart'; // logger

/// ConversationMemoryEncryptedService
/// - متوافق مع EncryptionService.encrypt/decrypt (يتوقع keyBytes طول 32)
/// - يدعم مفتاح خارجي (recommended: session/msgKey from Ratchet)
/// - لو مفيش مفتاح خارجي، يولّد مفتاح جهاز محلي ويخزنه في FlutterSecureStorage
/// - يخزن الرسائل مشفّرة كـ List<String> (كل عنصر = base64 payload من EncryptionService)
class ConversationMemoryEncryptedService {
  static const _secure = FlutterSecureStorage();
  static const _localKeyPrefix = 'conv_storage_key:'; // stores base64(32 bytes)
  static const _storagePrefix = 'conv_enc:'; // main storage per user (json list)
  static const int _defaultLimit = 50;

  /// حفظ رسالة (مشفر)
  /// - userId: معرف المستخدم المحلي (مفتاح التخزين مرتبط بالمستخدم على هذا الجهاز)
  /// - chatId: معرف المحادثة (يُستخدم كـ AAD context)
  /// - role: 'user' | 'assistant' | 'system'
  /// - text: نص الرسالة الخام (plaintext) — سيتم تشفيره قبل التخزين
  /// - keyBytes: المفتاح 32 بايت إن وُفّر (مفضل: msgKey من Ratchet/KeyExchange). إن لم يُقدَّم، سيستخدم مفتاح جهاز مُولَّد.
  static Future<void> saveMessage({
    required String userId,
    required String chatId,
    required String role,
    required String text,
    List<int>? keyBytes,
    int maxEntries = _defaultLimit,
  }) async {
    try {
      final key = keyBytes ?? await _getOrCreateLocalStorageKey(userId);

      // AAD: نستخدم chatId + role + timestamp لتوثيق السياق
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final aad = utf8.encode('$chatId|$role|$timestamp');

      final encrypted = await EncryptionService.encrypt(
        plaintext: text,
        keyBytes: key,
        aad: aad,
      ); // returns base64(payload)

      // load existing list (json array of objects: {e: <encrypted>, r:role, t:timestamp})
      final storageKey = '$_storagePrefix$userId:$chatId';
      final raw = await _secure.read(key: storageKey);
      List<Map<String, dynamic>> list;
      if (raw == null) {
        list = [];
      } else {
        list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      }

      list.add({'e': encrypted, 'r': role, 'ts': timestamp});

      // enforce limit
      if (list.length > maxEntries) {
        list = list.sublist(list.length - maxEntries);
      }

      await _secure.write(key: storageKey, value: jsonEncode(list));
    } catch (e) {
      logger.e('❌ ConversationMemoryEncryptedService.saveMessage failed: $e');
      rethrow;
    }
  }

  /// استرجاع المحادثة (تفكيك التشفير)
  /// - يعيد List<Map<String,String>> كل عنصر: { role, text, timestamp }
  static Future<List<Map<String, String>>> getConversation({
    required String userId,
    required String chatId,
    List<int>? keyBytes,
  }) async {
    try {
      final key = keyBytes ?? await _getOrCreateLocalStorageKey(userId);
      final storageKey = '$_storagePrefix$userId:$chatId';
      final raw = await _secure.read(key: storageKey);
      if (raw == null) return [];

      final listJson = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final out = <Map<String, String>>[];

      for (final item in listJson) {
        try {
          final encrypted = item['e'] as String;
          final role = item['r'] as String? ?? 'user';
          final ts = item['ts'] as String? ?? '';

          // reconstruct same AAD used during encryption (aad must match)
          // NOTE: timestamp was part of AAD, so we must use it — we saved it.
          final aad = utf8.encode('$chatId|$role|$ts');

          final plaintext = await EncryptionService.decrypt(
            encrypted: encrypted,
            keyBytes: key,
            aad: aad,
          );

          out.add({'role': role, 'text': plaintext, 'timestamp': ts});
        } catch (e) {
          // إذا فشل فك عنصر واحد — نسجل ونتخطاه (لا نكسر الباقي)
          logger.w('⚠️ فشل فك رسالة محفوظة واحدة — قد يكون key مختلف أو بيانات تالفة');
          continue;
        }
      }

      return out;
    } catch (e) {
      logger.e('❌ ConversationMemoryEncryptedService.getConversation failed: $e');
      rethrow;
    }
  }

  /// حذف محادثة محليًا
  static Future<void> clearConversation({
    required String userId,
    required String chatId,
  }) async {
    final storageKey = '$_storagePrefix$userId:$chatId';
    await _secure.delete(key: storageKey);
  }

  /// توليد أو استرجاع مفتاح التخزين المحلي (32 بايت) مخزّن مشفّر في FlutterSecureStorage
  /// هذا المفتاح جهاز-محلي فقط (not for cross-device E2EE) — يوصى باستخدام keyBytes خارجي من Ratchet.
  static Future<List<int>> _getOrCreateLocalStorageKey(String userId) async {
    final k = '$_localKeyPrefix$userId';
    final existing = await _secure.read(key: k);
    if (existing != null) {
      return base64Decode(existing);
    }
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _secure.write(key: k, value: base64Encode(bytes));
    return bytes;
  }

  /// تتيح للمستخدم تصدير المحادثة المشفّرة (JSON)
  /// مفيد للنسخ الاحتياطي: يتم تصدير الحالة المشفّرة كما هي (لا تفك التشفير هنا)
  static Future<String?> exportEncryptedConversation({
    required String userId,
    required String chatId,
  }) async {
    final storageKey = '$_storagePrefix$userId:$chatId';
    final raw = await _secure.read(key: storageKey);
    return raw; // already JSON array of {e, r, ts}
  }

  /// استيراد محادثة مشفّرة (مثلاً من BackupService)
  /// - rawExport: JSON string (كما أخرجت exportEncryptedConversation)
  /// - يحل مكان المحادثة المحلية (overwrite)
  static Future<bool> importEncryptedConversation({
    required String userId,
    required String chatId,
    required String rawExport,
  }) async {
    try {
      // basic validation
      final parsed = jsonDecode(rawExport);
      if (parsed is! List) return false;
      // write as-is
      final storageKey = '$_storagePrefix$userId:$chatId';
      await _secure.write(key: storageKey, value: jsonEncode(parsed));
      return true;
    } catch (e) {
      logger.e('❌ importEncryptedConversation failed: $e');
      return false;
    }
  }
}