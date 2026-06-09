// lib/models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rolesMap = data['roles'] as Map<String, dynamic>? ?? {};
    
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] ?? []),
      roles: rolesMap.map(
        (k, v) => MapEntry(k, GroupRole.values.firstWhere((e) => e.name == v)),
      ),
      encrypted: data['encrypted'] ?? true,
      groupKey: data['groupKey'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'members': members,
    'roles': roles.map((k, v) => MapEntry(k, v.name)),
    'encrypted': encrypted,
    if (groupKey != null) 'groupKey': groupKey,
  };

  bool isAdmin(String userId) => roles[userId] == GroupRole.admin;
}