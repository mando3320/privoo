// lib/models/chat_model.dart
class ChatModel {
  final String id;
  final String? name;
  final String? avatarUrl;
  final bool isGroup;
  final bool isChannel;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> members;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    this.name,
    this.avatarUrl,
    this.isGroup = false,
    this.isChannel = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.unreadCount = const {},
  });

  factory ChatModel.fromSupabase(Map<String, dynamic> data) {
    return ChatModel(
      id: data['id'] ?? '',
      name: data['name'],
      avatarUrl: data['avatar_url'],
      isGroup: data['is_group'] ?? false,
      isChannel: data['is_channel'] ?? false,
      createdBy: data['created_by'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      members: List<String>.from(data['members'] ?? []),
      unreadCount: Map<String, int>.from(data['unread_count'] ?? {}),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_group': isGroup,
      'is_channel': isChannel,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'members': members,
      'unread_count': unreadCount,
    };
  }
}