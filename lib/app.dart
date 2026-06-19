// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'config/app_theme.dart';
import 'services/supabase_service.dart';

// استيراد جميع الشاشات
import 'views/auth/otp_login_screen.dart';
import 'views/auth/profile_setup_screen.dart';
import 'views/auth/terms_acceptance_screen.dart';
import 'views/auth/age_verification_screen.dart';
import 'views/auth/invite_screen.dart';
import 'views/auth/verify_screen.dart';
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
import 'views/settings/parental_control_screen.dart';
import 'views/chat/smart_chat_screen.dart';
import 'views/chat/create_group_screen.dart';
import 'views/chat/group_details_screen.dart';
import 'views/chat/pinned_messages_screen.dart';
import 'views/call/call_screen.dart';
import 'views/call/group_call_screen.dart';
import 'views/incoming_call_screen.dart';
import 'views/block_list_screen.dart';
import 'views/channels/channel_list_screen.dart';
import 'views/channels/channel_screen.dart';
import 'views/channels/create_channel_screen.dart';
import 'views/search_screen.dart';
import 'views/sticker/sticker_maker_screen.dart';
import 'views/users/users_list_screen.dart';
import 'views/admin/manage_admins_screen.dart';
import 'views/admin/support_tickets_screen.dart';
import 'views/admin/manage_users_screen.dart';
import 'views/admin/manage_offers_screen.dart';

final _logger = Logger();

class PrivooApp extends ConsumerStatefulWidget {
  final Function(Locale)? onLocaleChange;
  
  const PrivooApp({super.key, this.onLocaleChange});

  @override
  ConsumerState<PrivooApp> createState() => _PrivooAppState();
}

class _PrivooAppState extends ConsumerState<PrivooApp> {
  bool _isInitialized = false;
  String _nextRoute = '/splash';
  bool _isAppInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    if (_isAppInitialized) return;
    
    try {
      final user = SupabaseService().currentUser;
      
      if (user != null) {
        _logger.i("🔍 المستخدم مسجل: ${user.id}");
        
        // ✅ جلب بيانات المستخدم من Supabase
        final userData = await SupabaseService().getUser(user.id);
        
        if (userData != null) {
          final name = userData.name;
          _nextRoute = (name != null && name.trim().isNotEmpty) ? '/home' : '/profile';
          _logger.i("✅ التوجيه إلى: $_nextRoute");
        } else {
          _nextRoute = '/profile';
          _logger.i("✅ التوجيه إلى: $_nextRoute (مستخدم جديد)");
        }
      } else {
        _nextRoute = '/login';
        _logger.i("👤 التوجيه إلى شاشة تسجيل الدخول");
      }

      _isAppInitialized = true;
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      _logger.e("❌ خطأ أثناء تهيئة التطبيق: $e");
      _isAppInitialized = true;
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _nextRoute = '/login';
        });
      }
    }
  }

  void changeLanguage(String languageCode) {
    widget.onLocaleChange?.call(Locale(languageCode));
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('app_language', languageCode);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
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
    
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد الخروج من التطبيق؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.privooCardDark,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    ) ?? false;
    
    return shouldExit;
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    _logger.d("🚀 مسار جديد: ${settings.name}");

    switch (settings.name) {
      case '/':
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case '/login':
      case '/otp-login':
        return MaterialPageRoute(builder: (_) => const OTPLoginScreen());
      
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen(
          onChangeLanguage: changeLanguage,
        ));
      
      case '/parental-control':
        return MaterialPageRoute(builder: (_) => const ParentalControlScreen());
      
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
      
      case '/chat':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['chatId'] != null && args['receiverId'] != null) {
          return MaterialPageRoute(
            builder: (_) => SmartChatScreen(
              chatId: args['chatId']!,
              receiverId: args['receiverId']!,
            ),
          );
        }
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
          onVerified: () => Navigator.pop(context),
          onUnderAge: () => showDialog(
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
          ),
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
        _logger.w("⚠️ مسار غير معروف: ${settings.name}");
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}