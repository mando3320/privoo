// lib/repositories/supabase_chat_repository.dart
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/message_model.dart';
import '../services/encryption_service.dart';
import '../services/ratchet_service.dart';
import '../services/supabase_service.dart';
import 'chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseService _supabase = SupabaseService();
  final Logger logger = Logger();

  @override
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required String myUserId,
    required String peerUserId,
    String algorithm = 'AES-GCM-256',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final ratchetData = await RatchetService.nextSendingKey(
      chatId: chatId,
      myUserId: myUserId,
    );

    final msgType = message.type.name;

    // ✅ استخدام AAD موحد
    final aad = EncryptionService.buildAAD(
      chatId: chatId,
      senderId: myUserId,
      receiverId: peerUserId,
      ratchetN: ratchetData.n,
      timestamp: timestamp,
      messageType: msgType,
      protocolVersion: 2,
      dhPub: ratchetData.myDhPub,
    );

    final encryptedContent = await EncryptionService.encrypt(
      plaintext: message.content,
      keyBytes: ratchetData.mk,
      aad: aad,
      algorithm: algorithm,
    );

    final encryptedMsg = message.copyWith(content: encryptedContent);

    await _supabase.client.from('messages').insert({
      ...encryptedMsg.toMap(),
      'chat_id': chatId,
      'ratchet_n': ratchetData.n,
      'sender_auth_id': myUserId,
      'recipient_id': peerUserId,
      'protocol_version': 2,
      'timestamp': timestamp,
      'message_type': msgType,
      'dh_pub': base64Encode(ratchetData.myDhPub),
      'alg': algorithm,
    });
  }

  @override
  Stream<List<MessageModel>> getMessages({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) async* {
    try {
      final messages = await _supabase.getMessages(chatId);
      
      final decryptedMessages = <MessageModel>[];
      
      for (var msg in messages) {
        try {
          final ratchetN = msg.ratchetN;
          
          if (ratchetN == 0) {
            decryptedMessages.add(msg);
            continue;
          }
          
          final dhPub = msg.dhPub != null ? base64Decode(msg.dhPub!) : null;
          
          final mk = await RatchetService.keyForReceived(
            chatId: chatId,
            myUserId: myUserId,
            ratchetN: ratchetN,
            senderDhPub: dhPub,
          );

          // ✅ استخدام AAD موحد
          final aad = EncryptionService.buildAAD(
            chatId: chatId,
            senderId: msg.senderId,
            receiverId: myUserId,
            ratchetN: ratchetN,
            timestamp: msg.timestamp.millisecondsSinceEpoch,
            messageType: msg.type.name,
            protocolVersion: msg.protocolVersion,
            dhPub: dhPub ?? [],
          );

          final clear = await EncryptionService.decrypt(
            encrypted: msg.content,
            keyBytes: mk,
            aad: aad,
          );

          decryptedMessages.add(msg.copyWith(content: clear));
        } catch (e) {
          logger.e('❌ فشل فك الرسالة: $e');
          decryptedMessages.add(msg.copyWith(content: '[فشل فك التشفير]'));
        }
      }
      
      yield decryptedMessages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل: $e');
      yield [];
    }
  }
}