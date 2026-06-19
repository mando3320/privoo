// lib/models/group_model.dart
enum GroupRole { admin, member }

class GroupModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final Map<String, GroupRole> roles;
  final bool encrypted;
  final String? groupKey;

  GroupModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.roles,
    this.encrypted = true,
    this.groupKey,
  });

  factory GroupModel.fromSupabase(Map<String, dynamic> data) {
    final rolesMap = data['roles'] as Map<String, dynamic>? ?? {};
    
    return GroupModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      avatarUrl: data['avatar_url'],
      createdBy: data['created_by'] ?? '',
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      members: List<String>.from(data['members'] ?? []),
      roles: rolesMap.map(
        (k, v) => MapEntry(k, GroupRole.values.firstWhere(
          (e) => e.name == v,
          orElse: () => GroupRole.member,
        )),
      ),
      encrypted: data['encrypted'] ?? true,
      groupKey: data['group_key'],
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'avatar_url': avatarUrl,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'members': members,
    'roles': roles.map((k, v) => MapEntry(k, v.name)),
    'encrypted': encrypted,
    if (groupKey != null) 'group_key': groupKey,
  };

  bool isAdmin(String userId) => roles[userId] == GroupRole.admin;
}