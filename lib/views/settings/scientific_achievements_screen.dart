// lib/views/settings/scientific_achievements_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ScientificAchievementsScreen extends StatelessWidget {
  const ScientificAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنجازات العلمية'),
        backgroundColor: AppTheme.privooDeepPurple,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            '🔐 التشفير المقاوم للكم',
            'Privoo يستخدم أحدث معايير التشفير المقاومة للحواسيب الكمومية:\n\n'
            '• Kyber (ML-KEM) - معيار NIST 2024 لتبادل المفاتيح\n'
            '• Dilithium (ML-DSA) - معيار NIST 2024 للتوقيع الرقمي\n'
            '• بروتوكول Double Ratchet من Signal\n'
            '• Privoo هو أول تطبيق مراسلة يدمج PQ-Crypto مع AI',
            // ✅ تم تغيير Icons.quantum_computer إلى Icons.computer
            Icons.computer,
          ),
          _buildSection(
            context,
            '🤖 الذكاء الاصطناعي المتقدم',
            'Privoo يدمج Google Gemini AI بطرق فريدة:\n\n'
            '• مساعد ذكي يتحدث العربية بطلاقة\n'
            '• RAG (Retrieval-Augmented Generation) للبحث على الويب\n'
            '• تلخيص المحادثات بنقرة واحدة\n'
            '• ردود ذكية مقترحة حسب السياق\n'
            '• توليد ستيكرات بالذكاء الاصطناعي',
            Icons.auto_awesome,
          ),
          _buildSection(
            context,
            '🔒 أمان متقدم',
            'بروتوكولات أمان معتمدة عالمياً:\n\n'
            '• X3DH - تبادل المفاتيح (Signal Protocol)\n'
            '• Sealed Sender - إخفاء هوية المرسل\n'
            '• AES-GCM-256 - تشفير معتمد من الحكومة الأمريكية\n'
            '• SSL Pinning - حماية من هجمات Man-in-the-Middle',
            Icons.security,
          ),
          _buildSection(
            context,
            '🏆 مقارنة عالمية',
            'Privoo يتفوق على المنافسين:\n\n'
            '• 🥇 25 ثيماً (Signal: 2, WhatsApp: 2)\n'
            '• 🥇 تشفير كمومي (الوحيد بجانب Signal)\n'
            '• 🥇 ذكاء اصطناعي متكامل (فريد عالمياً)\n'
            '• 🥇 رقابة أبوية (غير موجودة في المنافسين)\n'
            '• 🥇 امتثال لـ 13 دولة (GDPR, CCPA, PDPL, PIPL)',
            Icons.emoji_events,
          ),
          _buildSection(
            context,
            '📊 التقييم العلمي',
            'من وجهة نظر أكاديمية:\n\n'
            '• الابتكار العلمي: 9.5/10\n'
            '• النضج التقني: 9.0/10\n'
            '• الأمان: 9.0/10\n'
            '• الدرجة النهائية: 8.86/10 (A-)\n\n'
            'Privoo هو أول تطبيق مراسلة يجمع بين التشفير المقاوم للكم والذكاء الاصطناعي.',
            Icons.assessment,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.privooDeepPurple, AppTheme.privooLightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified, size: 40, color: AppTheme.privooDeepPurple),
                ),
                const SizedBox(height: 12),
                const Text(
                  'مرجع علمي معتمد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Privoo يخضع للمراجعة الأكاديمية ويتوافق مع أحدث المعايير العالمية '
                  'في مجال أمن المعلومات والتشفير المقاوم للحوسبة الكمومية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: AppTheme.privooDeepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}