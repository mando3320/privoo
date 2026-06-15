// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../config/app_theme.dart';
import '../../services/security_checker.dart';
import '../../services/contact_service.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    print('🔵🔵🔵 جاري تشغيل _loadUserData... 🔵🔵🔵');
    
    if (user != null) {
      print('🆔 Current user UID: ${user.uid}');
      if (mounted) {
        setState(() {
          _userUid = user.uid;
        });
      }
      
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        
        print('📄 المستند موجود في السيرفر؟: ${doc.exists}');
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _userName = data['name'] ?? user.phoneNumber ?? 'المستخدم';
              _userAvatar = data['avatarUrl'];
            });
          }
          print('✅ تم تحميل بيانات Firestore بنجاح: name=$_userName');
        } else {
          print('⚠️ المستند غير موجود في Firestore! سيتم استخدام بيانات الهاتف مؤقتاً.');
          if (mounted) {
            setState(() {
              _userName = user.phoneNumber ?? 'المستخدم الجديد';
            });
          }
        }
      } catch (e) {
        print('❌ خطأ في طلب Firestore (جلب بيانات المستخدم): $e');
        if (mounted) {
          setState(() {
            _userName = user.phoneNumber ?? 'المستخدم';
          });
        }
      }
    } else {
      print('⚠️ لا يوجد مستخدم مسجل دخول (User is Null)');
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
      
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();
      
      final registeredPhones = usersSnapshot.docs
          .map((doc) => doc.data()['phoneNumber'] ?? '')
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
      
      logger.i('📱 تم تحميل ${result.length} جهة اتصال (${result.where((c) => c['isRegistered'] == true).length} مسجل)');
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return;

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: contact['phone'])
        .limit(1)
        .get();

    if (usersSnapshot.docs.isEmpty) {
      _showSnackbar('لم يتم العثور على المستخدم');
      return;
    }

    final targetUser = usersSnapshot.docs.first;
    final targetUid = targetUser.id;
    final targetName = targetUser.data()['name'] ?? contact['name'];

    final chatId = currentUserId.compareTo(targetUid) < 0
        ? '${currentUserId}_$targetUid'
        : '${targetUid}_$currentUserId';

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, targetUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

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