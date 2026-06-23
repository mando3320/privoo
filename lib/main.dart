// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/app_theme.dart';
import 'controllers/app_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/hive_storage_service.dart';
import 'services/supabase_service.dart';
import 'services/permission_service.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    logger.i('✅ تم تحميل ملف .env بنجاح');

    await SupabaseService().init();
    logger.i('✅ تم تهيئة Supabase بنجاح');

    await HiveStorageService.init();
    logger.i('✅ تم تهيئة Hive Storage بنجاح');

    // ✅ طلب الأذونات تلقائياً
    await PermissionService.requestAllPermissions();
    logger.i('✅ تم طلب الأذونات تلقائياً');

    runApp(
      const ProviderScope(
        child: PrivooMainApp(),
      ),
    );
  } catch (e, s) {
    logger.e('❌ خطأ أثناء التهيئة: $e');
    logger.e('Stacktrace: $s');
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تهيئة التطبيق: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivooMainApp extends ConsumerStatefulWidget {
  const PrivooMainApp({super.key});

  @override
  ConsumerState<PrivooMainApp> createState() => _PrivooMainAppState();
}

class _PrivooMainAppState extends ConsumerState<PrivooMainApp> {
  Locale? _locale;
  
  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }
  
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language');
    if (savedLanguage != null && mounted) {
      setState(() {
        _locale = Locale(savedLanguage);
      });
    }
  }
  
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('app_language', locale.languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return MaterialApp(
      title: 'Privoo',
      debugShowCheckedModeBanner: false,
      // ✅ استخدام Privoo Premium Theme فقط
      theme: AppTheme.privooPremiumTheme,
      // ✅ استخدام نفس الثيم للوضع الداكن (لأن Privoo Premium داكن)
      darkTheme: AppTheme.privooPremiumTheme,
      // ✅ تثبيت الوضع على الداكن دائماً (لأن Privoo Premium مصمم للداكن)
      themeMode: ThemeMode.dark,
      locale: _locale ?? app.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'), 
        Locale('en'), 
        Locale('fr'), 
        Locale('es'),
        Locale('de'), 
        Locale('zh'), 
        Locale('ru'), 
        Locale('hi'),
        Locale('tr'), 
        Locale('ja'),
      ],
      home: PrivooApp(
        onLocaleChange: setLocale,
      ),
    );
  }
}
