// lib/services/hive_storage_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../main.dart';

class HiveStorageService {
  static const String _settingsBox = 'settings';
  static const String _messagesBox = 'messages';
  static const String _chatsBox = 'chats';
  static const String _pendingMessagesBox = 'pending_messages';
  static const String _syncBox = 'sync_status';
  
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyKey = 'hive_encryption_key';
  static HiveAesCipher? _cachedCipher;
  
  static bool _initialized = false;

  // ============================================================
  // 🚀 التهيئة
  // ============================================================
  
  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    final cipher = await _getOrCreateCipher();
    _cachedCipher = cipher;
    
    await Hive.openBox(_settingsBox, encryptionCipher: cipher);
    await Hive.openBox(_messagesBox, encryptionCipher: cipher);
    await Hive.openBox(_chatsBox, encryptionCipher: cipher);
    await Hive.openBox(_pendingMessagesBox, encryptionCipher: cipher);
    await Hive.openBox(_syncBox, encryptionCipher: cipher);
    
    _initialized = true;
    logger.i('✅ Hive Storage initialized successfully');
  }
  
  static Future<HiveAesCipher> _getOrCreateCipher() async {
    String? keyBase64 = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (keyBase64 == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final cipher = HiveAesCipher(keyBytes);
      keyBase64 = base64Encode(keyBytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: keyBase64);
      logger.i('🔐 تم توليد مفتاح تشفير جديد لـ Hive');
      return cipher;
    }
    
    return HiveAesCipher(base64Decode(keyBase64));
  }

  // ============================================================
  // ✅ التحقق من الاتصال
  // ============================================================
  
  static Future<bool> isConnected() async {
    try {
      final box = Hive.box(_syncBox);
      final lastSync = box.get('last_sync_time') as int?;
      if (lastSync != null) {
        final diff = DateTime.now().millisecondsSinceEpoch - lastSync;
        if (diff < 60000) return true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  // ============================================================
  // 📦 الإعدادات (Settings)
  // ============================================================
  
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }
  
  static dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }
  
  static Future<void> clearSettings() async {
    final box = Hive.box(_settingsBox);
    await box.clear();
  }

  // ============================================================
  // 💬 الرسائل (Messages) - Offline Support
  // ============================================================
  
  /// ✅ حفظ رسالة محلياً - إضافة chatId كمعامل
  static Future<void> saveMessage(String chatId, MessageModel message) async {
    try {
      final box = Hive.box(_messagesBox);
      final key = '${chatId}_${message.id}';  // ✅ استخدام chatId المعطى
      await box.put(key, jsonEncode(message.toJson()));
      logger.d('📦 تم حفظ الرسالة محلياً: ${message.id}');
    } catch (e) {
      logger.e('❌ فشل حفظ الرسالة محلياً: $e');
    }
  }
  
  /// ✅ حفظ رسالة معلقة - إضافة chatId كمعامل
  static Future<void> savePendingMessage(String chatId, MessageModel message) async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final key = '${chatId}_${message.id}';  // ✅ استخدام chatId المعطى
      final data = {
        ...message.toJson(),
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };
      await box.put(key, jsonEncode(data));
      logger.d('⏳ تم حفظ الرسالة المعلقة: ${message.id}');
    } catch (e) {
      logger.e('❌ فشل حفظ الرسالة المعلقة: $e');
    }
  }
  
  /// ✅ جلب كل الرسائل المعلقة لمحادثة
  static Future<List<MessageModel>> getPendingMessages(String chatId) async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final keys = box.keys.where((key) => key.toString().startsWith('${chatId}_'));  // ✅ استخدام chatId
      final messages = <MessageModel>[];
      
      for (var key in keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final message = MessageModel.fromJson(json);
            messages.add(message);
          } catch (e) {
            logger.w('⚠️ فشل فك تشفير رسالة معلقة: $e');
          }
        }
      }
      
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل المعلقة: $e');
      return [];
    }
  }
  
  /// ✅ حذف رسالة معلقة بعد إرسالها
  static Future<void> deletePendingMessage(String chatId, String messageId) async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final key = '${chatId}_$messageId';
      await box.delete(key);
      logger.d('🗑️ تم حذف الرسالة المعلقة: $messageId');
    } catch (e) {
      logger.e('❌ فشل حذف الرسالة المعلقة: $e');
    }
  }
  
  /// ✅ زيادة عدد محاولات الإرسال لرسالة معلقة
  static Future<void> incrementRetryCount(String chatId, String messageId) async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final key = '${chatId}_$messageId';
      final value = box.get(key);
      if (value == null) return;
      
      final json = jsonDecode(value.toString()) as Map<String, dynamic>;
      final retryCount = (json['retry_count'] ?? 0) + 1;
      json['retry_count'] = retryCount;
      
      await box.put(key, jsonEncode(json));
    } catch (e) {
      logger.e('❌ فشل تحديث عدد المحاولات: $e');
    }
  }
  
  /// ✅ جلب كل الرسائل المعلقة (للمزامنة)
  static Future<List<Map<String, dynamic>>> getAllPendingMessages() async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final messages = <Map<String, dynamic>>[];
      
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            json['_key'] = key.toString();
            messages.add(json);
          } catch (e) {
            logger.w('⚠️ فشل فك تشفير رسالة معلقة: $e');
          }
        }
      }
      
      return messages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل المعلقة: $e');
      return [];
    }
  }

  /// ✅ حفظ قائمة رسائل للمحادثة
  static Future<void> saveMessagesForChat(String chatId, List<MessageModel> messages) async {
    try {
      final box = Hive.box(_messagesBox);
      for (var message in messages) {
        final key = '${chatId}_${message.id}';  // ✅ استخدام chatId
        await box.put(key, jsonEncode(message.toJson()));
      }
      logger.d('📦 تم حفظ ${messages.length} رسالة للمحادثة $chatId');
    } catch (e) {
      logger.e('❌ فشل حفظ الرسائل: $e');
    }
  }
  
  /// ✅ جلب رسائل محادثة من التخزين المحلي
  static Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    try {
      final box = Hive.box(_messagesBox);
      final keys = box.keys.where((key) => key.toString().startsWith('${chatId}_'));  // ✅ استخدام chatId
      final messages = <MessageModel>[];
      
      for (var key in keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final message = MessageModel.fromJson(json);
            messages.add(message);
          } catch (e) {
            logger.w('⚠️ فشل فك تشفير رسالة: $e');
          }
        }
      }
      
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل المحلية: $e');
      return [];
    }
  }
  
  /// ✅ جلب رسالة واحدة
  static Future<MessageModel?> getMessage(String chatId, String messageId) async {
    try {
      final box = Hive.box(_messagesBox);
      final key = '${chatId}_$messageId';
      final value = box.get(key);
      if (value == null) return null;
      
      final json = jsonDecode(value.toString()) as Map<String, dynamic>;
      return MessageModel.fromJson(json);
    } catch (e) {
      logger.e('❌ فشل جلب الرسالة: $e');
      return null;
    }
  }
  
  /// ✅ حذف رسالة
  static Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final box = Hive.box(_messagesBox);
      final key = '${chatId}_$messageId';
      await box.delete(key);
      logger.d('🗑️ تم حذف الرسالة محلياً: $messageId');
    } catch (e) {
      logger.e('❌ فشل حذف الرسالة: $e');
    }
  }
  
  /// ✅ حذف كل رسائل محادثة
  static Future<void> deleteMessagesForChat(String chatId) async {
    try {
      final box = Hive.box(_messagesBox);
      final keys = box.keys.where((key) => key.toString().startsWith('${chatId}_'));  // ✅ استخدام chatId
      await box.deleteAll(keys);
      logger.d('🗑️ تم حذف كل رسائل المحادثة $chatId');
    } catch (e) {
      logger.e('❌ فشل حذف الرسائل: $e');
    }
  }
  
  /// ✅ التحقق من وجود رسائل محلية لمحادثة
  static Future<bool> hasMessagesForChat(String chatId) async {
    try {
      final box = Hive.box(_messagesBox);
      final keys = box.keys.where((key) => key.toString().startsWith('${chatId}_'));
      return keys.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// ✅ عدد الرسائل في محادثة
  static Future<int> getMessageCountForChat(String chatId) async {
    try {
      final box = Hive.box(_messagesBox);
      final keys = box.keys.where((key) => key.toString().startsWith('${chatId}_'));
      return keys.length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // 📋 المحادثات (Chats) - Offline Support
  // ============================================================
  
  static Future<void> saveChat(ChatModel chat) async {
    try {
      final box = Hive.box(_chatsBox);
      await box.put(chat.chatId, jsonEncode(chat.toJson()));
      logger.d('📋 تم حفظ المحادثة محلياً: ${chat.chatId}');
    } catch (e) {
      logger.e('❌ فشل حفظ المحادثة: $e');
    }
  }
  
  static Future<ChatModel?> getChat(String chatId) async {
    try {
      final box = Hive.box(_chatsBox);
      final value = box.get(chatId);
      if (value == null) return null;
      
      final json = jsonDecode(value.toString()) as Map<String, dynamic>;
      return ChatModel.fromJson(json);
    } catch (e) {
      logger.e('❌ فشل جلب المحادثة: $e');
      return null;
    }
  }
  
  static Future<List<ChatModel>> getAllChats() async {
    try {
      final box = Hive.box(_chatsBox);
      final chats = <ChatModel>[];
      
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final chat = ChatModel.fromJson(json);
            chats.add(chat);
          } catch (e) {
            logger.w('⚠️ فشل فك تشفير محادثة: $e');
          }
        }
      }
      
      chats.sort((a, b) => (b.lastMessageTime ?? b.createdAt)
          .compareTo(a.lastMessageTime ?? a.createdAt));
      return chats;
    } catch (e) {
      logger.e('❌ فشل جلب المحادثات: $e');
      return [];
    }
  }
  
  static Future<void> deleteChat(String chatId) async {
    try {
      final box = Hive.box(_chatsBox);
      await box.delete(chatId);
      await deleteMessagesForChat(chatId);
      logger.d('🗑️ تم حذف المحادثة محلياً: $chatId');
    } catch (e) {
      logger.e('❌ فشل حذف المحادثة: $e');
    }
  }

  // ============================================================
  // 🔄 مزامنة البيانات
  // ============================================================
  
  static Future<void> updateLastSyncTime() async {
    try {
      final box = Hive.box(_syncBox);
      await box.put('last_sync_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      logger.e('❌ فشل تحديث وقت المزامنة: $e');
    }
  }
  
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final box = Hive.box(_syncBox);
      final time = box.get('last_sync_time') as int?;
      if (time == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(time);
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> syncMessages(String chatId, List<MessageModel> serverMessages) async {
    try {
      final localMessages = await getMessagesForChat(chatId);
      final localIds = localMessages.map((m) => m.id).toSet();
      
      int addedCount = 0;
      for (var message in serverMessages) {
        if (!localIds.contains(message.id)) {
          await saveMessage(chatId, message);  // ✅ تمرير chatId
          addedCount++;
        }
      }
      
      await updateLastSyncTime();
      logger.d('🔄 تمت مزامنة $addedCount رسالة جديدة للمحادثة $chatId');
    } catch (e) {
      logger.e('❌ فشل مزامنة الرسائل: $e');
    }
  }
  
  static Future<void> syncChats(List<ChatModel> serverChats) async {
    try {
      for (var chat in serverChats) {
        await saveChat(chat);
      }
      await updateLastSyncTime();
      logger.d('🔄 تمت مزامنة ${serverChats.length} محادثة');
    } catch (e) {
      logger.e('❌ فشل مزامنة المحادثات: $e');
    }
  }
  
  static Future<List<MessageModel>> getPendingMessagesToSend() async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final messages = <MessageModel>[];
      
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final retryCount = json['retry_count'] ?? 0;
            if (retryCount < 5) {
              final message = MessageModel.fromJson(json);
              messages.add(message);
            }
          } catch (e) {
            logger.w('⚠️ فشل فك تشفير رسالة معلقة: $e');
          }
        }
      }
      
      return messages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل المعلقة للإرسال: $e');
      return [];
    }
  }

  // ============================================================
  // 📊 حالة التطبيق (App State)
  // ============================================================
  
  static Future<void> saveAppState(Map<String, dynamic> state) async {
    try {
      final box = Hive.box(_settingsBox);
      await box.put('app_state', jsonEncode(state));
    } catch (e) {
      logger.e('❌ فشل حفظ حالة التطبيق: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> getAppState() async {
    try {
      final box = Hive.box(_settingsBox);
      final value = box.get('app_state');
      if (value == null) return null;
      return jsonDecode(value.toString()) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> saveCurrentUserId(String userId) async {
    await saveSetting('current_user_id', userId);
  }
  
  static String? getCurrentUserId() {
    return getSetting('current_user_id') as String?;
  }

  // ============================================================
  // 🗑️ تنظيف
  // ============================================================
  
  static Future<void> clearAllData() async {
    try {
      final messagesBox = Hive.box(_messagesBox);
      final chatsBox = Hive.box(_chatsBox);
      final pendingBox = Hive.box(_pendingMessagesBox);
      final syncBox = Hive.box(_syncBox);
      
      await messagesBox.clear();
      await chatsBox.clear();
      await pendingBox.clear();
      await syncBox.clear();
      
      logger.i('🧹 تم حذف كل البيانات المحلية');
    } catch (e) {
      logger.e('❌ فشل حذف البيانات: $e');
    }
  }
  
  static Future<void> cleanOldData({int keepDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      final box = Hive.box(_messagesBox);
      
      final keysToDelete = <String>[];
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final timestamp = DateTime.tryParse(json['timestamp'] ?? '');
            if (timestamp != null && timestamp.isBefore(cutoffDate)) {
              keysToDelete.add(key.toString());
            }
          } catch (e) {
            // تجاهل
          }
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        logger.i('🧹 تم حذف ${keysToDelete.length} رسالة قديمة');
      }
    } catch (e) {
      logger.e('❌ فشل تنظيف البيانات القديمة: $e');
    }
  }
  
  static Future<void> cleanFailedPendingMessages() async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final keysToDelete = <String>[];
      
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            final json = jsonDecode(value.toString()) as Map<String, dynamic>;
            final retryCount = json['retry_count'] ?? 0;
            if (retryCount >= 5) {
              keysToDelete.add(key.toString());
            }
          } catch (e) {
            // تجاهل
          }
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        logger.i('🧹 تم حذف ${keysToDelete.length} رسالة معلقة فاشلة');
      }
    } catch (e) {
      logger.e('❌ فشل تنظيف الرسائل المعلقة: $e');
    }
  }

  // ============================================================
  // 📝 سجلات (Logs) - للتشخيص
  // ============================================================
  
  static Future<Map<String, int>> getStorageSize() async {
    try {
      final messagesBox = Hive.box(_messagesBox);
      final chatsBox = Hive.box(_chatsBox);
      final pendingBox = Hive.box(_pendingMessagesBox);
      
      return {
        'messages': messagesBox.length,
        'chats': chatsBox.length,
        'pending': pendingBox.length,
      };
    } catch (e) {
      return {};
    }
  }
}