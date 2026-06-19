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
          final ratchetN = msg['ratchet_n'] as int?;
          if (ratchetN == null) {
            decryptedMessages.add(MessageModel.fromMap(msg['id'].toString(), msg));
            continue;
          }
          
          final mk = await RatchetService.keyForReceived(
            chatId: chatId,
            myUserId: myUserId,
            ratchetN: ratchetN,
            senderDhPub: null,
          );

          final clear = await EncryptionService.decrypt(
            encrypted: msg['content'],
            keyBytes: mk,
            aad: utf8.encode('chat:$chatId;...'), // Simplified for example
          );

          decryptedMessages.add(MessageModel.fromMap(msg['id'].toString(), {
            ...msg,
            'content': clear,
          }));
        } catch (e) {
          logger.e('❌ فشل فك الرسالة: $e');
          decryptedMessages.add(MessageModel.fromMap(msg['id'].toString(), {
            ...msg,
            'content': '[فشل فك التشفير]',
          }));
        }
      }
      
      yield decryptedMessages;
    } catch (e) {
      logger.e('❌ فشل جلب الرسائل: $e');
      yield [];
    }
  }
}