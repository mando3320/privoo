// test/controllers/auth_controller_test.dart - 20 اختبار
import 'package:flutter_test/flutter_test.dart';
import 'package:privoo/models/admin_model.dart';
import 'package:privoo/core/permissions.dart';

void main() {
  group('AuthController - 20 اختبار (نظام المشرفين)', () {
    group('Admin Roles (8)', () {
      test('TC1: مدير عام - كل الصلاحيات', () {
        final perms = RolePermissions.rolePermissions[AdminRole.superAdmin];
        expect(perms!.contains(Permissions.manageAdmins), true);
        expect(perms.contains(Permissions.viewUsers), true);
        expect(perms.contains(Permissions.blockUsers), true);
      });
      
      test('TC2: دعم فني - صلاحيات محدودة', () {
        final perms = RolePermissions.rolePermissions[AdminRole.supportAdmin];
        expect(perms!.contains(Permissions.viewSupportTickets), true);
        expect(perms.contains(Permissions.manageAdmins), false);
        expect(perms.contains(Permissions.blockUsers), false);
      });
      
      test('TC3: مدير محتوى - صلاحيات المحتوى', () {
        final perms = RolePermissions.rolePermissions[AdminRole.contentAdmin];
        expect(perms!.contains(Permissions.manageThemes), true);
        expect(perms.contains(Permissions.viewSupportTickets), false);
      });
      
      test('TC4: مراقب - مشاهدة فقط', () {
        final perms = RolePermissions.rolePermissions[AdminRole.viewerAdmin];
        expect(perms!.contains(Permissions.viewUsers), true);
        expect(perms.contains(Permissions.blockUsers), false);
      });
      
      test('TC5: اسم دور مدير عام', () {
        expect(AdminRole.superAdmin.displayName, 'مدير عام');
      });
      
      test('TC6: اسم دور دعم فني', () {
        expect(AdminRole.supportAdmin.displayName, 'دعم فني');
      });
      
      test('TC7: اسم دور مدير محتوى', () {
        expect(AdminRole.contentAdmin.displayName, 'مدير محتوى');
      });
      
      test('TC8: اسم دور مراقب', () {
        expect(AdminRole.viewerAdmin.displayName, 'مراقب');
      });
    });
    
    group('Permissions (7)', () {
      test('TC9: صلاحية عرض المستخدمين', () {
        expect(Permissions.viewUsers, 'users:view');
      });
      
      test('TC10: صلاحية حظر المستخدمين', () {
        expect(Permissions.blockUsers, 'users:block');
      });
      
      test('TC11: صلاحية حذف المستخدمين', () {
        expect(Permissions.deleteUsers, 'users:delete');
      });
      
      test('TC12: صلاحية منح اشتراكات', () {
        expect(Permissions.grantSubscription, 'users:grant_subscription');
      });
      
      test('TC13: صلاحية عرض تذاكر الدعم', () {
        expect(Permissions.viewSupportTickets, 'support:view');
      });
      
      test('TC14: صلاحية الرد على التذاكر', () {
        expect(Permissions.replySupportTickets, 'support:reply');
      });
      
      test('TC15: صلاحية إدارة المشرفين', () {
        expect(Permissions.manageAdmins, 'admins:manage');
      });
    });
    
    group('API Values (5)', () {
      test('TC16: مدير عام API value', () {
        expect(AdminRole.superAdmin.apiValue, 'super_admin');
      });
      
      test('TC17: دعم فني API value', () {
        expect(AdminRole.supportAdmin.apiValue, 'support_admin');
      });
      
      test('TC18: مدير محتوى API value', () {
        expect(AdminRole.contentAdmin.apiValue, 'content_admin');
      });
      
      test('TC19: مراقب API value', () {
        expect(AdminRole.viewerAdmin.apiValue, 'viewer_admin');
      });
      
      test('TC20: تحويل API value إلى دور', () {
        expect(AdminRoleExtension.fromApiValue('super_admin'), AdminRole.superAdmin);
        expect(AdminRoleExtension.fromApiValue('invalid'), AdminRole.viewerAdmin);
      });
    });
  });
}