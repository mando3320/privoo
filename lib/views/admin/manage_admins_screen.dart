// lib/views/admin/manage_admins_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin_model.dart';
import '../../core/permissions.dart';

class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  AdminRole? _selectedRole;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المشرفين'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('admins')
            .stream(primaryKey: ['phoneNumber']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final admins = snapshot.data ?? [];
          
          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = AdminModel.fromMap(admins[index]);
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(admin.role),
                    child: Icon(_getRoleIcon(admin.role), color: Colors.white),
                  ),
                  title: Text(admin.name),
                  subtitle: Text('${admin.role.displayName}\n${admin.phoneNumber}'),
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _supabase
                            .from('admins')
                            .delete()
                            .eq('phoneNumber', admin.phoneNumber);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdminDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مشرف'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
  
  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مشرف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            DropdownButtonFormField<AdminRole>(
              decoration: const InputDecoration(labelText: 'الدور'),
              items: AdminRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                );
              }).toList(),
              onChanged: (value) => _selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty &&
                  _selectedRole != null) {
                final admin = AdminModel(
                  phoneNumber: _phoneController.text,
                  role: _selectedRole!,
                  name: _nameController.text,
                  assignedAt: DateTime.now(),
                  permissions: RolePermissions.getPermissionsForRole(_selectedRole!),
                );
                await _supabase
                    .from('admins')
                    .insert(admin.toMap());
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
  
  Color _getRoleColor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin: return Colors.purple;
      case AdminRole.supportAdmin: return Colors.blue;
      case AdminRole.contentAdmin: return Colors.green;
      case AdminRole.viewerAdmin: return Colors.grey;
    }
  }
  
  IconData _getRoleIcon(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin: return Icons.admin_panel_settings;
      case AdminRole.supportAdmin: return Icons.support_agent;
      case AdminRole.contentAdmin: return Icons.palette;
      case AdminRole.viewerAdmin: return Icons.visibility;
    }
  }
}