// lib/views/chat/group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../services/supabase_service.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  late Future<GroupModel> _groupFuture;
  final GroupService _groupService = GroupService();

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  void _loadGroup() {
    _groupFuture = _groupService.getGroup(widget.groupId);
  }

  Future<void> _addMember() async {
    final TextEditingController controller = TextEditingController();
    
    final userId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عضو'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'معرف المستخدم (UID)',
            hintText: 'أدخل UID المستخدم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    
    if (userId != null && userId.isNotEmpty) {
      final currentUser = SupabaseService().currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
        );
        return;
      }
      try {
        await _groupService.addMember(widget.groupId, userId, currentUser.id);
        _loadGroup();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العضو بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المجموعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addMember,
            tooltip: 'إضافة عضو',
          ),
        ],
      ),
      body: FutureBuilder<GroupModel>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          final group = snapshot.data!;
          final currentUser = SupabaseService().currentUser;
          if (currentUser == null) {
            return const Center(child: Text('يجب تسجيل الدخول'));
          }
          final currentUserId = currentUser.id;
          final isAdmin = group.isAdmin(currentUserId);
          
          return Column(
            children: [
              // معلومات المجموعة
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        group.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      group.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${group.members.length} عضو'),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(group),
                        icon: const Icon(Icons.delete),
                        label: const Text('حذف المجموعة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(),
              // قائمة الأعضاء
              Expanded(
                child: ListView.builder(
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    final role = group.roles[memberId];
                    final isCurrentUser = memberId == currentUserId;
                    
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(isCurrentUser ? 'أنت' : memberId),
                      subtitle: Text(role == GroupRole.admin ? 'مشرف' : 'عضو'),
                      trailing: isAdmin && !isCurrentUser
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'remove') {
                                  await _groupService.removeMember(
                                    widget.groupId,
                                    memberId,
                                    currentUserId,
                                  );
                                  _loadGroup();
                                } else if (value == 'promote') {
                                  await _groupService.promoteToAdmin(
                                    widget.groupId,
                                    memberId,
                                    currentUserId,
                                  );
                                  _loadGroup();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'promote',
                                  child: Text('ترقية إلى مشرف'),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('إزالة', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(GroupModel group) {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text('هل أنت متأكد من حذف المجموعة "${group.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _groupService.deleteGroup(widget.groupId, currentUser.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المجموعة')),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}