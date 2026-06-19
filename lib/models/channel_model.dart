// lib/models/channel_model.dart
class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final String ownerId;
  final DateTime createdAt;
  final List<String> subscribers;
  final bool isPrivate;

  ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.createdAt,
    required this.subscribers,
    required this.isPrivate,
  });

  factory ChannelModel.fromSupabase(Map<String, dynamic> data) {
    return ChannelModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatarUrl: data['avatar_url'],
      ownerId: data['created_by'] ?? data['ownerId'] ?? '',
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      subscribers: List<String>.from(data['subscribers'] ?? []),
      isPrivate: !(data['is_public'] ?? true),
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'description': description,
    'avatar_url': avatarUrl,
    'created_by': ownerId,
    'is_public': !isPrivate,
    'subscribers': subscribers,
    'created_at': createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}