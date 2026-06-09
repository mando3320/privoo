// lib/services/parental_control_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentalControlService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> setParentalControls({
    required String childId,
    required bool enabled,
    List<String>? blockedContacts,
  }) async {
    await _firestore.collection('parental_controls').doc(childId).set({
      'enabled': enabled,
      'blockedContacts': blockedContacts ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  Future<bool> isChildRestricted(String userId) async {
    final doc = await _firestore.collection('parental_controls').doc(userId).get();
    return doc.exists && doc.data()?['enabled'] == true;
  }
}
