// lib/models/admin_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin,    // المدير العام
  supportAdmin,  // دعم فني
  contentAdmin,  // مدير محتوى
  viewerAdmin,   // مراقب
}

extension AdminRoleExtension on AdminRole {
  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'مدير عام';
      case AdminRole.supportAdmin:
        return 'دعم فني';
      case AdminRole.contentAdmin:
        return 'مدير محتوى';
      case AdminRole.viewerAdmin:
        return 'مراقب';
    }
  }
  
  String get apiValue {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.supportAdmin:
        return 'support_admin';
      case AdminRole.contentAdmin:
        return 'content_admin';
      case AdminRole.viewerAdmin:
        return 'viewer_admin';
    }
  }
  
  static AdminRole fromApiValue(String value) {
    switch (value) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'support_admin':
        return AdminRole.supportAdmin;
      case 'content_admin':
        return AdminRole.contentAdmin;
      default:
        return AdminRole.viewerAdmin;
    }
  }
}

class AdminModel {
  final String phoneNumber;
  final AdminRole role;
  final String name;
  final DateTime assignedAt;
  final List<String> permissions;
  final bool isActive;
  
  AdminModel({
    required this.phoneNumber,
    required this.role,
    required this.name,
    required this.assignedAt,
    required this.permissions,
    this.isActive = true,
  });
  
  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      phoneNumber: map['phoneNumber'] ?? '',
      role: AdminRoleExtension.fromApiValue(map['role'] ?? 'viewer_admin'),
      name: map['name'] ?? '',
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      permissions: List<String>.from(map['permissions'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'role': role.apiValue,
      'name': name,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'permissions': permissions,
      'isActive': isActive,
    };
  }
}
