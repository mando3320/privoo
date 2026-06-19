// lib/services/block_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BlockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> blockUser(String userId) async {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return;
    
    await _supabase.from('block_list').insert({
      'blocker_id': currentUser.id,
      'blocked_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unblockUser(String userId) async {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return;
    
    await _supabase
        .from('block_list')
        .delete()
        .eq('blocker_id', currentUser.id)
        .eq('blocked_id', userId);
  }

  Future<bool> isBlocked(String userId) async {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return false;
    
    final response = await _supabase
        .from('block_list')
        .select()
        .eq('blocker_id', currentUser.id)
        .eq('blocked_id', userId)
        .maybeSingle();
    
    return response != null;
  }

  Stream<List<String>> getBlockedUsers() {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    
    return _supabase
        .from('block_list')
        .stream(primaryKey: ['id'])
        .eq('blocker_id', currentUser.id)
        .map((data) {
          return data.map((doc) => doc['blocked_id'] as String).toList();
        });
  }
}