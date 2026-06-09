// lib/views/settings/about_screen.dart
import 'package:flutter/material.dart';
import 'package:privoo/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appName = "Privoo";
  String version = "1.0.0";
  String buildNumber = "";

  final String _privacyPolicyUrl = "https://privoo-b1c4b.web.app/privacy_policy.html";
  final String _appDownloadLink = "https://privoo-b1c4b.web.app/download.html";

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  void _openChat(BuildContext context) {
    Navigator.pushNamed(context, '/chatWithDeveloper');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الرابط: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.about),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${loc.version}: $version (Build $buildNumber)",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Privoo ليس مجرد تطبيق. إنه فلسفة رقمية متمردة.\n"
                "نحن نؤمن أن الخصوصية ليست ميزة، بل حق.\n"
                "كل تفصيلة في Privoo – من الكود إلى النغمة – تعكس احترامنا لوعيك، وحرصنا على حريتك التقنية.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 20),
              Text(
                loc.appDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(loc.chatWithDeveloper),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _launchUrl(_privacyPolicyUrl),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(loc.privacyPolicy),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _launchUrl(_appDownloadLink),
                icon: const Icon(Icons.star_rate),
                label: Text(loc.rateApp),
              ),
              const Divider(height: 40),
              Column(
                children: [
                  Text(
                    "© 2025 Privoo. ${loc.allRightsReserved}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "يعمل الذكاء الاصطناعي في Privoo عبر تقنية Gemini AI من Google.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(128),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}