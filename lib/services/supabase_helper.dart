// lib/services/supabase_helper.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'supabase_service.dart';

class SupabaseHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> ensureUserExists(String uid, String phoneNumber) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      
      if (response == null) {
        logger.i('🆕 إنشاء مستخدم جديد في Supabase: $uid');
        await _supabase.from('users').insert({
          'uid': uid,
          'name': phoneNumber,
          'phone_number': phoneNumber,
          'avatar_url': '',
          'about': 'مرحباً، أنا أستخدم Privoo',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'last_seen': DateTime.now().toIso8601String(),
        });
        
        // تأكيد
        final check = await _supabase
            .from('users')
            .select()
            .eq('uid', uid)
            .maybeSingle();
        logger.i('✅ تم إنشاء المستخدم: ${check?['name']}');
        return check != null;
      }
      
      // ✅ المستخدم موجود - تحقق من وجود name
      if (response['name'] == null || response['name'].toString().isEmpty) {
        logger.i('📝 تحديث الاسم المؤقت للمستخدم: $uid');
        await _supabase
            .from('users')
            .update({'name': phoneNumber})
            .eq('uid', uid);
      }
      
      logger.i('✅ المستخدم موجود بالفعل: $uid');
      return true;
    } catch (e) {
      logger.e('❌ خطأ في ensureUserExists: $e');
      return false;
    }
  }
  
  static Future<void> updateUserName(String uid, String newName) async {
    try {
      await _supabase
          .from('users')
          .update({'name': newName})
          .eq('uid', uid);
      logger.i('✅ تم تحديث اسم المستخدم: $newName');
    } catch (e) {
      logger.e('❌ فشل تحديث الاسم: $e');
    }
  }
  
  static Future<void> updateLastSeen(String uid) async {
    try {
      await _supabase
          .from('users')
          .update({
            'last_seen': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .eq('uid', uid);
    } catch (e) {
      logger.e('❌ فشل تحديث lastSeen: $e');
    }
  }
}