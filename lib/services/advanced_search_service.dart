// lib/services/advanced_search_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class AdvancedSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<MessageModel>> searchMessages({
    required String userId,
    String? query,
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collectionGroup('messages')
        .where('senderId', isEqualTo: userId)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => MessageModel.fromDoc(doc)).toList();
  }
}
