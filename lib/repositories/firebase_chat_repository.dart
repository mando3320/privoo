// repositories/firebase_chat_repository.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../models/message_model.dart';
import '../services/encryption_service.dart';
// key_exchange_service import removed (not used here)
import '../services/ratchet_service.dart';
import 'chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // KeyExchangeService instance removed here because it's not used directly.
  final Logger logger = Logger();

  @override
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required String myUserId,
    required String peerUserId,
    String algorithm = 'AES-GCM-256',
  }) async {
    // ✅ حساب timestamp مرة واحدة (سيُستخدم في AAD والتخزين)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final ratchetData = await RatchetService.nextSendingKey(
      chatId: chatId,
      myUserId: myUserId,
    );

    final msgType = message.type.name;

    // ✅ AAD يستخدم نفس timestamp الذي سيُخزن في Firestore
    final aad = utf8.encode(
      'chat:$chatId;sender:$myUserId;recv:$peerUserId;n:${ratchetData.n};ts:$timestamp;type:$msgType;v:2;dh:${base64Encode(ratchetData.myDhPub)}',
    );

    final encryptedContent = await EncryptionService.encrypt(
      plaintext: message.content,
      keyBytes: ratchetData.mk,
      aad: aad,
      algorithm: algorithm,
    );

    final encryptedMsg = message.copyWith(content: encryptedContent);

    // ✅ تخزين نفس timestamp في قاعدة البيانات
    await _db.collection('chats').doc(chatId).collection('messages').add({
      ...encryptedMsg.toMap(),
      'ratchetN': ratchetData.n,
      'senderId': myUserId,
      'recipientId': peerUserId,
      'protocolVersion': 2,
      'timestamp': timestamp,  // ✅ timestamp واحد
      'messageType': msgType,
      'dhPub': base64Encode(ratchetData.myDhPub),
      'alg': algorithm,
    });
  }

  @override
  Stream<List<MessageModel>> getMessages({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = <MessageModel>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        try {
          final ratchetN = data['ratchetN'] as int;
          final senderId = data['senderId'] ?? '';
          final recipientId = data['recipientId'] ?? '';
          final dhPub = data['dhPub'] ?? '';
          final mk = await RatchetService.keyForReceived(
            chatId: chatId,
            myUserId: myUserId,
            ratchetN: ratchetN,
            senderDhPub: dhPub.isNotEmpty ? base64Decode(dhPub) : null,
          );

          // ✅ استخدام نفس timestamp المخزن في قاعدة البيانات
          final storedTimestamp = data['timestamp'] as int;
          
          final aad = utf8.encode(
            'chat:$chatId;sender:$senderId;recv:$recipientId;n:$ratchetN;ts:$storedTimestamp;type:${data['messageType']};v:${data['protocolVersion']};dh:$dhPub',
          );

          final clear = await EncryptionService.decrypt(
            encrypted: data['content'],
            keyBytes: mk,
            aad: aad,
          );

          messages.add(MessageModel.fromMap(doc.id, {
            ...data,
            'content': clear,
          }));
        } catch (e) {
          logger.e('❌ فشل فك الرسالة ${doc.id}: $e');
          messages.add(MessageModel.fromMap(doc.id, {
            ...data,
            'content': '[فشل فك التشفير]',
          }));
        }
      }

      return messages;
    });
  }
}