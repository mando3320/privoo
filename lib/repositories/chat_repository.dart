// lib/repositories/chat_repository.dart
import '../models/message_model.dart';

/// واجهة الـ Repository لعزل Firebase
abstract class ChatRepository {
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required String myUserId,
    required String peerUserId,
    String algorithm = 'AES-GCM-256',
  });

  Stream<List<MessageModel>> getMessages({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  });
}