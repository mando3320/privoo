// lib/views/settings/notification_sound_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';  // ✅ استخدام just_audio بدلاً من audioplayers
import '../../config/app_theme.dart';

class NotificationSoundScreen extends ConsumerStatefulWidget {
  const NotificationSoundScreen({super.key});

  @override
  ConsumerState<NotificationSoundScreen> createState() => _NotificationSoundScreenState();
}

class _NotificationSoundScreenState extends ConsumerState<NotificationSoundScreen> {
  static const List<Map<String, dynamic>> _sounds = [
    {'id': 'default', 'name': 'افتراضي (Privoo)', 'file': 'assets/sounds/default_notification.mp3', 'isDefault': true},
    {'id': 'classic', 'name': 'نغمة كلاسيكية', 'file': 'assets/sounds/classic.mp3', 'isDefault': false},
    {'id': 'modern', 'name': 'نغمة حديثة', 'file': 'assets/sounds/modern.mp3', 'isDefault': false},
    {'id': 'gentle', 'name': 'نغمة هادئة', 'file': 'assets/sounds/gentle.mp3', 'isDefault': false},
    {'id': 'digital', 'name': 'نغمة رقمية', 'file': 'assets/sounds/digital.mp3', 'isDefault': false},
    {'id': 'silent', 'name': 'صامت', 'file': null, 'isDefault': false},
  ];

  String _selectedSound = 'default';
  String? _playingSound;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();  // ✅ من just_audio

  @override
  void initState() {
    super.initState();
    _loadSelectedSound();
  }

  Future<void> _loadSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('notification_sound') ?? 'default';
      _isLoading = false;
    });
  }

  Future<void> _saveSound(String soundId, String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', soundId);
    setState(() => _selectedSound = soundId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تغيير نغمة الإشعارات إلى $soundName'),
          backgroundColor: AppTheme.privooSuccess,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    if (soundId != 'silent') {
      await _playSound(soundId);
    }
  }

  Future<void> _playSound(String soundId) async {
    final sound = _sounds.firstWhere((s) => s['id'] == soundId);
    if (sound['file'] == null) return;

    setState(() => _playingSound = soundId);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(sound['file']);  // ✅ just_audio API
      await _audioPlayer.play();
      await Future.delayed(const Duration(seconds: 3));
      await _audioPlayer.stop();
    } catch (e) {
      print('Error playing sound: $e');
    } finally {
      if (mounted && _playingSound == soundId) {
        setState(() => _playingSound = null);
      }
    }
  }

  Future<void> _stopSound() async {
    await _audioPlayer.stop();
    setState(() => _playingSound = null);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نغمة الإشعارات'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_playingSound != null)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopSound,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, size: 40, color: AppTheme.privooDeepPurple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نغمة الإشعارات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر النغمة التي تريد سماعها عند وصول الإشعارات',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  ..._sounds.map((sound) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _selectedSound == sound['id']
                          ? AppTheme.privooDeepPurple.withValues(alpha: 0.05)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedSound == sound['id']
                            ? AppTheme.privooDeepPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _selectedSound == sound['id']
                            ? AppTheme.privooDeepPurple
                            : Colors.grey.shade300,
                        child: Icon(
                          _playingSound == sound['id']
                              ? Icons.play_arrow
                              : (_selectedSound == sound['id']
                                  ? Icons.check
                                  : Icons.music_note),
                          color: _selectedSound == sound['id']
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                      title: Text(
                        sound['name'],
                        style: TextStyle(
                          fontWeight: _selectedSound == sound['id']
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedSound == sound['id']
                              ? AppTheme.privooDeepPurple
                              : null,
                        ),
                      ),
                      subtitle: sound['isDefault']
                          ? const Text('النغمة الافتراضية للتطبيق', style: TextStyle(fontSize: 12))
                          : null,
                      trailing: sound['id'] != 'silent'
                          ? IconButton(
                              icon: Icon(
                                _playingSound == sound['id'] ? Icons.pause : Icons.play_arrow,
                                color: AppTheme.privooDeepPurple,
                              ),
                              onPressed: () {
                                if (_playingSound == sound['id']) {
                                  _stopSound();
                                } else {
                                  _playSound(sound['id']);
                                }
                              },
                            )
                          : null,
                      onTap: () => _saveSound(sound['id'], sound['name']),
                    ),
                  )),

                  const SizedBox(height: 24),

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
                            'يمكنك معاينة أي نغمة بالضغط على أيقونة التشغيل',
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