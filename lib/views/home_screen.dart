// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../config/app_theme.dart';
import '../../services/security_checker.dart';
import '../../services/contact_service.dart';
import '../../services/supabase_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _userName;
  String? _userAvatar;
  String? _userUid;
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
    
    _initializeHomeScreen();
    _checkDeviceSecurity();
  }

  Future<void> _initializeHomeScreen() async {
    setState(() => _isLoading = true);
    try {
      await _loadUserData();
      await _loadRecentChats();
    } catch (e) {
      print('❌ خطأ أثناء تهيئة الشاشة الرئيسية: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    final user = SupabaseService().currentUser;
    print('🔵🔵🔵 جاري تشغيل _loadUserData... 🔵🔵🔵');
    
    if (user != null) {
      print('🆔 Current user UID: ${user.id}');
      if (mounted) {
        setState(() {
          _userUid = user.id;
        });
      }
      
      try {
        final userData = await SupabaseService().getUser(user.id);
        
        if (userData != null) {
          if (mounted) {
            setState(() {
              _userName = userData.name ?? 'المستخدم';
              _userAvatar = userData.avatarUrl;
            });
          }
          print('✅ تم تحميل بيانات Supabase بنجاح: name=$_userName');
        } else {
          print('⚠️ المستخدم غير موجود في Supabase!');
          if (mounted) {
            setState(() {
              _userName = 'المستخدم الجديد';
            });
          }
        }
      } catch (e) {
        print('❌ خطأ في جلب بيانات المستخدم: $e');
        if (mounted) {
          setState(() {
            _userName = 'المستخدم';
          });
        }
      }
    } else {
      print('⚠️ لا يوجد مستخدم مسجل دخول (User is Null)');
    }
  }

  Future<void> _loadRecentChats() async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    try {
      final chats = await SupabaseService().getUserChats(user.id);
      
      final chatList = chats.map((chat) {
        final otherId = chat.members.firstWhere((id) => id != user.id);
        return {
          'chatId': chat.chatId,
          'receiverId': otherId,
          'name': 'مستخدم', // TODO: جلب اسم المستخدم الآخر
          'avatar': null,
          'lastMessage': chat.lastMessage ?? 'ابدأ المحادثة',
          'timestamp': chat.lastMessageTime ?? chat.createdAt,
          'unreadCount': chat.unreadCount[user.id] ?? 0,
        };
      }).toList();

      setState(() {
        _recentChats = chatList;
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
      await SupabaseService().signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    if (timestamp.day == now.day && timestamp.month == now.month) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day}/${timestamp.month}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
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
          );
          return shouldExit ?? false;
        }
        _tabController.animateTo(0);
        return false;
      },
      child: Scaffold(
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
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
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
            _buildChatsTab(),
            _buildGroupsTab(),
            _buildContactsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _startNewChat,
          backgroundColor: AppTheme.privooLightPurple,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
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
              // TODO: حذف المحادثة من Supabase
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

  Future<List<Map<String, dynamic>>> _loadRealContacts() async {
    try {
      final hasPermission = await ContactService.hasPermission();
      if (!hasPermission) {
        logger.w('⚠️ لا يوجد إذن لقراءة جهات الاتصال');
        return [];
      }
      
      final phoneContacts = await ContactService.getPhoneContacts();
      if (phoneContacts.isEmpty) {
        logger.i('📱 لا توجد جهات اتصال في الهاتف');
        return [];
      }
      
      final users = await SupabaseService().getAllUsers();
      final registeredPhones = users
          .map((u) => u.phoneNumber ?? '')
          .where((phone) => phone.isNotEmpty)
          .toSet();
      
      final List<Map<String, dynamic>> result = [];
      
      for (var contact in phoneContacts) {
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
        if (phone != null && phone.isNotEmpty) {
          result.add({
            'name': contact.displayName,
            'phone': phone,
            'isRegistered': registeredPhones.contains(phone),
          });
        }
      }
      
      logger.i('📱 تم تحميل ${result.length} جهة اتصال');
      return result;
    } catch (e) {
      logger.e('❌ فشل تحميل جهات الاتصال: $e');
      return [];
    }
  }

  Widget _buildContactsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRealContacts(),
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
                const Text(
                  'لا توجد جهات اتصال',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'أضف جهات اتصال إلى هاتفك',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('تحديث'),
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
              title: Text(contact['name'] ?? ''),
              subtitle: Text(contact['phone'] ?? ''),
              trailing: contact['isRegistered'] == true
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.privooSuccess.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: AppTheme.privooSuccess),
                          const SizedBox(width: 4),
                          Text(
                            'مسجل',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.privooSuccess,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => _inviteContact(contact['phone']),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.privooGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'دعوة',
                        style: TextStyle(color: AppTheme.privooGold),
                      ),
                    ),
              onTap: () {
                if (contact['isRegistered'] == true) {
                  _startChatWithContact(contact);
                }
              },
            );
          },
        );
      },
    );
  }

  void _startChatWithContact(Map<String, dynamic> contact) async {
    final currentUser = SupabaseService().currentUser;
    final currentUserId = currentUser?.id;
    if (currentUserId == null) return;

    // ✅ البحث عن المستخدم برقم الهاتف
    final users = await SupabaseService().getAllUsers();
    final targetUser = users.firstWhere(
      (u) => u.phoneNumber == contact['phone'],
      orElse: () => null,
    );
    
    if (targetUser == null) {
      _showSnackbar('لم يتم العثور على المستخدم');
      return;
    }

    final targetUid = targetUser.authId;
    final targetName = targetUser.name ?? contact['name'];

    // ✅ إنشاء محادثة
    final chatId = await SupabaseService().createChat([currentUserId, targetUid]);

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'receiverId': targetUid,
          'name': targetName,
        },
      );
    }
  }

  void _inviteContact(String? phone) {
    final message = 'انضم إلى Privoo للتواصل معي: https://privoo.app/download';
    
    if (phone != null && phone.isNotEmpty) {
      final smsUri = Uri.parse('sms:$phone?body=$message');
      canLaunchUrl(smsUri).then((canLaunch) {
        if (canLaunch) {
          launchUrl(smsUri);
        } else {
          Share.share(message);
        }
      });
    } else {
      Share.share(message);
    }
    
    _showSnackbar('تم إرسال الدعوة');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}