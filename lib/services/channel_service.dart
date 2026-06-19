// services/channel_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/channel_model.dart';
import 'supabase_service.dart';

class ChannelService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// إنشاء قناة جديدة
  Future<ChannelModel> createChannel({
    required String name,
    required String description,
    String? avatarUrl,
    bool isPrivate = false,
  }) async {
    final user = SupabaseService().currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final channelId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    
    final channel = ChannelModel(
      id: channelId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      ownerId: user.id,
      createdAt: DateTime.now(),
      subscribers: [user.id],
      isPrivate: isPrivate,
    );

    await _supabase.from('channels').insert({
      'id': channelId,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': user.id,
      'is_public': !isPrivate,
      'subscriber_count': 1,
      'created_at': now,
      'updated_at': now,
    });

    await _supabase.from('channel_subscribers').insert({
      'channel_id': channelId,
      'user_id': user.id,
      'is_moderator': true,
      'joined_at': now,
    });
    
    return channel;
  }

  /// الحصول على قنوات المستخدم
  Stream<List<ChannelModel>> getUserChannels(String userId) {
    return _supabase
        .from('channels')
        .stream(primaryKey: ['id'])
        .eq('subscribers.user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((doc) => ChannelModel.fromSupabase(doc)).toList();
        });
  }

  /// الحصول على بيانات قناة واحدة
  Future<ChannelModel> getChannel(String channelId) async {
    final response = await _supabase
        .from('channels')
        .select()
        .eq('id', channelId)
        .maybeSingle();
    
    if (response == null) throw Exception('Channel not found');
    return ChannelModel.fromSupabase(response);
  }

  /// الحصول على جميع القنوات العامة
  Stream<List<ChannelModel>> getPublicChannels() {
    return _supabase
        .from('channels')
        .stream(primaryKey: ['id'])
        .eq('is_public', true)
        .order('subscriber_count', ascending: false)
        .map((data) {
          return data.map((doc) => ChannelModel.fromSupabase(doc)).toList();
        });
  }

  /// الاشتراك في قناة
  Future<void> subscribeToChannel(String channelId) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;
    
    await _supabase.from('channel_subscribers').insert({
      'channel_id': channelId,
      'user_id': user.id,
      'joined_at': DateTime.now().toIso8601String(),
    });
    
    await _supabase.rpc('increment_subscriber_count', params: {'channel_id': channelId});
  }

  /// إلغاء الاشتراك من قناة
  Future<void> unsubscribeFromChannel(String channelId) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;
    
    await _supabase
        .from('channel_subscribers')
        .delete()
        .eq('channel_id', channelId)
        .eq('user_id', user.id);
    
    await _supabase.rpc('decrement_subscriber_count', params: {'channel_id': channelId});
  }

  /// إرسال منشور في قناة
  Future<void> sendChannelPost({
    required String channelId,
    required String content,
    required String senderId,
  }) async {
    await _supabase.from('messages').insert({
      'id': _uuid.v4(),
      'chat_id': channelId,
      'sender_id': senderId,
      'content': content,
      'type': 'channel_post',
      'timestamp': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// استلام منشورات القناة
  Stream<List<Map<String, dynamic>>> getChannelPosts(String channelId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', channelId)
        .eq('type', 'channel_post')
        .order('timestamp', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// إعجاب بمنشور
  Future<void> likePost(String channelId, String postId) async {
    final user = SupabaseService().currentUser;
    if (user == null) return;
    
    await _supabase.from('reactions').insert({
      'message_id': postId,
      'user_id': user.id,
      'emoji': '👍',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// حذف قناة (للمالك فقط)
  Future<void> deleteChannel(String channelId, String ownerId) async {
    final user = SupabaseService().currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (user.id != ownerId) throw Exception('Only channel owner can delete');
    
    await _supabase
        .from('channels')
        .delete()
        .eq('id', channelId)
        .eq('created_by', ownerId);
  }
}