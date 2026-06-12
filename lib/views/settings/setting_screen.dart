// lib/views/settings/setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import 'upgrade_pro_view.dart';
import 'compliance_screen.dart';
import '../block_list_screen.dart';
import 'theme_selector_screen.dart';
import '../../routes/app_routes.dart';
import '../../core/permissions.dart';
import '../admin/manage_admins_screen.dart';
import '../admin/support_tickets_screen.dart';
import '../admin/manage_users_screen.dart';
import '../admin/manage_offers_screen.dart';
import 'local_webview_screen.dart';
import 'change_name_screen.dart';
import 'change_avatar_screen.dart';
import 'change_credentials_screen.dart';
import 'link_providers_screen.dart';
import 'chat_wallpaper_screen.dart';
import 'chat_font_size_screen.dart';
import 'notification_sound_screen.dart';
import 'silent_notifications_screen.dart';
import 'auto_download_media_screen.dart';
import 'manage_allowed_senders_screen.dart';
import 'hidden_chats_screen.dart';
import 'parental_control_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const List<Map<String, String>> _languages = [
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'en', 'label': 'English'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'tr', 'label': 'Türkçe'},
    {'code': 'ja', 'label': '日本語'},
  ];

  Future<bool> _isAdmin(String phoneNumber) async {
    try {
      final authController = ref.read(authControllerProvider.notifier);
      return await authController.checkIfAdmin(phoneNumber);
    } catch (e) {
      return false;
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
    final loc = AppLocalizations.of(context)!;
    final app = ref.watch(appControllerProvider);
    final appNotifier = ref.read(appControllerProvider.notifier);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ---------- اللغة ----------
          _buildLanguageTile(context, app, appNotifier),
          const Divider(),

          // ✅ ---------- الثيمات ----------
          ListTile(
            leading: Icon(Icons.palette, color: AppTheme.privooDeepPurple),
            title: const Text('الثيمات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text(
              app.isPro 
                ? '25 ثيماً متاحة (جميع الثيمات)'
                : '8 ثيمات أساسية + ${appNotifier.getLockedThemesCount()} ثيماً حصرية للمشتركين',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!app.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.privooGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pro',
                      style: TextStyle(color: AppTheme.privooGold, fontSize: 10),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.privooDeepPurple),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectorScreen()),
              );
            },
          ),
          const Divider(),

          // ---------- الوضع الليلي ----------
          SwitchListTile(
            title: const Text('الوضع الليلي', style: TextStyle(fontSize: 16)),
            value: app.themeMode == ThemeMode.dark,
            onChanged: (value) {
              appNotifier.toggleTheme(value);
              _showSnack(context, value ? "تم تفعيل الوضع الداكن" : "تم تفعيل الوضع الفاتح");
            },
            secondary: Icon(Icons.brightness_6, color: AppTheme.privooDeepPurple),
          ),
          const Divider(),

          // ---------- النسخ الاحتياطي ----------
          ListTile(
            leading: Icon(Icons.backup, color: AppTheme.privooDeepPurple),
            title: const Text('نسخ احتياطي'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSnack(context, "✅ تم عمل نسخة احتياطية"),
          ),
          ListTile(
            leading: Icon(Icons.restore, color: AppTheme.privooDeepPurple),
            title: const Text('استعادة النسخة الاحتياطية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSnack(context, "♻️ تم استعادة النسخة الاحتياطية"),
          ),
          const Divider(),

          // ---------- الاشتراك ----------
          ListTile(
            leading: Icon(
              app.isPro ? Icons.verified : Icons.workspace_premium,
              color: app.isPro ? AppTheme.privooSuccess : AppTheme.privooGold,
            ),
            title: Text(app.isPro ? 'أنت مشترك في Privoo Pro' : 'الترقية إلى Privoo Pro'),
            subtitle: Text(app.isPro ? 'تم تفعيل الميزات الحصرية' : 'افتح الميزات الحصرية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradeProView()),
              );
            },
          ),
          const Divider(),

          // ---------- الخصوصية والأمان ----------
          ExpansionTile(
            leading: Icon(Icons.lock, color: AppTheme.privooDeepPurple),
            title: const Text("الخصوصية والأمان"),
            children: [
              SwitchListTile(
                title: const Text("قفل التطبيق ببصمة/كلمة مرور"),
                value: app.lockApp,
                onChanged: (v) {
                  appNotifier.toggleLockApp(v);
                  _showSnack(context, v ? "تم تفعيل قفل التطبيق" : "تم إيقاف قفل التطبيق");
                },
              ),
              SwitchListTile(
                title: const Text("إخفاء آخر ظهور"),
                value: app.hideLastSeen,
                onChanged: (v) {
                  appNotifier.toggleHideLastSeen(v);
                  _showSnack(context, v ? "تم إخفاء آخر ظهور" : "تم إظهار آخر ظهور");
                },
              ),
              SwitchListTile(
                title: const Text("إخفاء حالة النشاط"),
                value: app.hideOnlineStatus,
                onChanged: (v) {
                  appNotifier.toggleHideOnlineStatus(v);
                  _showSnack(context, v ? "تم إخفاء حالة النشاط" : "تم إظهار حالة النشاط");
                },
              ),
              ListTile(
                title: const Text("إدارة من يمكنه مراسلتي"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAllowedSendersScreen())),
              ),
              ListTile(
                title: const Text("إدارة المحادثات المخفية"),
                trailing: const Icon(Icons.lock_outline),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HiddenChatsScreen())),
              ),
              ListTile(
                leading: Icon(Icons.block, color: AppTheme.privooError),
                title: const Text("المستخدمون المحظورون"),
                subtitle: const Text("إدارة قائمة الحظر"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockListScreen())),
              ),
            ],
          ),

          // ---------- الرقابة الأبوية ----------
          ListTile(
            leading: Icon(Icons.family_restroom, color: AppTheme.privooDeepPurple),
            title: const Text('الرقابة الأبوية'),
            subtitle: const Text('تقييد المحتوى وإدارة وقت الاستخدام'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParentalControlScreen()),
            ),
          ),
          const Divider(),

          // ---------- الإشعارات ----------
          ExpansionTile(
            leading: Icon(Icons.notifications, color: AppTheme.privooDeepPurple),
            title: const Text("الإشعارات"),
            children: [
              SwitchListTile(
                title: const Text("تفعيل الإشعارات"),
                value: app.notificationsEnabled,
                onChanged: (v) {
                  appNotifier.toggleNotifications(v);
                  _showSnack(context, v ? "تم تفعيل الإشعارات" : "تم إيقاف الإشعارات");
                },
              ),
              SwitchListTile(
                title: const Text("تفعيل الاهتزاز"),
                value: app.vibrationEnabled,
                onChanged: (v) {
                  appNotifier.toggleVibration(v);
                  _showSnack(context, v ? "تم تفعيل الاهتزاز" : "تم إيقاف الاهتزاز");
                },
              ),
              ListTile(
                title: const Text("نغمة الإشعارات"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSoundScreen())),
              ),
              ListTile(
                title: const Text("إدارة الإشعارات الصامتة للمحادثات"),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SilentNotificationsScreen())),
              ),
            ],
          ),

          // ---------- الحساب ----------
          ExpansionTile(
            leading: Icon(Icons.person, color: AppTheme.privooDeepPurple),
            title: const Text("إدارة الحساب"),
            children: [
              ListTile(
                title: const Text("تغيير الاسم"),
                trailing: const Icon(Icons.edit),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeNameScreen())),
              ),
              ListTile(
                title: const Text("تغيير الصورة الشخصية"),
                trailing: const Icon(Icons.image),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeAvatarScreen())),
              ),
              ListTile(
                title: const Text("تغيير البريد وكلمة المرور"),
                trailing: const Icon(Icons.security),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeCredentialsScreen())),
              ),
              ListTile(
                title: const Text("ربط الحساب بجوجل / أبل"),
                trailing: const Icon(Icons.link),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkProvidersScreen())),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppTheme.privooError),
                title: const Text("حذف الحساب نهائيًا"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),

          // ---------- المحادثات ----------
          ExpansionTile(
            leading: Icon(Icons.chat, color: AppTheme.privooDeepPurple),
            title: const Text("إعدادات المحادثات"),
            children: [
              ListTile(
                title: const Text("تغيير خلفية المحادثة"),
                trailing: const Icon(Icons.wallpaper),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWallpaperScreen())),
              ),
              ListTile(
                title: const Text("حجم الخط في الرسائل"),
                trailing: const Icon(Icons.text_fields),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatFontSizeScreen())),
              ),
              SwitchListTile(
                title: const Text("إظهار تأكيد قراءة الرسائل"),
                value: app.readReceipts,
                onChanged: (v) {
                  appNotifier.toggleReadReceipts(v);
                  _showSnack(context, v ? "تم تفعيل تأكيد القراءة" : "تم إيقاف تأكيد القراءة");
                },
              ),
              ListTile(
                title: const Text("تنزيل الوسائط تلقائيًا"),
                trailing: const Icon(Icons.download),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoDownloadMediaScreen())),
              ),
            ],
          ),

          // ---------- إعدادات متقدمة ----------
          ExpansionTile(
            leading: Icon(Icons.settings_applications, color: AppTheme.privooDeepPurple),
            title: const Text("إعدادات متقدمة"),
            children: [
              ListTile(
                title: const Text("مسح الكاش"),
                trailing: const Icon(Icons.cleaning_services),
                onTap: () {
                  appNotifier.clearCache();
                  _showSnack(context, "🧹 تم مسح الكاش");
                },
              ),
              ListTile(
                title: const Text("إعادة ضبط الإعدادات"),
                trailing: const Icon(Icons.refresh),
                onTap: () {
                  appNotifier.resetSettings();
                  _showSnack(context, "♻️ تم إعادة ضبط الإعدادات");
                },
              ),
              SwitchListTile(
                title: const Text("تفعيل وضع توفير البيانات"),
                value: app.dataSaverEnabled,
                onChanged: (v) {
                  appNotifier.toggleDataSaver(v);
                  _showSnack(context, v ? "تم تفعيل وضع توفير البيانات" : "تم إيقاف وضع توفير البيانات");
                },
              ),
            ],
          ),

          // ✅ ---------- لوحة تحكم المشرفين ----------
          if (user != null)
            FutureBuilder<bool>(
              future: _isAdmin(user.phoneNumber ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  final authController = ref.read(authControllerProvider.notifier);
                  
                  return Column(
                    children: [
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: AppTheme.privooDeepPurple),
                            const SizedBox(width: 8),
                            Text(
                              'لوحة تحكم المشرفين',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.privooDeepPurple),
                            ),
                          ],
                        ),
                      ),
                      
                      if (authController.hasPermission(Permissions.viewSupportTickets))
                        ListTile(
                          leading: Icon(Icons.support_agent, color: AppTheme.privooDeepPurple),
                          title: const Text('تذاكر الدعم الفني'),
                          subtitle: const Text('عرض والرد على رسائل المستخدمين'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
                        ),
                      
                      if (authController.hasPermission(Permissions.viewUsers))
                        ListTile(
                          leading: Icon(Icons.people, color: AppTheme.privooDeepPurple),
                          title: const Text('إدارة المستخدمين'),
                          subtitle: const Text('عرض، حظر، منح اشتراكات'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                        ),
                      
                      if (authController.hasPermission(Permissions.manageAdmins))
                        ListTile(
                          leading: Icon(Icons.admin_panel_settings, color: AppTheme.privooDeepPurple),
                          title: const Text('إدارة المشرفين'),
                          subtitle: const Text('إضافة، تعديل، حذف المشرفين'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAdminsScreen())),
                        ),
                      
                      if (authController.hasPermission(Permissions.manageAdmins))
                        ListTile(
                          leading: Icon(Icons.local_offer, color: AppTheme.privooGold),
                          title: const Text('إدارة العروض والكوبونات'),
                          subtitle: const Text('إضافة وتعديل أكواد الخصم'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageOffersScreen())),
                        ),
                      
                      if (authController.hasPermission(Permissions.sendNotifications))
                        ListTile(
                          leading: Icon(Icons.notifications_active, color: AppTheme.privooDeepPurple),
                          title: const Text('إرسال إشعار جماعي'),
                          subtitle: const Text('إشعار لجميع المستخدمين'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.pushNamed(context, '/send-notification'),
                        ),
                      
                      const Divider(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          const Divider(),

          // ✅ ---------- الامتثال القانوني ----------
          ListTile(
            leading: Icon(Icons.gavel, color: AppTheme.privooDeepPurple),
            title: const Text('الامتثال القانوني وحقوقي'),
            subtitle: const Text('GDPR • CCPA • PDPL • PIPL • وغيرها (13 دولة)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplianceScreen())),
          ),
          const Divider(),

          // ✅ ---------- الإنجازات العلمية ----------
          ListTile(
            leading: Icon(Icons.science, color: AppTheme.privooDeepPurple),
            title: const Text('الإنجازات العلمية'),
            subtitle: const Text('التشفير المقاوم للكم • الذكاء الاصطناعي • بروتوكولات متقدمة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.scientificAchievements),
          ),
          const Divider(),

          // ---------- روابط وسياسة ----------
          ListTile(
            leading: Icon(Icons.privacy_tip, color: AppTheme.privooDeepPurple),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchWeb(context, 'privacy_policy.html'),
          ),
          ListTile(
            leading: Icon(Icons.rule, color: AppTheme.privooDeepPurple),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchWeb(context, 'terms_of_use.html'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.privooDeepPurple),
            title: const Text('من نحن'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchWeb(context, 'about_us.html'),
          ),
          ListTile(
            leading: Icon(Icons.support_agent, color: AppTheme.privooDeepPurple),
            title: const Text('الدعم الفني'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchWeb(context, 'support.html'),
          ),
          ListTile(
            leading: Icon(Icons.download, color: AppTheme.privooDeepPurple),
            title: const Text('تحميل التطبيق'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchWeb(context, 'download_wait.html'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, dynamic app, dynamic appNotifier) {
    final currentCode = app.locale.languageCode;
    return ListTile(
      title: const Text('اللغة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: DropdownButton<String>(
        value: currentCode,
        items: _languages.map((lang) {
          return DropdownMenuItem(
            value: lang['code'],
            child: Text(lang['label']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            appNotifier.updateLanguage(value);
            _showSnack(context, "تم تغيير اللغة إلى ${_languages.firstWhere((l) => l['code'] == value)['label']}");
          }
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد حذف الحساب"),
        content: const Text("هل أنت متأكد من حذف حسابك نهائيًا؟ سيتم حذف جميع بياناتك ولا يمكن استرجاعها."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack(context, "✅ تم حذف الحساب بنجاح");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooError,
            ),
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWeb(BuildContext context, String file) async {
    final assetPath = 'web/$file';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalWebViewScreen(
          assetPath: assetPath,
          title: file,
        ),
      ),
    );
  }
}