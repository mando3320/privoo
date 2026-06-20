// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/chat_member_model.dart';

class UserModel {
  final String id;
  final String authId;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? about;
  final bool isActive;
  final bool isPro;
  final bool isLifetime;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.authId,
    this.name,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.about,
    this.isActive = true,
    this.isPro = false,
    this.isLifetime = false,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    authId: json['auth_id'] ?? '',
    name: json['name'],
    phoneNumber: json['phone_number'],
    email: json['email'],
    avatarUrl: json['avatar_url'],
    about: json['about'],
    isActive: json['is_active'] ?? true,
    isPro: json['is_pro'] ?? false,
    isLifetime: json['is_lifetime'] ?? false,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    isOnline: json['is_online'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'auth_id': authId,
    if (name != null) 'name': name,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (about != null) 'about': about,
    'is_active': isActive,
    'is_pro': isPro,
    'is_lifetime': isLifetime,
    'created_at': createdAt.toIso8601String(),
    if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
    'is_online': isOnline,
  };
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  final _uuid = const Uuid();
  bool _initialized = false;

  SupabaseClient get client => _client;

  static String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    print('✅ Supabase initialized');
  }

  // ============================================================
  // 👤 Auth
  // ============================================================

  Future<void> signInWithOTP(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: phoneNumber);
  }

  Future<AuthResponse> verifyOTP(String phoneNumber, String code) async {
    return await _client.auth.verifyOTP(
      phone: phoneNumber,
      token: code,
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  String? get sessionToken => _client.auth.currentSession?.accessToken;

  // ============================================================
  // 👤 Users
  // ============================================================

  Future<UserModel?> getUser(String authId) async {
    try {
      final response = await _client.from('users').select().eq('auth_id', authId).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUser error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final response = await _client.from('users').select().eq('phone_number', phoneNumber).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUserByPhone error: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client.from('users').select();
      return List<Map<String, dynamic>>.from(response)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getAllUsers error: $e');
      return [];
    }
  }

  Future<void> createUser(UserModel user) async {
    await _client.from('users').insert(user.toJson());
  }

  Future<void> updateUser(String authId, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('auth_id', authId);
  }

  Future<void> updateUserLastSeen(String authId) async {
    await _client.from('users').update({
      'last_seen': DateTime.now().toIso8601String(),
      'is_online': true,
    }).eq('auth_id', authId);
  }

  Future<void> setUserOffline(String authId) async {
    await _client.from('users').update({
      'is_online': false,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('auth_id', authId);
  }

  // ============================================================
  // 💬 Chats
  // ============================================================

  Future<String> createChat(List<String> members) async {
    final chatId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    
    await _client.from('chats').insert({
      'id': chatId,
      'created_at': now,
      'updated_at': now,
      'last_message': '',
      'last_message_time': now,
      'unread_count': {for (var m in members) m: 0},
    });
    
    for (final member in members) {
      await _client.from('chat_members').insert({
        'chat_id': chatId,
        'user_id': member,
        'joined_at': now,
      });
    }
    
    return chatId;
  }

  Future<List<ChatModel>> getUserChats(String authId) async {
    try {
      final memberResponse = await _client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', authId);
      
      final chatIds = List<Map<String, dynamic>>.from(memberResponse)
          .map((e) => e['chat_id'] as String)
          .toList();
      
      if (chatIds.isEmpty) return [];
      
      final response = await _client
          .from('chats')
          .select()
          .inFilter('id', chatIds)
          .order('last_message_time', ascending: false);
      
      final List<ChatModel> result = [];
      for (var json in response) {
        final members = await _getChatMembers(json['id'] as String);
        result.add(ChatModel.fromJson({
          ...json,
          'members': members,
        }));
      }
      return result;
    } catch (e) {
      print('❌ getUserChats error: $e');
      return [];
    }
  }

  Future<List<String>> _getChatMembers(String chatId) async {
    try {
      final response = await _client
          .from('chat_members')
          .select('user_id')
          .eq('chat_id', chatId);
      
      return List<Map<String, dynamic>>.from(response)
          .map((e) => e['user_id'] as String)
          .toList();
    } catch (e) {
      print('❌ _getChatMembers error: $e');
      return [];
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      final response = await _client.from('chats').select().eq('id', chatId).maybeSingle();
      if (response == null) return null;
      
      final members = await _getChatMembers(chatId);
      
      return ChatModel.fromJson({
        ...response,
        'members': members,
      });
    } catch (e) {
      print('❌ getChat error: $e');
      return null;
    }
  }

  Future<void> updateChatLastMessage(String chatId, String message, DateTime time) async {
    await _client.from('chats').update({
      'last_message': message,
      'last_message_time': time.toIso8601String(),
      'updated_at': time.toIso8601String(),
    }).eq('id', chatId);
  }

  Future<void> incrementUnreadCount(String chatId, String userId) async {
    final chat = await getChat(chatId);
    if (chat == null) return;
    
    final newCount = (chat.unreadCount[userId] ?? 0) + 1;
    final newUnread = Map<String, int>.from(chat.unreadCount);
    newUnread[userId] = newCount;
    
    await _client.from('chats').update({
      'unread_count': newUnread,
    }).eq('id', chatId);
  }

  Future<void> resetUnreadCount(String chatId, String userId) async {
    final chat = await getChat(chatId);
    if (chat == null) return;
    
    final newUnread = Map<String, int>.from(chat.unreadCount);
    newUnread[userId] = 0;
    
    await _client.from('chats').update({
      'unread_count': newUnread,
    }).eq('id', chatId);
  }

  // ============================================================
  // 📨 Messages
  // ============================================================

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    
    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: '',
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      type: _parseMessageType(type),
    );
    
    final response = await _client
        .from('messages')
        .insert({
          ...message.toMap(),
          'chat_id': chatId,
          'created_at': now,
        })
        .select()
        .single();
    
    await updateChatLastMessage(chatId, content, DateTime.now());
    
    final members = await _getChatMembers(chatId);
    for (final member in members) {
      if (member != senderId) {
        await incrementUnreadCount(chatId, member);
      }
    }
    
    return MessageModel.fromJson(response);
  }

  Future<List<MessageModel>> getMessages(String chatId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response)
          .map((json) => MessageModel.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('❌ getMessages error: $e');
      return [];
    }
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    final message = await _client.from('messages').select().eq('id', messageId).maybeSingle();
    if (message == null) return;
    
    final readBy = Map<String, bool>.from(message['read_by'] ?? {});
    readBy[userId] = true;
    
    await _client.from('messages').update({
      'read_by': readBy,
    }).eq('id', messageId);
  }

  // ============================================================
  // 📡 Realtime Subscriptions
  // ============================================================

  Stream<List<MessageModel>> subscribeToMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) {
          return List<Map<String, dynamic>>.from(data)
              .where((json) => json['chat_id'] == chatId)
              .map((json) => MessageModel.fromJson(json))
              .toList()
              .reversed
              .toList();
        });
  }

  Stream<ChatModel?> subscribeToChat(String chatId) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((data) {
          if (data.isEmpty) return null;
          return ChatModel.fromJson(data.first);
        });
  }

  Stream<UserModel?> subscribeToUserStatus(String authId) {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }

  // ============================================================
  // 🛠️ Helper Methods
  // ============================================================

  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'gif':
        return MessageType.gif;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}