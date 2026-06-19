// lib/services/advanced_search_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class AdvancedSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MessageModel>> searchMessages({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    try {
      // ✅ البحث في الرسائل النصية
      final response = await _supabase
          .from('messages')
          .select()
          .eq('sender_id', userId)
          .ilike('content', '%$query%')
          .order('timestamp', ascending: false)
          .limit(limit);

      return response.map((doc) => MessageModel.fromSupabase(doc)).toList();
    } catch (e) {
      print('❌ Advanced search error: $e');
      return [];
    }
  }

  Future<List<MessageModel>> searchMessagesInChat({
    required String chatId,
    required String query,
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .ilike('content', '%$query%')
          .order('timestamp', ascending: false)
          .limit(limit);

      return response.map((doc) => MessageModel.fromSupabase(doc)).toList();
    } catch (e) {
      print('❌ Advanced search in chat error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from('users')
          .select()
          .ilike('name', '%$query%')
          .limit(limit);

      return response.map((doc) => {
        'id': doc['uid'],
        'name': doc['name'],
        'phone': doc['phone_number'],
        'avatar': doc['avatar_url'],
      }).toList();
    } catch (e) {
      print('❌ User search error: $e');
      return [];
    }
  }
}