// lib/services/sealed_sender.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';
import 'supabase_service.dart';

class SealedSenderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> sendSealedMessage({
    required String chatId,
    required String message,
    required String recipientId,
  }) async {
    final sender = SupabaseService().currentUser;
    if (sender == null) throw Exception('User not authenticated');

    final sealedMessage = await _sealMessage(message, sender.id, recipientId);

    await _supabase.from('sealed_messages').insert({
      'chat_id': chatId,
      'sender_id': sender.id,
      'recipient_id': recipientId,
      'sealed_content': sealedMessage,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> _sealMessage(String message, String senderId, String recipientId) async {
    final sealed = {
      'sender': senderId,
      'recipient': recipientId,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonString = jsonEncode(sealed);
    return base64Encode(utf8.encode(jsonString));
  }

  Future<String?> unsealMessage(String sealedMessage) async {
    try {
      final decoded = base64Decode(sealedMessage);
      final jsonString = utf8.decode(decoded);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return data['message'] as String?;
    } catch (e) {
      print('❌ Failed to unseal message: $e');
      return null;
    }
  }

  Future<bool> verifySealedSender(String sealedMessage) async {
    try {
      final decoded = base64Decode(sealedMessage);
      final jsonString = utf8.decode(decoded);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final senderId = data['sender'] as String?;
      if (senderId == null) return false;

      final userExists = await _supabase
          .from('users')
          .select()
          .eq('uid', senderId)
          .maybeSingle();

      return userExists != null;
    } catch (e) {
      print('❌ Failed to verify sealed sender: $e');
      return false;
    }
  }
}