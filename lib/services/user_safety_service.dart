// lib/services/user_safety_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserSafetyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
  }) async {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return;
    
    await _supabase.from('reports').insert({
      'reporter_id': currentUser.id,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
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
}