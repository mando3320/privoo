// views/auth/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/key_exchange_service.dart';

/// شاشة عرض بصمة الأمان (Safety Number) للمستخدم الحالي ومقارنتها مع طرف آخر
/// تُستخدم للتحقق من هوية الطرف الآخر ومنع هجمات Man-in-the-Middle
class VerifyScreen extends ConsumerStatefulWidget {
  /// معرف المستخدم الذي نريد التحقق منه (الطرف الآخر)
  final String peerId;
  /// اسم الطرف الآخر للعرض
  final String peerName;

  const VerifyScreen({
    super.key,
    required this.peerId,
    required this.peerName,
  });

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  late Future<String?> _myFingerprintFuture;
  late Future<String?> _peerFingerprintFuture;

  @override
  void initState() {
    super.initState();
    _loadFingerprints();
  }

  void _loadFingerprints() {
    final authController = ref.read(authControllerProvider.notifier);
    _myFingerprintFuture = authController.getMyFingerprint();
    // ملاحظة: الحصول على بصمة الطرف الآخر يتطلب من الطرف الآخر مشاركتها.
    // في التنفيذ الحالي، سنحصل عليها من خلال AuthService و KeyExchangeService
    _peerFingerprintFuture = _getPeerFingerprint();
  }

  Future<String?> _getPeerFingerprint() async {
    try {
      final keyExchange = KeyExchangeService();
      final peerPublicKey = await keyExchange.fetchPeerIdentityPublicKey(widget.peerId);
      final fingerprint = await KeyExchangeService.pubFingerprint(peerPublicKey.bytes, bytes: 16);
      return fingerprint;
    } catch (e) {
      debugPrint('خطأ في جلب بصمة الطرف الآخر: $e');
      return null;
    }
  }

  /// التحقق من تطابق البصمة مع الطرف الآخر
  Future<bool> _verifyFingerprint() async {
    final myFingerprint = await _myFingerprintFuture;
    final peerFingerprint = await _peerFingerprintFuture;
    
    if (myFingerprint == null || peerFingerprint == null) return false;
    return myFingerprint == peerFingerprint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الهوية'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([_myFingerprintFuture, _peerFingerprintFuture]),
        builder: (context, AsyncSnapshot<List<String?>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFingerprints,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final myFingerprint = snapshot.data?[0];
          final peerFingerprint = snapshot.data?[1];

          if (myFingerprint == null || peerFingerprint == null) {
            return const Center(
              child: Text('لا يمكن عرض بصمة الأمان. تأكد من الاتصال بالإنترنت.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // أيقونة بصمة
                const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                
                // شرح
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'للتأكد من أن اتصالك آمن وعدم وجود وسيط، قارن بصمة الأمان هذه مع بصمة الشخص الذي تتحدث معه. '
                    'إذا كانت البصمتان متطابقتان، فالاتصال آمن.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
                // بصمة المستخدم الحالي
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'بصمتك أنت',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _formatFingerprint(myFingerprint),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // بصمة الطرف الآخر
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'بصمة ${widget.peerName}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _formatFingerprint(peerFingerprint),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // زر التحقق والمطابقة
                ElevatedButton.icon(
                  onPressed: () async {
                    final isMatch = await _verifyFingerprint();
                    if (!mounted) return;
                    final ctx = context;
                    if (isMatch) {
                      // بصمة متطابقة - اتصال آمن
                      showDialog(
                        context: ctx,
                        builder: (context) => AlertDialog(
                          title: const Text('✅ اتصال آمن'),
                          content: const Text('البصمة متطابقة. الاتصال مع هذا المستخدم آمن ومشفر بالكامل.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('حسناً'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // بصمة غير متطابقة - خطر
                      showDialog(
                        context: ctx,
                        builder: (context) => AlertDialog(
                          title: const Text('⚠️ تحذير أمني!'),
                          content: const Text(
                            'البصمة غير متطابقة!\n'
                            'قد يكون هناك هجوم Man-in-the-Middle.\n'
                            'لا ترسل أي معلومات حساسة وتأكد من الهوية عبر قناة أخرى.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('فهمت الخطر'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified),
                  label: const Text('التحقق من تطابق البصمة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // زر إلغاء
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('إلغاء'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// تنسيق البصمة لتكون مقروءة بشكل أفضل
  String _formatFingerprint(String fingerprint) {
    // إزالة النقطتين المزدوجتين إن وجدت ثم إضافتها بشكل منظم كل 4 أحرف
    String cleaned = fingerprint.replaceAll(':', '');
    List<String> chunks = [];
    for (int i = 0; i < cleaned.length; i += 4) {
      int end = i + 4;
      if (end > cleaned.length) end = cleaned.length;
      chunks.add(cleaned.substring(i, end));
    }
    return chunks.join(' ');
  }
}//None