// lib/services/parental_control_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentalControlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> setParentalControls({
    required String childId,
    required bool enabled,
    List<String>? blockedContacts,
  }) async {
    await _supabase.from('parental_controls').upsert({
      'user_id': childId,
      'enabled': enabled,
      'blocked_contacts': blockedContacts ?? [],
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
  
  Future<bool> isChildRestricted(String userId) async {
    final response = await _supabase
        .from('parental_controls')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    return response != null && response['enabled'] == true;
  }
}