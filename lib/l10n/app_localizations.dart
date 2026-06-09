import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar'), Locale('de'), Locale('en'), Locale('es'), Locale('fr'),
    Locale('hi'), Locale('it'), Locale('ru'), Locale('tr'), Locale('zh')
  ];

  // Basic
  String get appName;
  String get welcome;
  String get login;
  String get logout;
  String get send;
  String get settings;
  String get language;
  String get theme;
  String get backup;
  String get darkMode;
  String get lightMode;
  String get about;
  String get version;
  String get appDescription;
  String get chatWithDeveloper;
  String get privacyPolicy;
  String get terms;
  String get rateApp;
  String get allRightsReserved;
  String get aiModelLicenseNotice;

  // Subscription
  String get pro;
  String get free;
  String get upgrade;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get search;
  String get loading;
  String get error;
  String get retry;
  String get noData;
  String get online;
  String get offline;
  String get typing;
  String get copied;
  String get pinned;
  String get unpinned;
  String get deleted;
  String get blocked;
  String get unblocked;

  // Admin
  String get adminPanel;
  String get supportTickets;
  String get manageUsers;
  String get manageAdmins;
  String get sendNotification;
  String get scientificAchievements;
  String get compliance;

  // Themes
  String get themeFreeCount;
  String get themeProCount;
  String get themeLockedCount;

  // Backup
  String get backupSuccess;
  String get restoreSuccess;
  String get cacheCleared;
  String get settingsReset;

  // Calls
  String get call;
  String get videoCall;
  String get groupVideoCall;
  String get groupVoiceCall;
  String get participants;
  String get noParticipants;

  // Chat
  String get summary;
  String get smartReplies;
  String get pinnedMessages;
  String get encrypted;
  String get quantumResistant;
  String get sealedSender;

  // Privacy Settings
  String get lockApp;
  String get lockAppEnabled;
  String get lockAppDisabled;
  String get hideLastSeen;
  String get hideLastSeenEnabled;
  String get hideLastSeenDisabled;
  String get hideOnlineStatus;
  String get hideOnlineStatusEnabled;
  String get hideOnlineStatusDisabled;
  String get manageAllowedSenders;
  String get manageHiddenChats;
  String get blockedUsers;
  String get blockedUsersSubtitle;

  // Notifications
  String get notificationsTitle;
  String get enableNotifications;
  String get vibration;
  String get notificationSound;
  String get silentNotifications;

  // Account Management
  String get accountManagement;
  String get changeName;
  String get changeAvatar;
  String get changeCredentials;
  String get linkProviders;
  String get deleteAccount;
  String get confirmDeleteTitle;
  String get confirmDeleteContent;

  // Chat Settings
  String get chatSettings;
  String get changeChatWallpaper;
  String get chatFontSize;
  String get readReceipts;
  String get readReceiptsEnabled;
  String get readReceiptsDisabled;
  String get autoDownloadMedia;

  // Advanced Settings
  String get advancedSettings;
  String get clearCache;
  String get resetSettings;
  String get dataSaver;
  String get dataSaverEnabled;
  String get dataSaverDisabled;

  // Admin Panel Details
  String get adminPanelTitle;
  String get supportTicketsTitle;
  String get supportTicketsSubtitle;
  String get manageUsersTitle;
  String get manageUsersSubtitle;
  String get manageAdminsTitle;
  String get manageAdminsSubtitle;
  String get manageOffersTitle;
  String get manageOffersSubtitle;
  String get sendNotificationTitle;
  String get sendNotificationSubtitle;
  String get workInProgress;

  // Compliance & Scientific
  String get complianceTitle;
  String get complianceSubtitle;
  String get scientificAchievementsTitle;
  String get scientificAchievementsSubtitle;

  // Other
  String get downloadApp;
  String get openingWeb;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.contains(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'it': return AppLocalizationsIt();
    case 'ru': return AppLocalizationsRu();
    case 'tr': return AppLocalizationsTr();
    case 'zh': return AppLocalizationsZh();
    default: return AppLocalizationsEn();
  }
}