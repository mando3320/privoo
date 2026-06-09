// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

// 🔒 Auth & Setup
import '../views/auth/otp_login_screen.dart';  // ✅ أصبحت الأساسية
import '../views/auth/profile_setup_screen.dart';
import '../views/auth/login_screen.dart';      // 📦 احتياطي
import '../views/auth/terms_acceptance_screen.dart';
import '../views/auth/age_verification_screen.dart';
import '../views/auth/verify_screen.dart';
import '../views/auth/invite_screen.dart';

// 💬 Chat & Calls
import '../views/chat/smart_chat_screen.dart';
import '../views/chat/create_group_screen.dart';
import '../views/chat/group_details_screen.dart';
import '../views/chat/pinned_messages_screen.dart';
import '../views/call/call_screen.dart';
import '../views/call/group_call_screen.dart';
import '../views/incoming_call_screen.dart';

// 🏠 Home & Users
import '../views/home_screen.dart';
import '../views/users/users_list_screen.dart';
import '../views/block_list_screen.dart';
import '../views/search_screen.dart';

// 📺 Channels
import '../views/channel_list_screen.dart';
import '../views/channel_screen.dart';
import '../views/create_channel_screen.dart';

// 🎨 Settings
import '../views/settings/splash_screen.dart';
import '../views/settings/setting_screen.dart';
import '../views/settings/privacy_settings_screen.dart';
import '../views/settings/scientific_achievements_screen.dart';
import '../views/settings/chat_with_developer_screen.dart';
import '../views/settings/about_screen.dart';
import '../views/settings/encryption_info_screen.dart';
import '../views/settings/export_data_screen.dart';
import '../views/settings/delete_account_screen.dart';
import '../views/settings/upgrade_pro_view.dart';
import '../views/settings/compliance_screen.dart';
import '../views/settings/theme_selector_screen.dart';
import '../views/settings/change_name_screen.dart';
import '../views/settings/change_avatar_screen.dart';
import '../views/settings/change_credentials_screen.dart';
import '../views/settings/link_providers_screen.dart';
import '../views/settings/chat_wallpaper_screen.dart';
import '../views/settings/chat_font_size_screen.dart';
import '../views/settings/notification_sound_screen.dart';
import '../views/settings/silent_notifications_screen.dart';
import '../views/settings/auto_download_media_screen.dart';
import '../views/settings/hidden_chats_screen.dart';
import '../views/settings/manage_allowed_senders_screen.dart';

// 🎨 Stickers
import '../views/sticker/sticker_maker_screen.dart';

// 👑 Admin Screens
import '../views/admin/manage_admins_screen.dart';
import '../views/admin/support_tickets_screen.dart';
import '../views/admin/manage_users_screen.dart';
import '../views/admin/manage_offers_screen.dart';

