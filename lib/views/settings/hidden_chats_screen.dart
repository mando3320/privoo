// lib/views/settings/hidden_chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/app_theme.dart';

class HiddenChatsScreen extends ConsumerStatefulWidget {
  const HiddenChatsScreen({super.key});

  @override
  ConsumerState<HiddenChatsScreen> createState() => _HiddenChatsScreenState();
}

class _HiddenChatsScreenState extends ConsumerState<HiddenChatsScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isBiometricAvailable = false;
  String? _errorMessage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      setState(() {
        _isBiometricAvailable = isAvailable || isDeviceSupported;
        _isLoading = false;
      });
      
      if (_isBiometricAvailable) {
        await _authenticate();
      } else {
        setState(() {
          _errorMessage = 'جهازك لا يدعم المصادقة البيومترية';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'تحقق من هويتك لعرض المحادثات المخفية',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticated = authenticated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _unhideChat(String chatId, String chatName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إظهار المحادثة'),
        content: Text('هل أنت متأكد من إظهار المحادثة "$chatName"؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooSuccess,
            ),
            child: const Text('إظهار'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('hidden_chats')
          .doc(chatId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إظهار المحادثة "$chatName"'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم${diff.inDays > 1 ? 'ين' : ''}';
    }
    if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة${diff.inHours > 1 ? 'ين' : ''}';
    }
    if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة${diff.inMinutes > 1 ? 'ين' : ''}';
    }
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات المخفية'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthenticated
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage ?? 'المحادثات المخفية محمية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.privooDeepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isBiometricAvailable
                            ? 'استخدم بصمتك أو وجهك للوصول إليها'
                            : 'يرجى تفعيل المصادقة البيومترية في إعدادات الجهاز',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                      if (_isBiometricAvailable)
                        ElevatedButton.icon(
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('التحقق من الهوية'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('hidden_chats')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppTheme.privooError),
                            const SizedBox(height: 16),
                            Text('حدث خطأ: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final chats = snapshot.data?.docs ?? [];

                    if (chats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 80, color: AppTheme.privooDeepPurple.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد محادثات مخفية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يمكنك إخفاء المحادثات من داخل أي محادثة',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final doc = chats[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final chatName = data['chatName'] ?? 'محادثة مخفية';
                        final timestamp = (data['hiddenAt'] as Timestamp?)?.toDate();

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
                              child: Icon(Icons.lock, color: AppTheme.privooDeepPurple),
                            ),
                            title: Text(
                              chatName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: timestamp != null
                                ? Text(
                                    'مخفية ${_formatDate(timestamp)}',
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.visibility, color: AppTheme.privooSuccess),
                              onPressed: () => _unhideChat(doc.id, chatName),
                              tooltip: 'إظهار المحادثة',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}