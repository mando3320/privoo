// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  String? _userAvatar;
  List<Map<String, dynamic>> _recentChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentChats();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userName = doc.data()?['name'] ?? user.phoneNumber ?? 'المستخدم';
            _userAvatar = doc.data()?['avatarUrl'];
          });
        } else {
          setState(() {
            _userName = user.phoneNumber ?? 'المستخدم';
          });
        }
      } catch (e) {
        logger.e('❌ فشل تحميل بيانات المستخدم: $e');
        setState(() {
          _userName = user.phoneNumber ?? 'المستخدم';
        });
      }
    }
  }

  Future<void> _loadRecentChats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final querySnapshot = await chatsRef
          .where('participants', arrayContains: user.uid)
          .limit(20)
          .get();

      final chats = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherId = participants.firstWhere((id) => id != user.uid);
        
        String otherName = 'مستخدم';
        String? otherAvatar;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .get();
          if (userDoc.exists) {
            otherName = userDoc.data()?['name'] ?? 'مستخدم';
            otherAvatar = userDoc.data()?['avatarUrl'];
          }
        } catch (e) {
          logger.e('❌ فشل تحميل اسم المستخدم الآخر: $e');
        }

        chats.add({
          'chatId': doc.id,
          'receiverId': otherId,
          'name': otherName,
          'avatar': otherAvatar,
          'lastMessage': data['lastMessage'] ?? '',
          'timestamp': data['lastMessageTime'],
        });
      }

      chats.sort((a, b) => (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0
          .compareTo((a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));

      setState(() {
        _recentChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('❌ فشل تحميل المحادثات: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startNewChat() async {
    final result = await Navigator.pushNamed(context, '/users');
    if (result != null && mounted) {
      _loadRecentChats();
    }
  }

  void _openChat(String chatId, String receiverId, String name) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatId,
        'receiverId': receiverId,
        'name': name,
      },
    ).then((_) => _loadRecentChats());
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooError,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('تأكيد الخروج'),
                content: const Text('هل تريد الخروج من التطبيق؟'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.privooError,
                    ),
                    child: const Text('خروج'),
                  ),
                ],
              ),
            ) ?? false;

        if (shouldExit) {
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Privoo'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // البروفايل المصغر
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.privooLightBg,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: _userAvatar != null
                                ? NetworkImage(_userAvatar!)
                                : null,
                            child: _userAvatar == null
                                ? Icon(Icons.person, size: 30, color: AppTheme.privooDeepPurple)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName ?? 'مرحباً بك',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'مرحباً بك في Privoo',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _startNewChat,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('محادثة جديدة'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  // قائمة المحادثات
                  Expanded(
                    child: _recentChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: AppTheme.privooDeepPurple.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد محادثات بعد',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ محادثة جديدة مع صديق',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recentChats.length,
                            itemBuilder: (context, index) {
                              final chat = _recentChats[index];
                              return ListTile(
                                leading: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: chat['avatar'] != null
                                        ? NetworkImage(chat['avatar'])
                                        : null,
                                    child: chat['avatar'] == null
                                        ? Icon(Icons.person, color: AppTheme.privooDeepPurple)
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  chat['name'] ?? 'مستخدم',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  chat['lastMessage'] ?? 'ابدأ المحادثة',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: chat['timestamp'] != null
                                    ? Text(
                                        _formatTime(chat['timestamp']),
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                onTap: () => _openChat(
                                  chat['chatId'],
                                  chat['receiverId'],
                                  chat['name'],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}