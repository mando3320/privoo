// lib/views/users/users_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../main.dart';
import '../../services/contact_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Contact> _phoneContacts = [];
  bool _isLoading = true;
  bool _isContactsLoading = false;
  bool _hasPhonePermission = false;
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserPhone = user?.phoneNumber;
    _loadUsers();
    _loadContacts();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final currentUserPhone = _currentUserPhone;
      
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();

      final users = <Map<String, dynamic>>[];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final userPhone = data['phoneNumber'] ?? data['phone'] ?? '';
        
        if (userPhone != currentUserPhone) {
          users.add({
            'id': doc.id,
            'name': data['name'] ?? 'مستخدم',
            'phone': userPhone,
            'avatarUrl': data['avatarUrl'],
            'isActive': data['isActive'] ?? true,
            'source': 'firebase',
          });
        }
      }

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      
      logger.i('✅ تم تحميل ${users.length} مستخدم من Firebase');
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
        final name = (user['name'] ?? '').toLowerCase();
        final phone = (user['phone'] ?? '').toLowerCase();
        return name.contains(lowerQuery) || phone.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _startChat(String userId, String name) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return;

    final chatId = currentUserId.compareTo(userId) < 0
        ? '${currentUserId}_$userId'
        : '${userId}_$currentUserId';

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, userId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'receiverId': userId,
          'name': name,
        },
      );
    }
  }

  void _inviteContact(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
    final message = 'انضم إلى Privoo للتواصل مع ${contact.displayName}: https://privoo.app/download';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'دعوة جهة الاتصال',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('ادعُ ${contact.displayName} إلى Privoo عبر:', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInviteButton(
                    icon: Icons.share,
                    label: 'مشاركة',
                    onTap: () {
                      Share.share(message);
                      Navigator.pop(context);
                    },
                  ),
                  if (phone != null)
                    _buildInviteButton(
                      icon: Icons.message,
                      label: 'رسالة نصية',
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
      ),
    );
  }

  Widget _buildInviteButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: IconButton(
            icon: Icon(icon, color: Colors.blue),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildContactsSection() {
    if (_isContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (!_hasPhonePermission) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.contacts, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('يحتاج التطبيق إلى إذن قراءة جهات الاتصال'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContacts,
              child: const Text('منح الإذن'),
            ),
          ],
        ),
      );
    }
    
    if (_phoneContacts.isEmpty) {
      return const Center(child: Text('لا توجد جهات اتصال في هاتفك'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '📱 جهات الاتصال',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _phoneContacts.length,
          itemBuilder: (context, index) {
            final contact = _phoneContacts[index];
            final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
            final isRegistered = _users.any((u) => u['phone'] == phone);
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  contact.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(contact.displayName),
              subtitle: Text(phone ?? 'لا يوجد رقم'),
              trailing: isRegistered
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : OutlinedButton(
                      onPressed: () => _inviteContact(contact),
                      child: const Text('دعوة'),
                    ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمين'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUsers();
              _loadContacts();
            },
            tooltip: 'تحديث',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ قسم جهات الاتصال
                        _buildContactsSection(),
                        
                        // ✅ قسم المستخدمين المسجلين
                        if (_filteredUsers.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '✅ مستخدمين Privoo',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(
                                    (user['name']?.substring(0, 1) ?? 'U'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  user['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(user['phone'] ?? ''),
                                trailing: ElevatedButton(
                                  onPressed: () => _startChat(user['id'], user['name']),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('محادثة'),
                                ),
                              );
                            },
                          ),
                        ],
                        
                        if (_filteredUsers.isEmpty && _phoneContacts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('لا يوجد مستخدمون أو جهات اتصال'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}