// lib/app.dart
// ============================================================
// 🚀 جميع الـ imports في الأعلى أولاً
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'services/firebase/notification_service.dart';

// 📁 استيراد جميع شاشات التطبيق
import 'views/auth/otp_login_screen.dart';  // ✅ أصبحت الأساسية
import 'views/auth/login_screen.dart';      // 📦 احتياطي (يمكن حذفه أو الاحتفاظ به)
import 'views/auth/profile_setup_screen.dart';
import 'views/auth/age_verification_screen.dart';
import 'views/auth/terms_acceptance_screen.dart';
import 'views/auth/verify_screen.dart';
import 'views/auth/invite_screen.dart';

import 'views/home_screen.dart';
import 'views/settings/setting_screen.dart';
import 'views/settings/splash_screen.dart';
import 'views/settings/upgrade_pro_view.dart';
import 'views/settings/compliance_screen.dart';
import 'views/settings/theme_selector_screen.dart';
import 'views/settings/privacy_settings_screen.dart';
import 'views/settings/scientific_achievements_screen.dart';
import 'views/settings/about_screen.dart';
import 'views/settings/chat_with_developer_screen.dart';
import 'views/settings/encryption_info_screen.dart';
import 'views/settings/export_data_screen.dart';
import 'views/settings/delete_account_screen.dart';

import 'views/chat/smart_chat_screen.dart';
import 'views/chat/create_group_screen.dart';
import 'views/chat/group_details_screen.dart';
import 'views/chat/pinned_messages_screen.dart';

import 'views/call/call_screen.dart';
import 'views/call/group_call_screen.dart';
import 'views/incoming_call_screen.dart';

import 'views/block_list_screen.dart';
import 'views/channel_list_screen.dart';
import 'views/channel_screen.dart';
import 'views/create_channel_screen.dart';
import 'views/search_screen.dart';
import 'views/sticker/sticker_maker_screen.dart';
import 'views/users/users_list_screen.dart';

import 'views/admin/manage_admins_screen.dart';
import 'views/admin/support_tickets_screen.dart';
import 'views/admin/manage_users_screen.dart';
import 'views/admin/manage_offers_screen.dart';

// ============================================================
// 📦 تعريف المتغيرات بعد الـ imports
// ============================================================
final _logger = Logger();

final notificationServiceProvider = Provider((ref) {
  final service = NotificationService();
  _logger.i("🔔 تم تهيئة NotificationService باستخدام Riverpod.");
  return service;
});

// ============================================================
// 🏠 التطبيق الرئيسي
// ============================================================
class PrivooApp extends ConsumerStatefulWidget {
  const PrivooApp({super.key});

  @override
  ConsumerState<PrivooApp> createState() => _PrivooAppState();
}

