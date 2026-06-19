// lib/services/group_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import 'encryption_service.dart';
import 'supabase_service.dart';

class GroupService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<GroupModel> createGroup({
    required String name,
    required List<String> members,
    String? avatarUrl,
  }) async {
    final user = SupabaseService().currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final allMembers = [...members, user.id];
    final groupId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    
    final group = GroupModel(
      id: groupId,
      name: name,
      avatarUrl: avatarUrl,
      createdBy: user.id,
      createdAt: DateTime.now(),
      members: allMembers,
      roles: {for (var m in allMembers) m: GroupRole.member, user.id: GroupRole.admin},
      encrypted: true,
    );

    await _supabase.from('chats').insert({
      'id': groupId,
      'name': name,
      'avatar_url': avatarUrl,
      'is_group': true,
      'created_by': user.id,
      'created_at': now,
      'updated_at': now,
    });

    for (var member in allMembers) {
      await _supabase.from('chat_members').insert({
        'chat_id': groupId,
        'user_id': member,
        'role': member == user.id ? 'admin' : 'member',
        'joined_at': now,
      });
    }
    
    return group;
  }

  // ✅ طريقة Supabase الصحيحة للـ Stream
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _supabase
        .from('chat_members')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('user_id', userId)
        .map((data) {
          final chatIds = List<Map<String, dynamic>>.from(data)
              .map((e) => e['chat_id'] as String)
              .toList();
          
          if (chatIds.isEmpty) return [];
          
          return _getGroupsStream(chatIds);
        });
  }

  Stream<List<GroupModel>> _getGroupsStream(List<String> chatIds) async* {
    try {
      final response = await _supabase
          .from('chats')
          .select()
          .eq('is_group', true)
          .inFilter('id', chatIds)
          .order('updated_at', ascending: false);
      
      yield response.map((doc) => GroupModel.fromSupabase(doc)).toList();
    } catch (e) {
      print('❌ _getGroupsStream error: $e');
      yield [];
    }
  }

  Future<GroupModel> getGroup(String groupId) async {
    final response = await _supabase
        .from('chats')
        .select()
        .eq('id', groupId)
        .eq('is_group', true)
        .maybeSingle();
    
    if (response == null) throw Exception('Group not found');
    return GroupModel.fromSupabase(response);
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
    required String senderId,
    String type = 'text',
  }) async {
    final response = await _supabase
        .from('chat_members')
        .select()
        .eq('chat_id', groupId)
        .eq('user_id', senderId)
        .maybeSingle();
    
    if (response == null) {
      throw Exception('User not in group');
    }
    
    final encryptedContent = await _encryptGroupMessage(message, groupId);
    
    await _supabase.from('messages').insert({
      'id': _uuid.v4(),
      'chat_id': groupId,
      'sender_id': senderId,
      'content': encryptedContent,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', groupId)
        .order('timestamp', ascending: false)
        .map((data) async {
          final group = await getGroup(groupId);
          final messages = <GroupMessage>[];
          for (var doc in data) {
            try {
              final decrypted = await _decryptGroupMessage(doc['content'], groupId);
              messages.add(GroupMessage(
                id: doc['id'],
                senderId: doc['sender_id'],
                content: decrypted,
                timestamp: DateTime.parse(doc['timestamp']).millisecondsSinceEpoch,
                type: doc['type'] ?? 'text',
              ));
            } catch (e) {
              messages.add(GroupMessage(
                id: doc['id'],
                senderId: doc['sender_id'],
                content: '[رسالة مشفرة]',
                timestamp: DateTime.parse(doc['timestamp']).millisecondsSinceEpoch,
                type: doc['type'] ?? 'text',
              ));
            }
          }
          return messages;
        });
  }

  Future<void> addMember(String groupId, String userId, String adminId) async {
    final response = await _supabase
        .from('chat_members')
        .select('role')
        .eq('chat_id', groupId)
        .eq('user_id', adminId)
        .maybeSingle();
    
    if (response == null || response['role'] != 'admin') {
      throw Exception('Only admins can add members');
    }
    
    await _supabase.from('chat_members').insert({
      'chat_id': groupId,
      'user_id': userId,
      'role': 'member',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeMember(String groupId, String userId, String adminId) async {
    final response = await _supabase
        .from('chat_members')
        .select('role')
        .eq('chat_id', groupId)
        .eq('user_id', adminId)
        .maybeSingle();
    
    if (response == null || response['role'] != 'admin') {
      throw Exception('Only admins can remove members');
    }
    
    await _supabase
        .from('chat_members')
        .delete()
        .eq('chat_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> promoteToAdmin(String groupId, String userId, String adminId) async {
    final response = await _supabase
        .from('chat_members')
        .select('role')
        .eq('chat_id', groupId)
        .eq('user_id', adminId)
        .maybeSingle();
    
    if (response == null || response['role'] != 'admin') {
      throw Exception('Only admins can promote members');
    }
    
    await _supabase
        .from('chat_members')
        .update({'role': 'admin'})
        .eq('chat_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _supabase
        .from('chat_members')
        .delete()
        .eq('chat_id', groupId)
        .eq('user_id', userId);
    
    final members = await _supabase
        .from('chat_members')
        .select('user_id')
        .eq('chat_id', groupId);
    
    if (members.isEmpty) {
      await _supabase
          .from('chats')
          .delete()
          .eq('id', groupId);
    }
  }

  Future<void> deleteGroup(String groupId, String adminId) async {
    final response = await _supabase
        .from('chat_members')
        .select('role')
        .eq('chat_id', groupId)
        .eq('user_id', adminId)
        .maybeSingle();
    
    if (response == null || response['role'] != 'admin') {
      throw Exception('Only admins can delete the group');
    }
    
    await _supabase
        .from('messages')
        .delete()
        .eq('chat_id', groupId);
    
    await _supabase
        .from('chat_members')
        .delete()
        .eq('chat_id', groupId);
    
    await _supabase
        .from('chats')
        .delete()
        .eq('id', groupId);
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
    final response = await _supabase
        .from('chats')
        .select('group_key')
        .eq('id', groupId)
        .maybeSingle();
    
    if (response == null || response['group_key'] == null) {
      final newKey = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      await _supabase
          .from('chats')
          .update({'group_key': base64Encode(newKey)})
          .eq('id', groupId);
      return newKey;
    }
    return base64Decode(response['group_key']);
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