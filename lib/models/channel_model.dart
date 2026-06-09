// lib/models/channel_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatarUrl: data['avatarUrl'],
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subscribers: List<String>.from(data['subscribers'] ?? []),
      isPrivate: data['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'avatarUrl': avatarUrl,
    'ownerId': ownerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'subscribers': subscribers,
    'isPrivate': isPrivate,
  };
}