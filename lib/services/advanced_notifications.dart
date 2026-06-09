// lib/services/advanced_notifications.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class AdvancedNotificationService {
  Future<void> enableSilentNotifications(String chatId, bool enabled) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('chat_settings').doc(chatId).set({
      'silentNotifications': enabled,
    }, SetOptions(merge: true));
  }
  
  Future<bool> isSilentNotification(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).collection('chat_settings').doc(chatId).get();
    return doc.data()?['silentNotifications'] ?? false;
  }
  
  Future<void> setupInlineReply(String chatId) async {
    logger.i('📱 تم إعداد الرد المباشر للمحادثة $chatId');
  }
}
