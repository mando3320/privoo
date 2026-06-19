// lib/models/chat_member_model.dart
class ChatMemberModel {
  final String chatId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isMuted;
  final DateTime? muteUntil;

  ChatMemberModel({
    required this.chatId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.lastReadAt,
    this.isMuted = false,
    this.muteUntil,
  });

  factory ChatMemberModel.fromSupabase(Map<String, dynamic> data) {
    return ChatMemberModel(
      chatId: data['chat_id'] ?? '',
      userId: data['user_id'] ?? '',
      role: data['role'] ?? 'member',
      joinedAt: data['joined_at'] != null
          ? DateTime.tryParse(data['joined_at']) ?? DateTime.now()
          : DateTime.now(),
      lastReadAt: data['last_read_at'] != null
          ? DateTime.tryParse(data['last_read_at'])
          : null,
      isMuted: data['is_muted'] ?? false,
      muteUntil: data['mute_until'] != null
          ? DateTime.tryParse(data['mute_until'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'chat_id': chatId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
      'is_muted': isMuted,
      'mute_until': muteUntil?.toIso8601String(),
    };
  }
}