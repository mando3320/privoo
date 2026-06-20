// lib/views/users/users_list_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../main.dart';
import '../../services/contact_service.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<Contact> _phoneContacts = [];
  bool _isLoading = true;
  bool _isContactsLoading = false;
  bool _hasPhonePermission = false;
  String? _currentUserId;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    final user = SupabaseService().currentUser;
    _currentUserId = user?.id;
    _loadUsers();
    _loadContacts();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await SupabaseService().getAllUsers();
      
      final filteredUsers = users.where((u) => u.authId != _currentUserId).toList();

      setState(() {
        _users = filteredUsers;
        _filteredUsers = filteredUsers;
        _isLoading = false;
      });
      
      logger.i('✅ تم تحميل ${filteredUsers.length} مستخدم من Supabase');
    } catch (e) {
      logger.e('❌ فشل تحميل المستخدمين: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isContactsLoading = true);
    _hasPhonePermission = await ContactService.hasPermission();
    if (_hasPhonePermission) {
      _phoneContacts = await ContactService.getPhoneContacts();
      logger.i('✅ تم تحميل ${_phoneContacts.length} جهة اتصال');
    }
    setState(() => _isContactsLoading = false);
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user.name ?? '').toLowerCase();
        final phone = (user.phoneNumber ?? '').toLowerCase();
        return name.contains(lowerQuery) || phone.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _startChat(String targetUid, String name) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      _showSnackbar('الرجاء تسجيل الدخول أولاً');
      return;
    }

    try {
      // ✅ جلب المستخدمين بالـ auth_id للحصول على الـ id الحقيقي
      final currentUser = await SupabaseService().getUser(currentUserId);
      final targetUser = await SupabaseService().getUser(targetUid);
      
      if (currentUser == null || targetUser == null) {
        _showSnackbar('المستخدم غير موجود');
        return;
      }
      
      print('📤 currentUser.id: ${currentUser.id}');
      print('📤 targetUser.id: ${targetUser.id}');
      
      // ✅ استخدم الـ id (المفتاح الأساسي) مش auth_id
      final chatId = await SupabaseService().createChat([
        currentUser.id,
        targetUser.id,
      ]);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'receiverId': targetUser.id,  // ✅ استخدم id
            'name': name,
          },
        );
      }
    } catch (e) {
      logger.e('❌ خطأ في بدء المحادثة: $e');
      _showSnackbar('حدث خطأ: ${e.toString()}');
    }
  }

  void _inviteContact(Contact contact) {
    final phones = contact.phones.where((p) => p.number != null && p.number.isNotEmpty);
    if (phones.isEmpty) return;
    
    final phone = phones.first.number;
    final message = 'انضم إلى Privoo للتواصل مع ${contact.displayName}: https://privoo.app/download';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'دعوة جهة الاتصال',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.privooLightPurple.withValues(alpha: 0.2),
              child: Text(
                contact.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              contact.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (phone != null)
              Text(
                phone,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInviteButton(
                  icon: Icons.share,
                  label: 'مشاركة',
                  color: Colors.blue,
                  onTap: () {
                    Share.share(message);
                    Navigator.pop(context);
                  },
                ),
                if (phone != null)
                  _buildInviteButton(
                    icon: Icons.message,
                    label: 'رسالة نصية',
                    color: Colors.green,
                    onTap: () async {
                      final smsUri = Uri.parse('sms:$phone?body=$message');
                      if (await canLaunchUrl(smsUri)) {
                        await launchUrl(smsUri);
                      }
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: color.withValues(alpha: 0.1),
          child: IconButton(
            icon: Icon(icon, color: color, size: 28),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.privooLightPurple.withValues(alpha: 0.2),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      (user.name?.substring(0, 1) ?? 'U'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.privooSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name ?? 'مستخدم',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.phoneNumber ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (user.about != null)
              Text(
                user.about!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startChat(user.authId, user.name ?? 'مستخدم'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.privooLightPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('مراسلة', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    final phones = contact.phones.where((p) => p.number != null && p.number.isNotEmpty);
    if (phones.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final phone = phones.first.number;
    final isRegistered = _users.any((u) => u.phoneNumber == phone);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.privooLightPurple.withValues(alpha: 0.2),
          child: Text(
            contact.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          contact.displayName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          phone ?? 'لا يوجد رقم',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        trailing: isRegistered
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
                onPressed: () => _inviteContact(contact),
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمين'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.privooGold,
          labelColor: AppTheme.privooGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
            Tab(icon: Icon(Icons.contacts), text: 'جهات الاتصال'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUsers();
              _loadContacts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('لا يوجد مستخدمون', style: TextStyle(fontSize: 18)),
                                const SizedBox(height: 8),
                                Text('شارك التطبيق مع أصدقائك', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                          ),
                _isContactsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasPhonePermission
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.contacts_outlined, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('يحتاج التطبيق إلى إذن قراءة جهات الاتصال', style: TextStyle(fontSize: 16)),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadContacts, child: const Text('منح الإذن')),
                              ],
                            ),
                          )
                        : _phoneContacts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.contact_phone_outlined, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    const Text('لا توجد جهات اتصال', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text('أضف جهات اتصال إلى هاتفك', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _phoneContacts.length,
                                itemBuilder: (context, index) => _buildContactCard(_phoneContacts[index]),
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}