// lib/views/chat/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/group_service.dart';
import '../../services/supabase_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedMembers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  
  final GroupService _groupService = GroupService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    // ✅ التحقق من mounted قبل setState
    if (mounted) {
      setState(() => _isLoadingUsers = true);
    }
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = SupabaseService().currentUser;
      
      // ✅ تغيير uid إلى id
      final response = await supabase
          .from('users')
          .select('id, name');
      
      _users = response
          .where((u) => u['id'] != currentUser?.id)
          .map((u) => {
            'id': u['id'],
            'name': u['name'] ?? 'مستخدم',
          })
          .toList();
      
      // ✅ التحقق من mounted قبل setState
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('❌ Failed to load users: $e');
      // ✅ التحقق من mounted قبل setState
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المجموعة')),
      );
      return;
    }
    
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار عضو واحد على الأقل')),
      );
      return;
    }
    
    // ✅ التحقق من mounted قبل setState
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        members: _selectedMembers,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء المجموعة ${group.name} بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      // ✅ التحقق من mounted قبل setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء مجموعة جديدة'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text('إنشاء'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المجموعة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'اختر الأعضاء (${_selectedMembers.length}):',
              ),
            ),
          ),
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('لا يوجد مستخدمون آخرون'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final userId = user['id'] as String;
                          final userName = user['name'] as String;
                          final isSelected = _selectedMembers.contains(userId);
                          
                          return CheckboxListTile(
                            title: Text(userName),
                            subtitle: Text(userId),
                            value: isSelected,
                            onChanged: (selected) {
                              // ✅ التحقق من mounted قبل setState
                              if (mounted) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedMembers.add(userId);
                                  } else {
                                    _selectedMembers.remove(userId);
                                  }
                                });
                              }
                            },
                            secondary: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}