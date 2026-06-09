// lib/services/group_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import 'encryption_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<GroupModel> createGroup({
    required String name,
    required List<String> members,
    String? avatarUrl,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final allMembers = [...members, userId];
    
    final group = GroupModel(
      id: _firestore.collection('groups').doc().id,
      name: name,
      avatarUrl: avatarUrl,
      createdBy: userId,
      createdAt: DateTime.now(),
      members: allMembers,
      roles: {for (var m in allMembers) m: GroupRole.member, userId: GroupRole.admin},
      encrypted: true,
    );

    await _firestore.collection('groups').doc(group.id).set(group.toFirestore());
    
    for (var member in allMembers) {
      await _firestore
          .collection('users')
          .doc(member)
          .collection('groups')
          .doc(group.id)
          .set({'joinedAt': FieldValue.serverTimestamp()});
    }
    
    return group;
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('groups')
        .snapshots()
        .asyncMap((snapshot) async {
          final groups = <GroupModel>[];
          for (var doc in snapshot.docs) {
            final groupDoc = await _firestore.collection('groups').doc(doc.id).get();
            if (groupDoc.exists) {
              groups.add(GroupModel.fromFirestore(groupDoc));
            }
          }
          return groups;
        });
  }

  Future<GroupModel> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) throw Exception('Group not found');
    return GroupModel.fromFirestore(doc);
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
    required String senderId,
    String type = 'text',
  }) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    if (!group.members.contains(senderId)) {
      throw Exception('User not in group');
    }
    
    final encryptedContent = await _encryptGroupMessage(message, groupId);
    
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': encryptedContent,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': type,
    });
  }

  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final group = await getGroup(groupId);
          final messages = <GroupMessage>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            try {
              final decrypted = await _decryptGroupMessage(data['content'], groupId);
              messages.add(GroupMessage(
                id: doc.id,
                senderId: data['senderId'],
                content: decrypted,
                timestamp: data['timestamp'],
                type: data['type'],
              ));
            } catch (e) {
              messages.add(GroupMessage(
                id: doc.id,
                senderId: data['senderId'],
                content: '[رسالة مشفرة]',
                timestamp: data['timestamp'],
                type: data['type'],
              ));
            }
          }
          return messages;
        });
  }

  Future<void> addMember(String groupId, String userId, String adminId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    if (!group.isAdmin(adminId)) {
      throw Exception('Only admins can add members');
    }
    
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'roles.$userId': GroupRole.member.name,
    });
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('groups')
        .doc(groupId)
        .set({'joinedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeMember(String groupId, String userId, String adminId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    if (!group.isAdmin(adminId)) {
      throw Exception('Only admins can remove members');
    }
    
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'roles.$userId': FieldValue.delete(),
    });
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('groups')
        .doc(groupId)
        .delete();
  }

  Future<void> promoteToAdmin(String groupId, String userId, String adminId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    if (!group.isAdmin(adminId)) {
      throw Exception('Only admins can promote members');
    }
    
    await _firestore.collection('groups').doc(groupId).update({
      'roles.$userId': GroupRole.admin.name,
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'roles.$userId': FieldValue.delete(),
    });
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('groups')
        .doc(groupId)
        .delete();
    
    if (group.members.length <= 1) {
      await _firestore.collection('groups').doc(groupId).delete();
    }
  }

  Future<void> deleteGroup(String groupId, String adminId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(groupDoc);
    
    if (!group.isAdmin(adminId)) {
      throw Exception('Only admins can delete the group');
    }
    
    final messages = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    
    for (var member in group.members) {
      await _firestore
          .collection('users')
          .doc(member)
          .collection('groups')
          .doc(groupId)
          .delete();
    }
    
    await _firestore.collection('groups').doc(groupId).delete();
  }

  Future<String> _encryptGroupMessage(String message, String groupId) async {
    final groupKey = await _getGroupKey(groupId);
    return await EncryptionService.encrypt(
      plaintext: message,
      keyBytes: groupKey,
    );
  }

  Future<String> _decryptGroupMessage(String encrypted, String groupId) async {
    final groupKey = await _getGroupKey(groupId);
    return await EncryptionService.decrypt(
      encrypted: encrypted,
      keyBytes: groupKey,
    );
  }

  Future<List<int>> _getGroupKey(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    final group = GroupModel.fromFirestore(doc);
    if (group.groupKey == null) {
      final newKey = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      await _firestore.collection('groups').doc(groupId).update({
        'groupKey': base64Encode(newKey),
      });
      return newKey;
    }
    return base64Decode(group.groupKey!);
  }
}

class GroupMessage {
  final String id;
  final String senderId;
  final String content;
  final int timestamp;
  final String type;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
  });
}