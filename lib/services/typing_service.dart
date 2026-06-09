// lib/services/typing_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TypingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _currentChatId;
  
  /// بدء الكتابة (يرسل إشارة "يكتب..." كل 2 ثانية)
  void startTyping(String chatId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    _currentChatId = chatId;
    _typingTimer?.cancel();
    
    // إرسال إشارة الكتابة فوراً
    _setTypingStatus(chatId, userId, true);
    
    // إرسال إشارة كل 2 ثانية أثناء الكتابة
    _typingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTyping) {
        _setTypingStatus(chatId, userId, true);
      }
    });
    
    _isTyping = true;
  }
  
  /// إيقاف الكتابة
  void stopTyping() {
    if (!_isTyping) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _currentChatId == null) return;
    
    _typingTimer?.cancel();
    _setTypingStatus(_currentChatId!, userId, false);
    _isTyping = false;
    _currentChatId = null;
  }
  
  void _setTypingStatus(String chatId, String userId, bool isTyping) {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// الاستماع لحالة الكتابة لطرف آخر
  Stream<bool> listenToTyping(String chatId, String otherUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(otherUserId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          if (data == null) return false;
          
          final updatedAt = data['updatedAt'] as Timestamp?;
          if (updatedAt == null) return false;
          
          // إذا مر أكثر من 5 ثوانٍ على آخر تحديث، نعتبر أنه توقف عن الكتابة
          final isRecent = DateTime.now().difference(updatedAt.toDate()).inSeconds < 5;
          return data['isTyping'] == true && isRecent;
        });
  }
}