// lib/views/block_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_safety_service.dart';
import '../../services/block_service.dart';
import '../../main.dart';

class BlockListScreen extends ConsumerStatefulWidget {
  const BlockListScreen({super.key});

  @override
  ConsumerState<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends ConsumerState<BlockListScreen> {
  final UserSafetyService _safetyService = UserSafetyService();
  final BlockService _blockService = BlockService();
  List<String> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      _blockedUsers = await _blockService.getBlockedUsers().first;
      logger.i('✅ تم تحميل قائمة المستخدمين المحظورين: ${_blockedUsers.length} مستخدم');
    } catch (e) {
      logger.e('❌ فشل تحميل قائمة المحظورين: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      await _safetyService.unblockUser(userId);
      setState(() {
        _blockedUsers.remove(userId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إلغاء حظر المستخدم'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      logger.i('✅ تم إلغاء حظر المستخدم: $userId');
    } catch (e) {
      logger.e('❌ فشل إلغاء حظر المستخدم: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل إلغاء الحظر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshList() async {
    await _loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون المحظورون'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد مستخدمون محظورون',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عندما تحظر مستخدماً، سيظهر هنا',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshList,
                  child: ListView.builder(
                    itemCount: _blockedUsers.length,
                    itemBuilder: (context, index) {
                      final userId = _blockedUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: const Icon(
                              Icons.block,
                              color: Colors.red,
                            ),
                          ),
                          title: Text(
                            userId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text('مستخدم محظور'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.person_add_disabled,
                              color: Colors.green,
                            ),
                            tooltip: 'إلغاء الحظر',
                            onPressed: () => _unblockUser(userId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}