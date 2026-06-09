// lib/core/permissions.dart
import '../models/admin_model.dart';

class Permissions {
  // صلاحيات المستخدمين
  static const String viewUsers = 'users:view';
  static const String blockUsers = 'users:block';
  static const String deleteUsers = 'users:delete';
  static const String grantSubscription = 'users:grant_subscription';
  
  // صلاحيات الدعم
  static const String viewSupportTickets = 'support:view';
  static const String replySupportTickets = 'support:reply';
  static const String closeSupportTickets = 'support:close';
  
  // صلاحيات المحتوى
  static const String manageThemes = 'content:themes';
  static const String manageAnnouncements = 'content:announcements';
  
  // صلاحيات النظام
  static const String viewAnalytics = 'system:analytics';
  static const String viewLogs = 'system:logs';
  static const String manageBackups = 'system:backups';
  
  // صلاحيات الإشعارات
  static const String sendNotifications = 'notifications:send';
  
  // صلاحيات الإعدادات
  static const String editSettings = 'settings:edit';
  static const String manageAdmins = 'admins:manage';
}

class RolePermissions {
  static const Map<AdminRole, List<String>> rolePermissions = {
    // مدير عام - كل الصلاحيات
    AdminRole.superAdmin: [
      Permissions.viewUsers,
      Permissions.blockUsers,
      Permissions.deleteUsers,
      Permissions.grantSubscription,
      Permissions.viewSupportTickets,
      Permissions.replySupportTickets,
      Permissions.closeSupportTickets,
      Permissions.manageThemes,
      Permissions.manageAnnouncements,
      Permissions.viewAnalytics,
      Permissions.viewLogs,
      Permissions.manageBackups,
      Permissions.sendNotifications,
      Permissions.editSettings,
      Permissions.manageAdmins,
    ],
    
    // دعم فني
    AdminRole.supportAdmin: [
      Permissions.viewSupportTickets,
      Permissions.replySupportTickets,
      Permissions.closeSupportTickets,
      Permissions.viewUsers,
    ],
    
    // مدير محتوى
    AdminRole.contentAdmin: [
      Permissions.manageThemes,
      Permissions.manageAnnouncements,
      Permissions.sendNotifications,
      Permissions.viewAnalytics,
    ],
    
    // مراقب
    AdminRole.viewerAdmin: [
      Permissions.viewUsers,
      Permissions.viewSupportTickets,
      Permissions.viewAnalytics,
      Permissions.viewLogs,
    ],
  };
  
  static bool hasPermission(AdminRole role, String permission) {
    final permissions = rolePermissions[role] ?? [];
    return permissions.contains(permission);
  }
  
  static List<String> getPermissionsForRole(AdminRole role) {
    return rolePermissions[role] ?? [];
  }
}