// شاشة مؤقتة للمسارات غير المكتملة
class UnderConstructionScreen extends StatelessWidget {
  final String title;
  const UnderConstructionScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('هذه الشاشة قيد التطوير', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('سيتم إضافتها قريباً', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';       // ✅ يستخدم OTPLoginScreen
  static const String otpLogin = '/otp-login';
  static const String profileSetup = '/profile';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String call = '/call';
  static const String groupCall = '/group-call';
  static const String incomingCall = '/incoming-call';
  static const String privacySettings = '/privacy-settings';
  static const String scientificAchievements = '/scientific-achievements';
  static const String about = '/about';
  static const String chatWithDeveloper = '/chat-with-developer';
  static const String encryptionInfo = '/encryption-info';
  static const String exportData = '/export-data';
  static const String deleteAccount = '/delete-account';
  static const String upgradePro = '/upgrade-pro';
  static const String compliance = '/compliance';
  static const String themeSelector = '/theme-selector';
  static const String blockList = '/block-list';
  static const String users = '/users';
  static const String invite = '/invite';
  static const String search = '/search';
  static const String stickerMaker = '/sticker-maker';
  static const String ageVerification = '/age-verification';
  static const String terms = '/terms';
  static const String verifyIdentity = '/verify-identity';
  static const String channels = '/channels';
  static const String channel = '/channel';
  static const String createChannel = '/create-channel';
  static const String createGroup = '/create-group';
  static const String groupDetails = '/group-details';
  static const String pinnedMessages = '/pinned-messages';
  
  // إعدادات
  static const String changeName = '/change-name';
  static const String changeAvatar = '/change-avatar';
  static const String changeCredentials = '/change-credentials';
  static const String linkProviders = '/link-providers';
  static const String chatWallpaper = '/chat-wallpaper';
  static const String chatFontSize = '/chat-font-size';
  static const String notificationSound = '/notification-sound';
  static const String silentNotifications = '/silent-notifications';
  static const String autoDownloadMedia = '/auto-download-media';
  static const String hiddenChats = '/hidden-chats';
  static const String manageAllowedSenders = '/manage-allowed-senders';
  
  // Admin
  static const String manageAdmins = '/manage-admins';
  static const String supportTickets = '/support-tickets';
  static const String manageUsers = '/manage-users';
  static const String manageOffers = '/manage-offers';
  static const String sendNotification = '/send-notification';
  static const String supportAdmin = '/support-admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        // ✅ استخدام OTPLoginScreen بدلاً من LoginScreen
        return MaterialPageRoute(builder: (_) => const OTPLoginScreen());

      case AppRoutes.otpLogin:
        return MaterialPageRoute(builder: (_) => const OTPLoginScreen());

      case AppRoutes.profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.chat:
        if (settings.arguments is Map<String, String>) {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (_) => SmartChatScreen(
              chatId: args['chatId'] ?? '',
              receiverId: args['receiverId'] ?? '',
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.users:
        return MaterialPageRoute(builder: (_) => const UsersListScreen());

      case AppRoutes.manageAllowedSenders:
        return MaterialPageRoute(builder: (_) => const ManageAllowedSendersScreen());

      case AppRoutes.hiddenChats:
        return MaterialPageRoute(builder: (_) => const HiddenChatsScreen());

      case AppRoutes.notificationSound:
        return MaterialPageRoute(builder: (_) => const NotificationSoundScreen());

      case AppRoutes.silentNotifications:
        return MaterialPageRoute(builder: (_) => const SilentNotificationsScreen());

      case AppRoutes.changeName:
        return MaterialPageRoute(builder: (_) => const ChangeNameScreen());

      case AppRoutes.changeAvatar:
        return MaterialPageRoute(builder: (_) => const ChangeAvatarScreen());

      case AppRoutes.changeCredentials:
        return MaterialPageRoute(builder: (_) => const ChangeCredentialsScreen());

      case AppRoutes.linkProviders:
        return MaterialPageRoute(builder: (_) => const LinkProvidersScreen());

      case AppRoutes.chatWallpaper:
        return MaterialPageRoute(builder: (_) => const ChatWallpaperScreen());

      case AppRoutes.chatFontSize:
        return MaterialPageRoute(builder: (_) => const ChatFontSizeScreen());

      case AppRoutes.autoDownloadMedia:
        return MaterialPageRoute(builder: (_) => const AutoDownloadMediaScreen());

      case AppRoutes.chatWithDeveloper:
        return MaterialPageRoute(builder: (_) => const ChatWithDeveloperScreen());

      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case AppRoutes.encryptionInfo:
        return MaterialPageRoute(builder: (_) => const EncryptionInfoScreen());

      case AppRoutes.exportData:
        return MaterialPageRoute(builder: (_) => const ExportDataScreen());

      case AppRoutes.deleteAccount:
        return MaterialPageRoute(builder: (_) => const DeleteAccountScreen());

      case AppRoutes.upgradePro:
        return MaterialPageRoute(builder: (_) => const UpgradeProView());

      case AppRoutes.compliance:
        return MaterialPageRoute(builder: (_) => const ComplianceScreen());

      case AppRoutes.themeSelector:
        return MaterialPageRoute(builder: (_) => const ThemeSelectorScreen());

      case AppRoutes.privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());

      case AppRoutes.scientificAchievements:
        return MaterialPageRoute(builder: (_) => const ScientificAchievementsScreen());

      case AppRoutes.blockList:
        return MaterialPageRoute(builder: (_) => const BlockListScreen());

      case AppRoutes.invite:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(builder: (_) => InviteScreen(
          phoneNumber: args?['phone'] ?? '',
          name: args?['name'] ?? '',
        ));

      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case AppRoutes.stickerMaker:
        return MaterialPageRoute(builder: (_) => const StickerMakerScreen());

      case AppRoutes.ageVerification:
        return MaterialPageRoute(builder: (_) => AgeVerificationScreen(
          onVerified: () {},
          onUnderAge: () {},
        ));

      case AppRoutes.terms:
        return MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen());

      case AppRoutes.verifyIdentity:
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

      case AppRoutes.channels:
        return MaterialPageRoute(builder: (_) => const ChannelListScreen());

      case AppRoutes.channel:
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['channelId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ChannelScreen(channelId: args['channelId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.createChannel:
        return MaterialPageRoute(builder: (_) => const CreateChannelScreen());

      case AppRoutes.createGroup:
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());

      case AppRoutes.groupDetails:
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['groupId'] != null) {
          return MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(groupId: args['groupId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.pinnedMessages:
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args['chatId'] != null) {
          return MaterialPageRoute(
            builder: (_) => PinnedMessagesScreen(chatId: args['chatId']!),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.call:
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

      case AppRoutes.groupCall:
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

      case AppRoutes.incomingCall:
        final callId = DateTime.now().millisecondsSinceEpoch.toString();
        return MaterialPageRoute(builder: (_) => IncomingCallScreen(
          callId: callId,
          callerName: 'مستخدم',
          isVideo: false,
          onAccept: () {},
          onReject: () {},
        ));

      case AppRoutes.manageAdmins:
        return MaterialPageRoute(builder: (_) => const ManageAdminsScreen());
        
      case AppRoutes.supportTickets:
        return MaterialPageRoute(builder: (_) => const SupportTicketsScreen());
        
      case AppRoutes.manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
        
      case AppRoutes.supportAdmin:
        return MaterialPageRoute(builder: (_) => const SupportTicketsScreen());

      case AppRoutes.manageOffers:
        return MaterialPageRoute(builder: (_) => const ManageOffersScreen());

      case AppRoutes.sendNotification:
        return MaterialPageRoute(builder: (_) => const UnderConstructionScreen(title: 'إرسال إشعار جماعي'));

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}