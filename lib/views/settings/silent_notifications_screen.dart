// lib/views/settings/silent_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class SilentNotificationsScreen extends ConsumerStatefulWidget {
  const SilentNotificationsScreen({super.key});

  @override
  ConsumerState<SilentNotificationsScreen> createState() => _SilentNotificationsScreenState();
}

class _SilentNotificationsScreenState extends ConsumerState<SilentNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _silentChats = [];
  String? _currentUserId;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService().currentUser?.id;
    _loadSilentChats();
  }

  Future<void> _loadSilentChats() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('chat_settings')
          .select()
          .eq('user_id', _currentUserId)
          .eq('silent_notifications', true);

      final chats = <Map<String, dynamic>>[];
      for (var doc in response) {
        final chatId = doc['chat_id'];
        final otherId = _getOtherUserId(chatId);
        String chatName = 'محادثة';
        
        // جلب اسم المستخدم الآخر
        try {
          final userResponse = await _supabase
              .from('users')
              .select()
              .eq('uid', otherId)
              .maybeSingle();
          
          if (userResponse != null) {
            chatName = userResponse['name'] ?? 'مستخدم';
          }
        } catch (e) {
          chatName = otherId.substring(0, 8);
        }

        chats.add({
          'chatId': chatId,
          'otherId': otherId,
          'name': chatName,
          'silent': true,
        });
      }

      setState(() {
        _silentChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getOtherUserId(String chatId) {
    if (_currentUserId == null) return '';
    final ids = chatId.split('_');
    return ids.firstWhere((id) => id != _currentUserId, orElse: () => ids.first);
  }

  Future<void> _toggleSilent(String chatId, bool value) async {
    if (_currentUserId == null) return;

    try {
      await _supabase.from('chat_settings').upsert({
        'user_id': _currentUserId,
        'chat_id': chatId,
        'silent_notifications': value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,chat_id');

      if (value) {
        // إضافة إلى القائمة المحلية
        final otherId = _getOtherUserId(chatId);
        String chatName = 'محادثة';
        try {
          final userResponse = await _supabase
              .from('users')
              .select()
              .eq('uid', otherId)
              .maybeSingle();
          
          if (userResponse != null) {
            chatName = userResponse['name'] ?? 'مستخدم';
          }
        } catch (e) {
          chatName = otherId.substring(0, 8);
        }
        
        setState(() {
          _silentChats.add({
            'chatId': chatId,
            'otherId': otherId,
            'name': chatName,
            'silent': true,
          });
        });
      } else {
        // إزالة من القائمة المحلية
        setState(() {
          _silentChats.removeWhere((c) => c['chatId'] == chatId);
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '✅ تم تفعيل الإشعارات الصامتة للمحادثة' : '✅ تم إلغاء الإشعارات الصامتة للمحادثة'),
            backgroundColor: AppTheme.privooSuccess,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: ${e.toString()}'),
            backgroundColor: AppTheme.privooError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddChatDialog() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة محادثة للإشعارات الصامتة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'أدخل معرف المستخدم',
            border: OutlineInputBorder(),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooDeepPurple,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // إنشاء معرف محادثة
      final chatId = [_currentUserId, result]..sort();
      final chatIdStr = '${chatId[0]}_${chatId[1]}';
      await _toggleSilent(chatIdStr, true);
      await _loadSilentChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات الصامتة'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChatDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _silentChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد محادثات في وضع الإشعارات الصامتة',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يمكنك تفعيل الإشعارات الصامتة من داخل أي محادثة',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _silentChats.length,
                  itemBuilder: (context, index) {
                    final chat = _silentChats[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                          child: Icon(Icons.chat_bubble_outline, color: AppTheme.privooDeepPurple),
                        ),
                        title: Text(
                          chat['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          chat['chatId'],
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.notifications_off, color: AppTheme.privooSuccess),
                          onPressed: () => _toggleSilent(chat['chatId'], false),
                          tooltip: 'إلغاء الصامت',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}