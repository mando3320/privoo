// lib/services/user_safety_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
  }) async {
    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
  
  Future<void> blockUser(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(currentUserId).collection('blocked').doc(userId).set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> unblockUser(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(currentUserId).collection('blocked').doc(userId).delete();
  }
}
