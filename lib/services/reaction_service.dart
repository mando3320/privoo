// lib/services/reaction_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ إيموجي التفاعل الموسعة (18 إيموجي)
  static const List<String> availableReactions = [
    // الأساسية (6)
    '❤️', '👍', '😂', '😮', '😢', '😡',
    
    // إضافية (12)
    '🎉', '😍', '🤔', '👏', '🙏', '🔥',
    '😎', '🥰', '🤣', '😱', '🥳', '💯',
  ];

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String reaction,
    required String userId,
    bool isGroup = false,
  }) async {
    if (!availableReactions.contains(reaction)) return;
    
    // ✅ التحقق من وجود التفاعل بالفعل
    final existing = await _supabase
        .from('reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', reaction)
        .maybeSingle();
    
    if (existing != null) return;
    
    await _supabase.from('reactions').insert({
      'message_id': messageId,
      'user_id': userId,
      'emoji': reaction,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String reaction,
    required String userId,
    bool isGroup = false,
  }) async {
    await _supabase
        .from('reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', reaction);
  }
  
  /// ✅ الحصول على تفاعلات رسالة
  Future<Map<String, int>> getReactions(String messageId) async {
    final response = await _supabase
        .from('reactions')
        .select()
        .eq('message_id', messageId);
    
    final reactions = <String, int>{};
    for (var doc in response) {
      final emoji = doc['emoji'] as String;
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    }
    return reactions;
  }
  
  // ✅ دالة مساعدة للحصول على اسم الإيموجي
  static String getReactionName(String reaction) {
    switch (reaction) {
      case '❤️': return 'قلب';
      case '👍': return 'أعجبني';
      case '😂': return 'ضحك';
      case '😮': return 'متفاجئ';
      case '😢': return 'حزين';
      case '😡': return 'غاضب';
      case '🎉': return 'احتفال';
      case '😍': return 'حب';
      case '🤔': return 'تفكير';
      case '👏': return 'تصفيق';
      case '🙏': return 'شكراً';
      case '🔥': return 'ممتاز';
      case '😎': return 'رائع';
      case '🥰': return 'حب';
      case '🤣': return 'ضحك';
      case '😱': return 'صدمة';
      case '🥳': return 'احتفال';
      case '💯': return 'مئة';
      default: return '';
    }
  }
  
  // ✅ دالة للحصول على كل الإيموجي مع أسمائها
  static List<Map<String, String>> getReactionsWithNames() {
    return availableReactions.map((reaction) {
      return {
        'code': reaction,
        'name': getReactionName(reaction),
      };
    }).toList();
  }
}