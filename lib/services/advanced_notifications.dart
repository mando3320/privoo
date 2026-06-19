// lib/services/advanced_notifications.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AdvancedNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> setChatSilent(String chatId, bool silent) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    await _supabase.from('chat_settings').upsert({
      'user_id': user.id,
      'chat_id': chatId,
      'silent_notifications': silent,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,chat_id');
  }

  Future<bool> isChatSilent(String chatId) async {
    final user = SupabaseService().currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('chat_settings')
        .select()
        .eq('user_id', user.id)
        .eq('chat_id', chatId)
        .maybeSingle();

    return response != null && (response['silent_notifications'] ?? false);
  }

  Future<void> setChatMuteUntil(String chatId, DateTime until) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    await _supabase.from('chat_settings').upsert({
      'user_id': user.id,
      'chat_id': chatId,
      'mute_until': until.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,chat_id');
  }

  Future<DateTime?> getChatMuteUntil(String chatId) async {
    final user = SupabaseService().currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('chat_settings')
        .select()
        .eq('user_id', user.id)
        .eq('chat_id', chatId)
        .maybeSingle();

    if (response == null || response['mute_until'] == null) return null;
    return DateTime.tryParse(response['mute_until']);
  }

  Future<void> setNotificationSound(String sound) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    await _supabase.from('user_settings').upsert({
      'user_id': user.id,
      'notification_sound': sound,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<String?> getNotificationSound() async {
    final user = SupabaseService().currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response?['notification_sound'] as String?;
  }
}