// lib/views/admin/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': !isActive})
          .eq('uid', userId);
      
      _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? '✅ تم حظر المستخدم' : '✅ تم إلغاء حظر المستخدم'),
          backgroundColor: isActive ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('خطأ: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('لا يوجد مستخدمين'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isActive = user['is_active'] ?? true;
                        final name = user['name'] ?? 'مستخدم';
                        final phone = user['phone_number'] ?? '';
                        final isPro = user['is_pro'] ?? false;
                        final isLifetime = user['is_lifetime'] ?? false;

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive ? Colors.green : Colors.red,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(phone),
                                if (isPro || isLifetime)
                                  Chip(
                                    label: Text(
                                      isLifetime ? 'مدى الحياة' : 'Pro',
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                    backgroundColor: isLifetime ? Colors.amber : Colors.blue,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'toggle') {
                                  _toggleUserStatus(user['uid'], isActive);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(isActive ? 'حظر' : 'إلغاء الحظر'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}