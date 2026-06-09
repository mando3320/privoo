// lib/views/settings/chat_font_size_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

class ChatFontSizeScreen extends ConsumerStatefulWidget {
  const ChatFontSizeScreen({super.key});

  @override
  ConsumerState<ChatFontSizeScreen> createState() => _ChatFontSizeScreenState();
}

class _ChatFontSizeScreenState extends ConsumerState<ChatFontSizeScreen> {
  double _fontSize = 14.0;
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _presets = [
    {'value': 10.0, 'name': 'صغير جداً', 'icon': Icons.text_decrease},
    {'value': 12.0, 'name': 'صغير', 'icon': Icons.text_decrease},
    {'value': 14.0, 'name': 'عادي', 'icon': Icons.text_fields},
    {'value': 16.0, 'name': 'كبير', 'icon': Icons.text_increase},
    {'value': 18.0, 'name': 'كبير جداً', 'icon': Icons.text_increase},
    {'value': 20.0, 'name': 'ضخم', 'icon': Icons.text_increase},
  ];

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('chat_font_size') ?? 14.0;
      _isLoading = false;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chat_font_size', size);
    setState(() => _fontSize = size);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تغيير حجم الخط إلى ${size.toStringAsFixed(0)}px'),
        backgroundColor: AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetToDefault() {
    _saveFontSize(14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجم خط المحادثة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                      child: Icon(Icons.text_fields, size: 40, color: AppTheme.privooDeepPurple),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'حجم الخط في المحادثات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر حجم الخط المناسب لك',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // معاينة النص
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.privooDeepPurple.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.privooDeepPurple,
                              child: const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Privoo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _fontSize - 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'هذا نص تجريبي لمعاينة حجم الخط. ستظهر جميع الرسائل بهذا الحجم في المحادثات.',
                          style: TextStyle(fontSize: _fontSize, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.done_all, size: _fontSize - 4, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'تمت القراءة',
                              style: TextStyle(fontSize: _fontSize - 4, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // شريط التمرير
                  Text(
                    '${_fontSize.toStringAsFixed(0)}px',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _fontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    activeColor: AppTheme.privooDeepPurple,
                    inactiveColor: AppTheme.privooDeepPurple.withValues(alpha: 0.2),
                    label: '${_fontSize.toStringAsFixed(0)}px',
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                    },
                    onChangeEnd: (value) {
                      _saveFontSize(value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // أزرار مسبقة
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _presets.map((preset) {
                      final isSelected = _fontSize == preset['value'];
                      return FilterChip(
                        label: Text(preset['name']),
                        selected: isSelected,
                        avatar: Icon(preset['icon'], size: 18),
                        onSelected: (selected) {
                          if (selected) {
                            _saveFontSize(preset['value']);
                          }
                        },
                        selectedColor: AppTheme.privooDeepPurple,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.privooDeepPurple,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // زر إعادة تعيين
                  OutlinedButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين إلى الإعدادات الافتراضية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.privooDeepPurple,
                      side: BorderSide(color: AppTheme.privooDeepPurple),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                            'تغيير حجم الخط يؤثر على جميع المحادثات',
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