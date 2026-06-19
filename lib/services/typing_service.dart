// lib/services/typing_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class TypingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _currentChatId;
  
  void startTyping(String chatId) {
    final user = SupabaseService().currentUser;
    if (user == null) return;
    
    _currentChatId = chatId;
    _typingTimer?.cancel();
    
    _setTypingStatus(chatId, user.id, true);
    
    _typingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTyping) {
        _setTypingStatus(chatId, user.id, true);
      }
    });
    
    _isTyping = true;
  }
  
  void stopTyping() {
    if (!_isTyping) return;
    
    final user = SupabaseService().currentUser;
    if (user == null || _currentChatId == null) return;
    
    _typingTimer?.cancel();
    _setTypingStatus(_currentChatId!, user.id, false);
    _isTyping = false;
    _currentChatId = null;
  }
  
  void _setTypingStatus(String chatId, String userId, bool isTyping) {
    _supabase.from('typing_indicators').upsert({
      'chat_id': chatId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'chat_id,user_id');
  }
  
  Stream<bool> listenToTyping(String chatId, String otherUserId) {
    return _supabase
        .from('typing_indicators')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('chat_id', chatId)
        .eq('user_id', otherUserId)
        .map((data) {
          if (data.isEmpty) return false;
          final doc = data.first;
          
          final updatedAt = doc['updated_at'] as String?;
          if (updatedAt == null) return false;
          
          final updatedDate = DateTime.tryParse(updatedAt);
          if (updatedDate == null) return false;
          
          final isRecent = DateTime.now().difference(updatedDate).inSeconds < 5;
          return doc['is_typing'] == true && isRecent;
        });
  }
}