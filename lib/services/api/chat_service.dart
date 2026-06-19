// services/api/chat_service.dart
import 'package:privoo/models/message_model.dart';
import 'package:privoo/repositories/chat_repository.dart';
import 'package:privoo/repositories/supabase_chat_repository.dart';
import 'package:privoo/services/key_exchange_service.dart';
import 'package:privoo/services/ratchet_service.dart';

class ChatService {
  final ChatRepository _repository;
  final KeyExchangeService _kx = KeyExchangeService();

  ChatService({ChatRepository? repository})
      : _repository = repository ?? SupabaseChatRepository();

  /// 🚀 إنشاء جلسة جديدة بين مستخدمين (مرة واحدة)
  Future<List<int>> initSession({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) async {
    // استخدام X3DH مع Ephemeral Key
    final session = await _kx.establishSessionWithEphemeral(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );

    await RatchetService.initRatchet(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
      sessionKey32: session.msgKey,
    );

    return session.msgKey;
  }

  /// ✉️ إرسال رسالة
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required String myUserId,
    required String peerUserId,
    String algorithm = 'AES-GCM-256',
  }) async {
    await _repository.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: myUserId,
      peerUserId: peerUserId,
      algorithm: algorithm,
    );
  }

  /// 🔄 الاستماع للرسائل
  Stream<List<MessageModel>> getMessages({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) {
    return _repository.getMessages(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );
  }
}