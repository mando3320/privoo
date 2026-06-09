// lib/views/settings/chat_wallpaper_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

class ChatWallpaperScreen extends ConsumerStatefulWidget {
  const ChatWallpaperScreen({super.key});

  @override
  ConsumerState<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends ConsumerState<ChatWallpaperScreen> {
  String _selectedWallpaper = 'default';
  bool _isLoading = true;

  // ✅ changed from const to final to fix constant evaluation error
  static final List<Map<String, dynamic>> _wallpapers = [
    {'id': 'default', 'name': 'افتراضي', 'icon': Icons.wallpaper, 'color': null},
    {'id': 'gradient_blue', 'name': 'أزرق متدرج', 'icon': Icons.gradient, 'color': null},
    {'id': 'gradient_purple', 'name': 'بنفسجي متدرج', 'icon': Icons.gradient, 'color': null},
    {'id': 'gradient_sunset', 'name': 'غروب الشمس', 'icon': Icons.wb_sunny, 'color': null},
    {'id': 'dark', 'name': 'داكن', 'icon': Icons.nightlight_round, 'color': null},
    {'id': 'light', 'name': 'فاتح', 'icon': Icons.light_mode, 'color': null},
    {'id': 'solid_blue', 'name': 'أزرق صلب', 'icon': Icons.circle, 'color': Colors.blue.shade400},
    {'id': 'solid_green', 'name': 'أخضر صلب', 'icon': Icons.circle, 'color': Colors.green.shade400},
    {'id': 'solid_orange', 'name': 'برتقالي صلب', 'icon': Icons.circle, 'color': Colors.orange.shade400},
    {'id': 'solid_purple', 'name': 'بنفسجي صلب', 'icon': Icons.circle, 'color': AppTheme.privooDeepPurple},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedWallpaper();
  }

  Future<void> _loadSelectedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedWallpaper = prefs.getString('chat_wallpaper') ?? 'default';
      _isLoading = false;
    });
  }

  Future<void> _saveWallpaper(String wallpaperId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_wallpaper', wallpaperId);
    setState(() => _selectedWallpaper = wallpaperId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تغيير خلفية المحادثة إلى ${_wallpapers.firstWhere((w) => w['id'] == wallpaperId)['name']}'),
        backgroundColor: AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildWallpaperPreview(Map<String, dynamic> wallpaper) {
    final isSelected = _selectedWallpaper == wallpaper['id'];
    
    Widget preview;
    if (wallpaper['color'] != null) {
      preview = Container(
        decoration: BoxDecoration(
          color: wallpaper['color'],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.chat_bubble_outline, size: 30, color: Colors.white),
        ),
      );
    } else if (wallpaper['id'] == 'default') {
      preview = Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Icon(Icons.wallpaper, size: 30, color: Colors.grey),
        ),
      );
    } else {
      preview = Container(
        decoration: BoxDecoration(
          gradient: _getGradient(wallpaper['id']),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.gradient, size: 30, color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _saveWallpaper(wallpaper['id']),
      child: Container(
        width: 100,
        height: 120,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.privooGold : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [AppTheme.mainShadow(AppTheme.privooGold)]
              : null,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: preview,
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.privooGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text(
                wallpaper['name'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.privooGold : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient? _getGradient(String id) {
    switch (id) {
      case 'gradient_blue':
        return const LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_purple':
        return const LinearGradient(
          colors: [AppTheme.privooDeepPurple, AppTheme.privooLightPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_sunset':
        return const LinearGradient(
          colors: [Colors.orange, Colors.red, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خلفية المحادثة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Icon(Icons.wallpaper, size: 40, color: AppTheme.privooDeepPurple),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر خلفية للمحادثات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.privooDeepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الخلفية المختارة ستظهر في جميع المحادثات',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedWallpaper == 'default'
                        ? Theme.of(context).scaffoldBackgroundColor
                        : null,
                    gradient: _getGradient(_selectedWallpaper),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.privooDeepPurple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: _selectedWallpaper == 'default' ? AppTheme.privooDeepPurple : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'معاينة الخلفية الحالية',
                          style: TextStyle(
                            color: _selectedWallpaper == 'default' ? AppTheme.privooDeepPurple : Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        _wallpapers.firstWhere((w) => w['id'] == _selectedWallpaper)['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedWallpaper == 'default' ? AppTheme.privooDeepPurple : AppTheme.privooGold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _wallpapers.length,
                    itemBuilder: (context, index) {
                      return _buildWallpaperPreview(_wallpapers[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}