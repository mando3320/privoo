// services/channel_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/channel_model.dart';

class ChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء قناة جديدة
  Future<ChannelModel> createChannel({
    required String name,
    required String description,
    String? avatarUrl,
    bool isPrivate = false,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    final channel = ChannelModel(
      id: _firestore.collection('channels').doc().id,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      ownerId: userId,
      createdAt: DateTime.now(),
      subscribers: [userId],
      isPrivate: isPrivate,
    );

    await _firestore.collection('channels').doc(channel.id).set(channel.toFirestore());
    
    return channel;
  }

  /// الحصول على قنوات المستخدم
  Stream<List<ChannelModel>> getUserChannels(String userId) {
    return _firestore
        .collection('channels')
        .where('subscribers', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChannelModel.fromFirestore(doc))
            .toList());
  }

  /// الحصول على بيانات قناة واحدة
  Future<ChannelModel> getChannel(String channelId) async {
    final doc = await _firestore.collection('channels').doc(channelId).get();
    if (!doc.exists) throw Exception('Channel not found');
    return ChannelModel.fromFirestore(doc);
  }

  /// الحصول على جميع القنوات العامة
  Stream<List<ChannelModel>> getPublicChannels() {
    return _firestore
        .collection('channels')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChannelModel.fromFirestore(doc))
            .toList());
  }

  /// الاشتراك في قناة
  Future<void> subscribeToChannel(String channelId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    await _firestore.collection('channels').doc(channelId).update({
      'subscribers': FieldValue.arrayUnion([userId]),
    });
  }

  /// إلغاء الاشتراك من قناة
  Future<void> unsubscribeFromChannel(String channelId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    await _firestore.collection('channels').doc(channelId).update({
      'subscribers': FieldValue.arrayRemove([userId]),
    });
  }

  /// إرسال منشور في قناة
  Future<void> sendChannelPost({
    required String channelId,
    required String content,
    required String senderId,
  }) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('posts')
        .add({
      'senderId': senderId,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'likes': 0,
      'comments': 0,
    });
  }

  /// استلام منشورات القناة
  Stream<List<ChannelPost>> getChannelPosts(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return ChannelPost(
            id: doc.id,
            senderId: data['senderId'],
            content: data['content'],
            timestamp: data['timestamp'],
            likes: data['likes'] ?? 0,
            comments: data['comments'] ?? 0,
          );
        }).toList());
  }

  /// إعجاب بمنشور
  Future<void> likePost(String channelId, String postId) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('posts')
        .doc(postId)
        .update({'likes': FieldValue.increment(1)});
  }

  /// حذف قناة (للمالك فقط)
  Future<void> deleteChannel(String channelId, String ownerId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (userId != ownerId) throw Exception('Only channel owner can delete');
    
    await _firestore.collection('channels').doc(channelId).delete();
  }
}

class ChannelPost {
  final String id;
  final String senderId;
  final String content;
  final int timestamp;
  final int likes;
  final int comments;

  ChannelPost({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });
}