// lib/views/settings/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privoo/controllers/chat_controller.dart';
import 'package:privoo/controllers/app_controller.dart';
import '../../config/app_theme.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late bool _useQuantumResistance;
  late bool _useSealedSender;
  late bool _lockApp;
  late bool _hideLastSeen;
  late bool _hideOnlineStatus;
  late bool _readReceipts;
  late bool _dataSaverEnabled;

  @override
  void initState() {
    super.initState();
    final chatController = ref.read(chatControllerProvider);
    _useQuantumResistance = chatController.useQuantumResistance;
    _useSealedSender = chatController.useSealedSender;
    _lockApp = ref.read(appControllerProvider).lockApp;
    _hideLastSeen = ref.read(appControllerProvider).hideLastSeen;
    _hideOnlineStatus = ref.read(appControllerProvider).hideOnlineStatus;
    _readReceipts = ref.read(appControllerProvider).readReceipts;
    _dataSaverEnabled = ref.read(appControllerProvider).dataSaverEnabled;
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.privooError : AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatController = ref.read(chatControllerProvider.notifier);
    final appController = ref.read(appControllerProvider.notifier);
    final isQuantumSession = ref.read(chatControllerProvider).isQuantumSession;
    final quantumFingerprint = ref.read(chatControllerProvider).quantumFingerprint;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الخصوصية'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ============================================================
          // 🔬 المقاومة الكمومية (Quantum Resistance)
          // ============================================================
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // ✅ تم تغيير Icons.quantum_computer إلى Icons.computer
                  child: const Icon(Icons.computer, size: 24, color: AppTheme.privooDeepPurple),
                ),
                const SizedBox(width: 12),
                Text(
                  '🔬 أمان متقدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.privooDeepPurple,
                  ),
                ),
              ],
            ),
          ),
          
          SwitchListTile(
            title: const Text('المقاومة الكمومية (Quantum Resistance)'),
            subtitle: const Text('حماية ضد هجمات الحواسيب الكمومية المستقبلية\n(قد تؤثر قليلاً على الأداء)'),
            value: _useQuantumResistance,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _useQuantumResistance = value);
              await chatController.toggleQuantumResistance(value);
              _showSnackbar(value ? '✅ تم تفعيل المقاومة الكمومية' : '⚠️ تم إيقاف المقاومة الكمومية');
            },
          ),
          
          if (isQuantumSession)
            ListTile(
              leading: Icon(Icons.fingerprint, color: AppTheme.privooDeepPurple),
              title: const Text('بصمة الجلسة الكمومية'),
              subtitle: Text(quantumFingerprint.isNotEmpty ? quantumFingerprint : 'غير متاحة'),
              onTap: () => _showQuantumFingerprintDialog(),
            ),
            
          ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.privooInfo),
            title: const Text('ما هي المقاومة الكمومية؟'),
            subtitle: const Text('تستخدم خوارزميات Kyber و Dilithium للحماية من الحواسيب الكمومية المستقبلية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showQuantumInfoDialog(),
          ),
          
          const Divider(),
          
          // ============================================================
          // 🤫 إخفاء الهوية (Sealed Sender)
          // ============================================================
          SwitchListTile(
            title: const Text('إخفاء هوية المرسل (Sealed Sender)'),
            subtitle: const Text('لا يظهر اسمك كمرسل للرسالة (الخادم لا يرى من أرسل)'),
            value: _useSealedSender,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _useSealedSender = value);
              await chatController.toggleSealedSender(value);
              _showSnackbar(value ? '✅ تم تفعيل إخفاء هوية المرسل' : '⚠️ تم إيقاف إخفاء هوية المرسل');
            },
          ),
          
          const Divider(),
          
          // ============================================================
          // 🔒 قفل التطبيق
          // ============================================================
          SwitchListTile(
            title: const Text('قفل التطبيق (بصمة / PIN)'),
            subtitle: const Text('يتطلب المصادقة لفتح التطبيق'),
            value: _lockApp,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _lockApp = value);
              await appController.toggleLockApp(value);
              _showSnackbar(value ? '✅ تم تفعيل قفل التطبيق' : '⚠️ تم إيقاف قفل التطبيق');
            },
          ),
          
          const Divider(),
          
          // ============================================================
          // 👁️ إخفاء آخر ظهور
          // ============================================================
          SwitchListTile(
            title: const Text('إخفاء آخر ظهور'),
            subtitle: const Text('لا يظهر للآخرين آخر ظهور لك'),
            value: _hideLastSeen,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _hideLastSeen = value);
              await appController.toggleHideLastSeen(value);
              _showSnackbar(value ? '✅ تم إخفاء آخر ظهور' : '⚠️ تم إظهار آخر ظهور');
            },
          ),
          
          // ============================================================
          // 🟢 إخفاء حالة النشاط
          // ============================================================
          SwitchListTile(
            title: const Text('إخفاء حالة النشاط'),
            subtitle: const Text('لا يظهر للآخرين أنك متصل حالياً'),
            value: _hideOnlineStatus,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _hideOnlineStatus = value);
              await appController.toggleHideOnlineStatus(value);
              _showSnackbar(value ? '✅ تم إخفاء حالة النشاط' : '⚠️ تم إظهار حالة النشاط');
            },
          ),
          
          // ============================================================
          // 👁️ تأكيد قراءة الرسائل
          // ============================================================
          SwitchListTile(
            title: const Text('إظهار تأكيد قراءة الرسائل'),
            subtitle: const Text('يظهر للآخرين أنك قرأت رسائلهم'),
            value: _readReceipts,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _readReceipts = value);
              await appController.toggleReadReceipts(value);
              _showSnackbar(value ? '✅ تم تفعيل تأكيد القراءة' : '⚠️ تم إيقاف تأكيد القراءة');
            },
          ),
          
          const Divider(),
          
          // ============================================================
          // 💾 توفير البيانات
          // ============================================================
          SwitchListTile(
            title: const Text('وضع توفير البيانات'),
            subtitle: const Text('تقليل استهلاك البيانات (تحميل الصور بجودة أقل)'),
            value: _dataSaverEnabled,
            activeColor: AppTheme.privooDeepPurple,
            onChanged: (value) async {
              setState(() => _dataSaverEnabled = value);
              await appController.toggleDataSaver(value);
              _showSnackbar(value ? '✅ تم تفعيل توفير البيانات' : '⚠️ تم إيقاف توفير البيانات');
            },
          ),
        ],
      ),
    );
  }

  void _showQuantumInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            // ✅ تم تغيير Icons.quantum_computer إلى Icons.computer
            Icon(Icons.computer, color: AppTheme.privooDeepPurple),
            const SizedBox(width: 8),
            const Text('المقاومة الكمومية'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Kyber-768 (ML-KEM): تبادل المفاتيح المقاوم كمومياً'),
            SizedBox(height: 8),
            Text('• Dilithium (ML-DSA): توقيعات رقمية مقاومة كمومياً'),
            SizedBox(height: 8),
            Text('• Hybrid Key Exchange: دمج X25519 + Kyber'),
            SizedBox(height: 8),
            Text('• آمن ضد هجمات الحواسيب الكمومية المستقبلية'),
            SizedBox(height: 8),
            Text('• متوافق مع معايير NIST'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.privooDeepPurple,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showQuantumFingerprintDialog() {
    final quantumFingerprint = ref.read(chatControllerProvider).quantumFingerprint;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppTheme.privooDeepPurple),
            const SizedBox(width: 8),
            const Text('بصمة الجلسة الكمومية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بصمة المفتاح الكمومي لهذه المحادثة:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                quantumFingerprint.isNotEmpty ? quantumFingerprint : 'غير متاحة',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: AppTheme.privooDeepPurple,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'إذا كانت هذه البصمة مختلفة عن بصمة الطرف الآخر، فهناك خطر وجود هجوم MITM.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.privooDeepPurple,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}