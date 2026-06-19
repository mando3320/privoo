// lib/services/user_search_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// البحث عن مستخدمين بالاسم
  Future<List<Map<String, dynamic>>> searchByName(String query) async {
    if (query.isEmpty) return [];
    
    final response = await _supabase
        .from('users')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    
    return response.map((doc) {
      return {
        'id': doc['uid'],
        'uid': doc['uid'],
        'name': doc['name'] ?? 'مستخدم',
        'phone': doc['phone_number'] ?? '',
        'avatarUrl': doc['avatar_url'],
        'about': doc['about'] ?? '',
      };
    }).toList();
  }

  /// البحث برقم الهاتف
  Future<Map<String, dynamic>?> searchByPhone(String phone) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('phone_number', phone)
        .maybeSingle();
    
    if (response == null) return null;
    
    return {
      'id': response['uid'],
      'uid': response['uid'],
      'name': response['name'] ?? 'مستخدم',
      'phone': response['phone_number'] ?? phone,
      'avatarUrl': response['avatar_url'],
      'about': response['about'] ?? '',
    };
  }

  /// اقتراح جهات اتصال (من دفتر الهاتف)
  Future<List<Map<String, dynamic>>> searchByContacts(List<String> phoneNumbers) async {
    if (phoneNumbers.isEmpty) return [];
    
    final response = await _supabase
        .from('users')
        .select()
        .inFilter('phone_number', phoneNumbers.take(30).toList())
        .limit(50);
    
    return response.map((doc) {
      return {
        'id': doc['uid'],
        'uid': doc['uid'],
        'name': doc['name'] ?? 'مستخدم',
        'phone': doc['phone_number'] ?? '',
        'avatarUrl': doc['avatar_url'],
        'about': doc['about'] ?? '',
      };
    }).toList();
  }
}