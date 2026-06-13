// lib/services/user_search_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// البحث عن مستخدمين بالاسم
  Future<List<Map<String, dynamic>>> searchByName(String query) async {
    if (query.isEmpty) return [];
    
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
        'uid': doc.id,
        'name': data['name'] ?? 'مستخدم',
        'phone': data['phoneNumber'] ?? data['phone'] ?? '',
        'avatarUrl': data['avatarUrl'],
        'about': data['about'] ?? '',
      };
    }).toList();
  }

  /// البحث برقم الهاتف (معدل للبحث في phoneNumber أولاً)
  Future<Map<String, dynamic>?> searchByPhone(String phone) async {
    // ✅ البحث في phoneNumber أولاً
    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return {
        'id': snapshot.docs.first.id,
        'uid': snapshot.docs.first.id,
        'name': data['name'] ?? 'مستخدم',
        'phone': data['phoneNumber'] ?? data['phone'] ?? phone,
        'avatarUrl': data['avatarUrl'],
        'about': data['about'] ?? '',
      };
    }
    
    // ✅ إذا لم يجد في phoneNumber، يبحث في phone (احتياطي)
    final fallbackSnapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (fallbackSnapshot.docs.isEmpty) return null;
    
    final data = fallbackSnapshot.docs.first.data();
    return {
      'id': fallbackSnapshot.docs.first.id,
      'uid': fallbackSnapshot.docs.first.id,
      'name': data['name'] ?? 'مستخدم',
      'phone': data['phone'] ?? phone,
      'avatarUrl': data['avatarUrl'],
      'about': data['about'] ?? '',
    };
  }

  /// اقتراح جهات اتصال (من دفتر الهاتف)
  Future<List<Map<String, dynamic>>> searchByContacts(List<String> phoneNumbers) async {
    if (phoneNumbers.isEmpty) return [];
    
    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', whereIn: phoneNumbers.take(30).toList())
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'uid': doc.id,
        'name': data['name'] ?? 'مستخدم',
        'phone': data['phoneNumber'] ?? data['phone'] ?? '',
        'avatarUrl': data['avatarUrl'],
        'about': data['about'] ?? '',
      };
    }).toList();
  }
}