class _PrivooAppState extends ConsumerState<PrivooApp> {
  bool _isInitialized = false;
  String _nextRoute = '/splash';
  Map<String, String>? _chatArgs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      ref.read(notificationServiceProvider);
      _logger.i("✅ تم تهيئة NotificationService");

      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        _nextRoute = '/home';
        _logger.i("✅ المستخدم مسجل: ${user.uid} - التوجيه إلى HomeScreen");
      } else {
        _nextRoute = '/login';
        _logger.i("👤 المستخدم غير مسجل - التوجيه إلى شاشة تسجيل الدخول");
      }

      setState(() => _isInitialized = true);
    } catch (e, s) {
      _logger.e("❌ خطأ أثناء تهيئة التطبيق: $e");
      _logger.e("Stacktrace: $s");
      setState(() {
        _isInitialized = true;
        _nextRoute = '/login';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _onWillPop();
        return shouldPop;
      },
      child: Navigator(
        key: UniqueKey(),
        initialRoute: _nextRoute,
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return true;
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    _logger.d("🚀 مسار جديد مطلوب: ${settings.name}");

    switch (settings.name) {
      case '/':
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case '/login':
        // ✅ استخدام OTPLoginScreen بدلاً من LoginScreen
        return MaterialPageRoute(builder: (_) => const OTPLoginScreen());
      
      case '/otp-login':
        return MaterialPageRoute(builder: (_) => const OTPLoginScreen());
      
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case '/users':
        return MaterialPageRoute(builder: (_) => const UsersListScreen());
      
      case '/invite':
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(builder: (_) => InviteScreen(
          phoneNumber: args?['phone'] ?? '',
          name: args?['name'] ?? '',
        ));
      
      case '/upgrade-pro':
        return MaterialPageRoute(builder: (_) => const UpgradeProView());
      
      case '/compliance':
        return MaterialPageRoute(builder: (_) => const ComplianceScreen());
      
      case '/block-list':
        return MaterialPageRoute(builder: (_) => const BlockListScreen());
      
      case '/theme-selector':
        return MaterialPageRoute(builder: (_) => const ThemeSelectorScreen());
      
      case '/privacy-settings':
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      
      case '/scientific-achievements':
        return MaterialPageRoute(builder: (_) => const ScientificAchievementsScreen());
      
      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      
      case '/chat-with-developer':
        return MaterialPageRoute(builder: (_) => const ChatWithDeveloperScreen());
      
      case '/encryption-info':
        return MaterialPageRoute(builder: (_) => const EncryptionInfoScreen());
      
      case '/export-data':
        return MaterialPageRoute(builder: (_) => const ExportDataScreen());
      
      case '/delete-account':
        return MaterialPageRoute(builder: (_) => const DeleteAccountScreen());
      
      case '/chat-wallpaper':
      case '/chat-font-size':
      case '/notification-sound':
      case '/silent-notifications':
      case '/auto-download-media':
      case '/manage-allowed-senders':
      case '/hidden-chats':
      case '/change-name':
      case '/change-avatar':
      case '/change-credentials':
      case '/link-providers':
        _logger.w("⚠️ شاشة '${settings.name}' غير موجودة بعد، مؤقتاً نعود للإعدادات.");
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/chat':
        final args = _chatArgs ?? (settings.arguments as Map<String, String>?);
        if (args != null && args['chatId'] != null && args['receiverId'] != null) {
          return MaterialPageRoute(
            builder: (_) => SmartChatScreen(
              chatId: args['chatId']!,
              receiverId: args['receiverId']!,
            ),
          );
        }
        _logger.w("⚠️ لا توجد محادثة محددة، التوجيه إلى HomeScreen");
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/create-group':
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());
      
      case '/group-details':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['groupId'] != null) {
          return MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(groupId: args['groupId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/pinned-messages':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['chatId'] != null) {
          return MaterialPageRoute(
            builder: (_) => PinnedMessagesScreen(chatId: args['chatId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/call':
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => CallScreen(
              isCaller: args['isCaller'] as bool? ?? false,
              callerId: args['callerId'] as String? ?? '',
              receiverId: args['receiverId'] as String? ?? '',
              callIdWhenCallee: args['callIdWhenCallee'] as String?,
              isVideo: args['isVideo'] as bool? ?? true,
              title: args['title'] as String? ?? 'Privoo Call',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const CallScreen(isCaller: false, callerId: '', receiverId: ''),
        );
      
      case '/group-call':
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => GroupCallScreen(
              isInitiator: args['isInitiator'] as bool? ?? false,
              groupId: args['groupId'] as String? ?? '',
              callId: args['callId'] as String? ?? '',
              participantIds: List<String>.from(args['participantIds'] ?? []),
              currentUserId: args['currentUserId'] as String? ?? '',
              isVideo: args['isVideo'] as bool? ?? true,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/incoming-call':
        final callId = DateTime.now().millisecondsSinceEpoch.toString();
        return MaterialPageRoute(builder: (_) => IncomingCallScreen(
          callId: callId,
          callerName: 'مستخدم',
          isVideo: false,
          onAccept: () {
            _logger.i("✅ تم قبول المكالمة: $callId");
            Navigator.pop(context);
            Navigator.pushNamed(context, '/call', arguments: {
              'isCaller': false,
              'callerId': '',
              'receiverId': '',
              'callIdWhenCallee': callId,
              'isVideo': false,
            });
          },
          onReject: () {
            _logger.i("❌ تم رفض المكالمة: $callId");
            Navigator.pop(context);
          },
        ));

      case '/channels':
        return MaterialPageRoute(builder: (_) => const ChannelListScreen());
      
      case '/channel':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['channelId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ChannelScreen(channelId: args['channelId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/create-channel':
        return MaterialPageRoute(builder: (_) => const CreateChannelScreen());

      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      
      case '/sticker-maker':
        return MaterialPageRoute(builder: (_) => const StickerMakerScreen());
      
      case '/age-verification':
        return MaterialPageRoute(builder: (_) => AgeVerificationScreen(
          onVerified: () {
            Navigator.pop(context);
          },
          onUnderAge: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('عمرك أقل من المطلوب'),
                content: const Text('عذراً، لا يمكنك استخدام Privoo.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('حسناً'),
                  ),
                ],
              ),
            );
          },
        ));
      
      case '/terms':
        return MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen());
      
      case '/verify-identity':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['peerId'] != null && args['peerName'] != null) {
          return MaterialPageRoute(
            builder: (_) => VerifyScreen(
              peerId: args['peerId']!,
              peerName: args['peerName']!,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/manage-admins':
        return MaterialPageRoute(builder: (_) => const ManageAdminsScreen());
      
      case '/support-tickets':
        return MaterialPageRoute(builder: (_) => const SupportTicketsScreen());
      
      case '/manage-users':
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      
      case '/manage-offers':
        return MaterialPageRoute(builder: (_) => const ManageOffersScreen());

      default:
        _logger.w("⚠️ مسار غير معروف: ${settings.name}. التوجيه إلى /home.");
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}