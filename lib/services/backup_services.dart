// services/backup_services.dart
// services/backup_service.dart (الإصدار النهائي المعدل)
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import '../models/message_model.dart';
import '../services/ratchet_service.dart';
import '../main.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _secureStorage = const FlutterSecureStorage();
  static const _localKeyPrefix = 'e2ee_backup_';
  // backup meta key (kept for compatibility) — not referenced directly

  static final _algo = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static const _deviceSecretKey = 'privoo.device.backup.mac';

  Future<void> backupUserChats({
    required String userId,
    required List<MessageModel> messages,
    required List<int> backupKey,
    String? chatIdForRatchetExport,
    Map<String, dynamic>? metadata,
  }) async {
    final backupData = <String, dynamic>{
      'protocolVersion': 3,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'meta': metadata ?? {},
    };

    if (chatIdForRatchetExport != null) {
      try {
        final ratchetJson = await RatchetService.exportState(
          chatId: chatIdForRatchetExport,
          myUserId: userId,
        );
        if (ratchetJson != null) {
          backupData['ratchetState'] = ratchetJson;
        }
      } catch (e) {
        logger.e('❌ خطأ أثناء تصدير حالة الراشِت: $e');
      }
    }

    final jsonString = jsonEncode(backupData);

    try {
      final encKeyBytes = await _deriveBackupEncryptionKey(backupKey, userId);
      final secretKey = SecretKey(encKeyBytes);
      final nonce = _randomNonce(12);
      final aad = utf8.encode('backup:$userId:v3');

      final secretBox = await _algo.encrypt(
        utf8.encode(jsonString),
        secretKey: secretKey,
        nonce: nonce,
        aad: aad,
      );

      final encryptedPayload = {
        'n': base64Encode(nonce),
        'c': base64Encode(secretBox.cipherText),
        't': base64Encode(secretBox.mac.bytes),
        'alg': 'AES-GCM-256',
        'v': 3,
      };

      final deviceMac = await _computeDeviceBackupMac(utf8.encode(jsonString));

      final versionsRef = _firestore.collection('backups').doc(userId).collection('versions');
      final ts = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

      await versionsRef.doc(ts).set({
        'encrypted_data': encryptedPayload,
        'created_at': FieldValue.serverTimestamp(),
        'meta': metadata ?? {},
        'version': 3,
        'device_mac': base64Encode(deviceMac),
      });

      final localWrapper = jsonEncode({
        'payload': encryptedPayload,
        'device_mac': base64Encode(deviceMac),
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _secureStorage.write(key: '$_localKeyPrefix$userId', value: localWrapper);
      logger.i('✅ النسخة الاحتياطية تم حفظها بنجاح للمستخدم $userId');
    } catch (e, st) {
      logger.e('❌ فشل إنشاء النسخة الاحتياطية: $e\n$st');
      rethrow;
    }
  }

  Future<List<MessageModel>> restoreUserChats({
    required String userId,
    required List<int> backupKey,
    String? versionTimestamp,
    bool importRatchetState = true,
  }) async {
    String? encryptedPayloadJson;
    String? deviceMacB64;

    try {
      final versionsRef = _firestore.collection('backups').doc(userId).collection('versions');
      DocumentSnapshot<Map<String, dynamic>>? doc;
      
      if (versionTimestamp != null) {
        doc = await versionsRef.doc(versionTimestamp).get();
      } else {
        final q = await versionsRef.orderBy('created_at', descending: true).limit(1).get();
        if (q.docs.isNotEmpty) {
          doc = q.docs.first;
        }
      }

      if (doc != null && doc.exists && doc.data()!['encrypted_data'] != null) {
        final enc = doc.data()!['encrypted_data'] as Map<String, dynamic>;
        encryptedPayloadJson = jsonEncode(enc);
        deviceMacB64 = doc.data()!['device_mac'] as String?;
      }
    } catch (e) {
      logger.e('❌ فشل استرجاع النسخة الاحتياطية من Firestore: $e');
    }

    if (encryptedPayloadJson == null) {
      try {
        final local = await _secureStorage.read(key: '$_localKeyPrefix$userId');
        if (local != null) {
          final wrapper = jsonDecode(local) as Map<String, dynamic>;
          final payload = wrapper['payload'];
          encryptedPayloadJson = jsonEncode(payload);
          deviceMacB64 = wrapper['device_mac'] as String?;
        }
      } catch (e) {
        logger.e('❌ فشل قراءة النسخة المحلية: $e');
      }
    }

    if (encryptedPayloadJson == null) {
      logger.w('⚠️ لا توجد نسخة احتياطية للمستخدم $userId');
      return [];
    }

    return await _decryptAndRestore(
      encryptedPayloadJson: encryptedPayloadJson,
      deviceMacB64: deviceMacB64,
      userId: userId,
      backupKey: backupKey,
      importRatchetState: importRatchetState,
    );
  }

  Future<void> autoBackupAllChats(String userId, List<int> backupKey) async {
    final chatsSnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();
    
    int backedUp = 0;
    for (var chatDoc in chatsSnapshot.docs) {
      final messagesSnapshot = await chatDoc.reference
          .collection('messages')
          .orderBy('timestamp')
          .get();
      
      final messages = messagesSnapshot.docs
          .map((doc) => MessageModel.fromDoc(doc))
          .toList();
      
      if (messages.isNotEmpty) {
        await backupUserChats(
          userId: userId,
          messages: messages,
          backupKey: backupKey,
          chatIdForRatchetExport: chatDoc.id,
        );
        backedUp++;
      }
    }
    
    logger.i('✅ تم إجراء نسخ احتياطي تلقائي لـ $backedUp محادثة للمستخدم $userId');
  }

  Future<List<MessageModel>> restoreLatestBackup(
    String userId, 
    List<int> backupKey,
  ) async {
    final versionsRef = _firestore
        .collection('backups')
        .doc(userId)
        .collection('versions');
    
    final snapshot = await versionsRef
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      logger.w('⚠️ لا توجد نسخ احتياطية للمستخدم $userId');
      return [];
    }
    
    return await restoreUserChats(
      userId: userId,
      backupKey: backupKey,
      versionTimestamp: snapshot.docs.first.id,
    );
  }

  Future<void> cleanOldBackups(String userId, {int keepDays = 30}) async {
    final versionsRef = _firestore
        .collection('backups')
        .doc(userId)
        .collection('versions');
    
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    
    final oldBackups = await versionsRef
        .where('created_at', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();
    
    final batch = _firestore.batch();
    for (var doc in oldBackups.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    logger.i('🧹 تم حذف ${oldBackups.docs.length} نسخة احتياطية قديمة للمستخدم $userId');
  }

  Future<void> deleteAllBackups(String userId) async {
    final versionsRef = _firestore
        .collection('backups')
        .doc(userId)
        .collection('versions');
    
    final allBackups = await versionsRef.get();
    final batch = _firestore.batch();
    for (var doc in allBackups.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    await _secureStorage.delete(key: '$_localKeyPrefix$userId');
    
    logger.i('🗑️ تم حذف جميع النسخ الاحتياطية للمستخدم $userId');
  }

  Future<List<MessageModel>> _decryptAndRestore({
    required String encryptedPayloadJson,
    required String? deviceMacB64,
    required String userId,
    required List<int> backupKey,
    required bool importRatchetState,
  }) async {
    try {
      final encMap = jsonDecode(encryptedPayloadJson) as Map<String, dynamic>;
      final nonce = base64Decode(encMap['n'] as String);
      final cipher = base64Decode(encMap['c'] as String);
      final tag = base64Decode(encMap['t'] as String);
      final aad = utf8.encode('backup:$userId:v3');

      final encKeyBytes = await _deriveBackupEncryptionKey(backupKey, userId);
      final secretKey = SecretKey(encKeyBytes);

      final box = SecretBox(cipher, nonce: nonce, mac: Mac(tag));
      final clear = await _algo.decrypt(box, secretKey: secretKey, aad: aad);
      final clearJson = utf8.decode(clear);
      
      if (deviceMacB64 != null) {
        final computed = await _computeDeviceBackupMac(utf8.encode(clearJson));
        if (!const ListEquality().equals(computed, base64Decode(deviceMacB64))) {
          logger.w('⚠️ فشل تحقق device_mac — النسخة قد تكون تالفة');
        }
      }

      final backupData = jsonDecode(clearJson) as Map<String, dynamic>;
      final msgsJson = backupData['messages'] as List<dynamic>? ?? [];
      final msgs = msgsJson.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();

      if (importRatchetState && backupData.containsKey('ratchetState')) {
        await _importRatchetState(backupData['ratchetState'] as Map<String, dynamic>, userId);
      }

      return msgs;
    } catch (e, st) {
      logger.e('❌ فشل فك تشفير النسخة الاحتياطية: $e\n$st');
      return [];
    }
  }

  Future<void> _importRatchetState(Map<String, dynamic> ratchetJson, String userId) async {
    try {
      final chatId = ratchetJson['chatId'] as String?;
      if (chatId != null) {
        await RatchetService.importState(
          chatId: chatId,
          myUserId: userId,
          jsonState: ratchetJson,
        );
        logger.i('✅ تم استيراد حالة الراشِت من النسخة الاحتياطية للمحادثة $chatId');
      }
    } catch (e) {
      logger.e('❌ خطأ أثناء استيراد حالة الراشِت: $e');
    }
  }

  Future<List<int>> _deriveBackupEncryptionKey(List<int> backupKey, String userId) async {
    final derived = await _hkdf.deriveKey(
      secretKey: SecretKey(backupKey),
      info: utf8.encode('privoo:backup:enc'),
    );
    return await derived.extractBytes();
  }

  Future<List<int>> _computeDeviceBackupMac(List<int> plaintext) async {
    final stored = await _secureStorage.read(key: _deviceSecretKey);
    List<int> deviceSecret;
    if (stored != null) {
      deviceSecret = base64Decode(stored);
    } else {
      final rnd = Random.secure();
      deviceSecret = List<int>.generate(32, (_) => rnd.nextInt(256));
      await _secureStorage.write(key: _deviceSecretKey, value: base64Encode(deviceSecret));
    }
    final h = Hmac.sha256();
    final mac = await h.calculateMac(plaintext, secretKey: SecretKey(deviceSecret));
    return mac.bytes;
  }

  List<int> _randomNonce(int len) {
    final rnd = Random.secure();
    return List<int>.generate(len, (_) => rnd.nextInt(256));
  }
}