// test/core/permissions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:privoo/models/admin_model.dart';
import 'package:privoo/core/permissions.dart';

void main() {
  group('Permissions Tests', () {
    test('Super Admin should have all permissions', () {
      final permissions = RolePermissions.rolePermissions[AdminRole.superAdmin];
      expect(permissions!.contains(Permissions.viewUsers), true);
      expect(permissions.contains(Permissions.manageAdmins), true);
      expect(permissions.contains(Permissions.blockUsers), true);
      expect(permissions.contains(Permissions.grantSubscription), true);
    });
    
    test('Support Admin should not have admin management', () {
      final permissions = RolePermissions.rolePermissions[AdminRole.supportAdmin];
      expect(permissions!.contains(Permissions.manageAdmins), false);
      expect(permissions.contains(Permissions.viewSupportTickets), true);
    });
    
    test('Content Admin should have theme management', () {
      final permissions = RolePermissions.rolePermissions[AdminRole.contentAdmin];
      expect(permissions!.contains(Permissions.manageThemes), true);
      expect(permissions.contains(Permissions.manageAnnouncements), true);
    });
    
    test('Viewer Admin should have view only permissions', () {
      final permissions = RolePermissions.rolePermissions[AdminRole.viewerAdmin];
      expect(permissions!.contains(Permissions.viewUsers), true);
      expect(permissions.contains(Permissions.viewSupportTickets), true);
      expect(permissions.contains(Permissions.blockUsers), false);
    });
    
    test('hasPermission should return true for correct permission', () {
      expect(RolePermissions.hasPermission(AdminRole.superAdmin, Permissions.viewUsers), true);
    });
    
    test('hasPermission should return false for incorrect permission', () {
      expect(RolePermissions.hasPermission(AdminRole.viewerAdmin, Permissions.blockUsers), false);
    });
    
    test('getPermissionsForRole returns correct list', () {
      final perms = RolePermissions.getPermissionsForRole(AdminRole.supportAdmin);
      expect(perms.contains(Permissions.viewSupportTickets), true);
      expect(perms.contains(Permissions.manageAdmins), false);
    });
  });
}