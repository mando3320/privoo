// lib/models/chat_model.dart
class ChatModel {
  final String chatId;
  final List<String> members;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.chatId,
    required this.members,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['id'] ?? json['chat_id'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'])
          : null,
      unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
    );
  }

  // ✅ للاستخدام مع Supabase
  factory ChatModel.fromSupabase(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['id'] ?? json['chat_id'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'])
          : null,
      unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'members': members,
      'created_at': createdAt.toIso8601String(),
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageTime != null) 'last_message_time': lastMessageTime!.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}