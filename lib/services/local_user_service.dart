// lib/services/local_user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LocalUserService {
  static final LocalUserService _instance = LocalUserService._internal();
  factory LocalUserService() => _instance;
  LocalUserService._internal();

  late String _filePath;

  // ✅ تهيئة المسار
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/users.json';
    print('📁 مسار ملف المستخدمين: $_filePath');
    
    // ✅ إنشاء الملف لو مش موجود
    final file = File(_filePath);
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode({'users': []}));
      print('✅ تم إنشاء ملف users.json');
    }
  }

  // ✅ جلب كل المستخدمين
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final file = File(_filePath);
      if (!await file.exists()) return [];
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      return List<Map<String, dynamic>>.from(data['users'] ?? []);
    } catch (e) {
      print('❌ فشل جلب المستخدمين: $e');
      return [];
    }
  }

  // ✅ حفظ مستخدم جديد
  Future<bool> saveUser(Map<String, dynamic> user) async {
    try {
      final users = await getUsers();
      
      // ✅ التأكد من عدم تكرار الـ UID
      users.removeWhere((u) => u['uid'] == user['uid']);
      users.add(user);
      
      final file = File(_filePath);
      await file.writeAsString(jsonEncode({'users': users}));
      
      print('✅ تم حفظ المستخدم: ${user['uid']}');
      return true;
    } catch (e) {
      print('❌ فشل حفظ المستخدم: $e');
      return false;
    }
  }

  // ✅ جلب مستخدم بواسطة UID
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final users = await getUsers();
      return users.firstWhere((u) => u['uid'] == uid);
    } catch (e) {
      return null;
    }
  }

  // ✅ تحديث مستخدم
  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final users = await getUsers();
      final index = users.indexWhere((u) => u['uid'] == uid);
      
      if (index == -1) return false;
      
      users[index] = {...users[index], ...data};
      
      final file = File(_filePath);
      await file.writeAsString(jsonEncode({'users': users}));
      
      print('✅ تم تحديث المستخدم: $uid');
      return true;
    } catch (e) {
      print('❌ فشل تحديث المستخدم: $e');
      return false;
    }
  }

  // ✅ حذف مستخدم
  Future<bool> deleteUser(String uid) async {
    try {
      final users = await getUsers();
      users.removeWhere((u) => u['uid'] == uid);
      
      final file = File(_filePath);
      await file.writeAsString(jsonEncode({'users': users}));
      
      print('✅ تم حذف المستخدم: $uid');
      return true;
    } catch (e) {
      print('❌ فشل حذف المستخدم: $e');
      return false;
    }
  }

  // ✅ طباعة كل المستخدمين (للتأكد)
  Future<void> printUsers() async {
    final users = await getUsers();
    print('📊 عدد المستخدمين: ${users.length}');
    for (var user in users) {
      print('  👤 ${user['name']} (${user['uid']})');
    }
  }
}