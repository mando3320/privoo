// lib/services/block_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> blockUser(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(userId)
        .set({'blockedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(userId)
        .delete();
  }

  Future<bool> isBlocked(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(userId)
        .get();
    
    return doc.exists;
  }

  Stream<List<String>> getBlockedUsers() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}