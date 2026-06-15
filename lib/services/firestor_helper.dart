// lib/services/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class FirestoreHelper {
  static Future<bool> ensureUserExists(String uid, String phoneNumber) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await userRef.get();
      
      if (!doc.exists) {
        logger.i('🆕 إنشاء مستخدم جديد في Firestore: $uid');
        await userRef.set({
          'uid': uid,
          'name': phoneNumber,  // ✅ نفس قيمة phoneNumber (رقم الهاتف)
          'phoneNumber': phoneNumber,
          'avatarUrl': '',
          'about': 'مرحباً، أنا أستخدم Privoo',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        
        // تأكيد
        final check = await userRef.get();
        logger.i('✅ تم إنشاء المستخدم: ${check.data()?['name']}');
        return check.exists;
      }
      
      // ✅ المستخدم موجود - تحقق من وجود name
      final data = doc.data()!;
      if (data['name'] == null || data['name'].toString().isEmpty) {
        logger.i('📝 تحديث الاسم المؤقت للمستخدم: $uid');
        await userRef.update({
          'name': phoneNumber,  // ✅ تحديث بنفس قيمة phoneNumber
        });
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
            'name': newName,
          });
      logger.i('✅ تم تحديث اسم المستخدم: $newName');
    } catch (e) {
      logger.e('❌ فشل تحديث الاسم: $e');
    }
  }
  
  static Future<void> updateLastSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isActive': true,
          });
    } catch (e) {
      logger.e('❌ فشل تحديث lastSeen: $e');
    }
  }
}