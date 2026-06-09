// lib/services/user_search_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// البحث عن مستخدمين بالاسم
  Future<List<Map<String, dynamic>>> searchByName(String query) async {
    if (query.isEmpty) return [];
    
    // البحث بالاسم (يستخدم معرّف أصغر ليطابق بداية الكلمة)
    final end = query.substring(0, query.length - 1) +
        String.fromCharCode(query.codeUnitAt(query.length - 1) + 1);
    
    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: end)
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'phone': data['phone'],
        'avatarUrl': data['avatarUrl'],
      };
    }).toList();
  }

  /// البحث برقم الهاتف
  Future<Map<String, dynamic>?> searchByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final data = snapshot.docs.first.data();
    return {
      'id': snapshot.docs.first.id,
      'name': data['name'],
      'phone': data['phone'],
      'avatarUrl': data['avatarUrl'],
    };
  }

  /// اقتراح جهات اتصال (من دفتر الهاتف)
  Future<List<Map<String, dynamic>>> searchByContacts(List<String> phoneNumbers) async {
    if (phoneNumbers.isEmpty) return [];
    
    final snapshot = await _firestore
        .collection('users')
        .where('phone', whereIn: phoneNumbers)
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'phone': data['phone'],
        'avatarUrl': data['avatarUrl'],
      };
    }).toList();
  }
}