// lib/views/settings/auto_download_media_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

class AutoDownloadMediaScreen extends ConsumerStatefulWidget {
  const AutoDownloadMediaScreen({super.key});

  @override
  ConsumerState<AutoDownloadMediaScreen> createState() => _AutoDownloadMediaScreenState();
}

class _AutoDownloadMediaScreenState extends ConsumerState<AutoDownloadMediaScreen> {
  bool _isLoading = true;
  
  // إعدادات التنزيل التلقائي
  Map<String, bool> _settings = {
    'mobile_images': true,
    'mobile_videos': false,
    'mobile_audio': false,
    'mobile_files': false,
    'wifi_images': true,
    'wifi_videos': true,
    'wifi_audio': true,
    'wifi_files': true,
  };

  Map<String, String> _labels = {
    'mobile_images': 'الصور (بيانات المحمول)',
    'mobile_videos': 'الفيديوهات (بيانات المحمول)',
    'mobile_audio': 'الرسائل الصوتية (بيانات المحمول)',
    'mobile_files': 'الملفات (بيانات المحمول)',
    'wifi_images': 'الصور (WiFi)',
    'wifi_videos': 'الفيديوهات (WiFi)',
    'wifi_audio': 'الرسائل الصوتية (WiFi)',
    'wifi_files': 'الملفات (WiFi)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var key in _settings.keys) {
        _settings[key] = prefs.getBool('auto_download_$key') ?? _settings[key]!;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_download_$key', value);
    setState(() => _settings[key] = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحديث إعدادات التنزيل التلقائي'),
          backgroundColor: AppTheme.privooSuccess,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text('هل أنت متأكد من إعادة تعيين إعدادات التنزيل التلقائي إلى الوضع الافتراضي؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooDeepPurple,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _settings['mobile_images'] = true;
        _settings['mobile_videos'] = false;
        _settings['mobile_audio'] = false;
        _settings['mobile_files'] = false;
        _settings['wifi_images'] = true;
        _settings['wifi_videos'] = true;
        _settings['wifi_audio'] = true;
        _settings['wifi_files'] = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      for (var key in _settings.keys) {
        await prefs.setBool('auto_download_$key', _settings[key]!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إعادة تعيين الإعدادات إلى الوضع الافتراضي'),
            backgroundColor: AppTheme.privooSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التنزيل التلقائي للوسائط'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: 'إعادة تعيين',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // شعار
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                    ),
                    child: const Center(
                      child: Icon(Icons.download, size: 40, color: AppTheme.privooDeepPurple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'التنزيل التلقائي',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر أنواع الملفات التي تريد تنزيلها تلقائياً',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // قسم بيانات المحمول
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.signal_cellular_alt, color: AppTheme.privooDeepPurple),
                              const SizedBox(width: 12),
                              Text(
                                'عند استخدام بيانات المحمول',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.privooDeepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          title: Text(_labels['mobile_images']!),
                          value: _settings['mobile_images']!,
                          onChanged: (value) => _saveSetting('mobile_images', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['mobile_videos']!),
                          value: _settings['mobile_videos']!,
                          onChanged: (value) => _saveSetting('mobile_videos', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['mobile_audio']!),
                          value: _settings['mobile_audio']!,
                          onChanged: (value) => _saveSetting('mobile_audio', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['mobile_files']!),
                          value: _settings['mobile_files']!,
                          onChanged: (value) => _saveSetting('mobile_files', value),
                        ),
                      ],
                    ),
                  ),

                  // قسم WiFi
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wifi, color: AppTheme.privooDeepPurple),
                              const SizedBox(width: 12),
                              Text(
                                'عند استخدام WiFi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.privooDeepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          title: Text(_labels['wifi_images']!),
                          value: _settings['wifi_images']!,
                          onChanged: (value) => _saveSetting('wifi_images', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['wifi_videos']!),
                          value: _settings['wifi_videos']!,
                          onChanged: (value) => _saveSetting('wifi_videos', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['wifi_audio']!),
                          value: _settings['wifi_audio']!,
                          onChanged: (value) => _saveSetting('wifi_audio', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(_labels['wifi_files']!),
                          value: _settings['wifi_files']!,
                          onChanged: (value) => _saveSetting('wifi_files', value),
                        ),
                      ],
                    ),
                  ),

                  // ملاحظة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.privooGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppTheme.privooGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم تنزيل الملفات تلقائياً بناءً على هذه الإعدادات. يمكنك تغييرها في أي وقت.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}