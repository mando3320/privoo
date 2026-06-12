// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../config/app_theme.dart';
import '../../services/security_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _userName;
  String? _userAvatar;
  List<Map<String, dynamic>> _recentChats = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    _loadUserData();
    _loadRecentChats();
    _checkDeviceSecurity();
  }

  Future<void> _checkDeviceSecurity() async {
    try {
      final securityChecker = SecurityChecker();
      final isSecure = await securityChecker.isDeviceSecure();
      if (!isSecure && mounted) {
        await securityChecker.showSecurityAlert(context);
      }
    } catch (e) {
      logger.w('⚠️ فشل التحقق من أمان الجهاز: $e');
    }
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
          .limit(50)
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
          'lastMessage': data['lastMessage'] ?? 'ابدأ المحادثة',
          'timestamp': data['lastMessageTime'],
          'unreadCount': data['unreadCount']?[user.uid] ?? 0,
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

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: _userAvatar != null ? NetworkImage(_userAvatar!) : null,
              child: _userAvatar == null
                  ? Icon(Icons.person, size: 16, color: AppTheme.privooDeepPurple)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privoo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_userName != null)
                  Text(
                    _userName!,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.privooGold,
          labelColor: AppTheme.privooGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'المحادثات'),
            Tab(icon: Icon(Icons.people), text: 'المجموعات'),
            Tab(icon: Icon(Icons.contact_phone), text: 'جهات الاتصال'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب المحادثات
          _buildChatsTab(),
          
          // تبويب المجموعات
          _buildGroupsTab(),
          
          // تبويب جهات الاتصال
          _buildContactsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: AppTheme.privooLightPurple,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.privooDeepPurple.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد محادثات بعد',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ محادثة جديدة مع صديق',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add),
              label: const Text('محادثة جديدة'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecentChats,
      child: ListView.builder(
        itemCount: _recentChats.length,
        itemBuilder: (context, index) {
          final chat = _recentChats[index];
          return Dismissible(
            key: Key(chat['chatId']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chat['chatId'])
                  .delete();
              _loadRecentChats();
            },
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.privooLightPurple.withValues(alpha: 0.2),
                    backgroundImage: chat['avatar'] != null ? NetworkImage(chat['avatar']) : null,
                    child: chat['avatar'] == null
                        ? Text(
                            (chat['name']?.substring(0, 1) ?? 'U'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (chat['unreadCount'] > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${chat['unreadCount']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                chat['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                chat['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chat['unreadCount'] > 0 
                      ? AppTheme.privooGold 
                      : Colors.grey.shade600,
                  fontWeight: chat['unreadCount'] > 0 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(chat['timestamp']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (chat['unreadCount'] > 0)
                    const SizedBox(height: 4),
                  if (chat['unreadCount'] > 0)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.privooGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () => _openChat(
                chat['chatId'],
                chat['receiverId'],
                chat['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: AppTheme.privooDeepPurple.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'المجموعات',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة المجموعات قريباً',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-group'),
            icon: const Icon(Icons.group_add),
            label: const Text('إنشاء مجموعة'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadContacts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final contacts = snapshot.data ?? [];
        
        if (contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.contact_phone_outlined,
                  size: 80,
                  color: AppTheme.privooDeepPurple.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد جهات اتصال',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'ستظهر جهات اتصالك هنا',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.privooLightPurple.withValues(alpha: 0.2),
                child: Text(
                  (contact['name']?.substring(0, 1) ?? 'C'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(contact['name']),
              subtitle: Text(contact['phone'] ?? ''),
              trailing: contact['isRegistered'] == true
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.privooSuccess.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'مسجل',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.privooSuccess,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => _inviteContact(contact['phone']),
                      child: const Text('دعوة'),
                    ),
              onTap: () {
                if (contact['isRegistered'] == true) {
                  // بدء محادثة مع المستخدم المسجل
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadContacts() async {
    final currentUserPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .limit(100)
        .get();
    
    final registeredPhones = usersSnapshot.docs
        .map((doc) => doc.data()['phoneNumber'] ?? doc.data()['phone'] ?? '')
        .toSet();
    
    // هنا يمكن إضافة جهات اتصال الهاتف
    return [
      {'name': 'مستخدم تجريبي', 'phone': '+201234567890', 'isRegistered': true},
      {'name': 'أحمد', 'phone': '+201234567891', 'isRegistered': false},
    ];
  }

  void _inviteContact(String? phone) {
    // دالة دعوة جهة الاتصال
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الدعوة')),
    );
  }
}