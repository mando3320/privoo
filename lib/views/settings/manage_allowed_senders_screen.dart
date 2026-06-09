// lib/views/settings/manage_allowed_senders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

class ManageAllowedSendersScreen extends ConsumerStatefulWidget {
  const ManageAllowedSendersScreen({super.key});

  @override
  ConsumerState<ManageAllowedSendersScreen> createState() => _ManageAllowedSendersScreenState();
}

class _ManageAllowedSendersScreenState extends ConsumerState<ManageAllowedSendersScreen> {
  String _selectedOption = 'everyone';
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _options = [
    {
      'value': 'everyone',
      'label': 'الجميع',
      'description': 'يمكن لأي شخص مراسلتي',
      'icon': Icons.public,
      'color': Colors.blue,
    },
    {
      'value': 'contacts',
      'label': 'جهات الاتصال فقط',
      'description': 'فقط الأشخاص الموجودين في جهات الاتصال',
      'icon': Icons.contacts,
      'color': Colors.green,
    },
    {
      'value': 'mutual_groups',
      'label': 'المجموعات المشتركة',
      'description': 'فقط الأعضاء المشتركين في مجموعات معي',
      'icon': Icons.group,
      'color': Colors.orange,
    },
    {
      'value': 'nobody',
      'label': 'لا أحد',
      'description': 'لا يمكن لأحد مراسلتي',
      'icon': Icons.block,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedOption = prefs.getString('allowed_senders') ?? 'everyone';
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String value, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allowed_senders', value);
    setState(() => _selectedOption = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تغيير الإعداد إلى: $label'),
          backgroundColor: AppTheme.privooSuccess,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة من يمكنه مراسلتي'),
        centerTitle: true,
        elevation: 0,
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
                      child: Icon(Icons.message, size: 40, color: AppTheme.privooDeepPurple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'من يمكنه مراسلتي',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر من يمكنه إرسال رسائل إليك',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // الإعداد الحالي
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.privooDeepPurple.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'الإعداد الحالي',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _options.firstWhere((o) => o['value'] == _selectedOption)['label'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.privooDeepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // قائمة الخيارات
                  ..._options.map((option) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _selectedOption == option['value']
                          ? AppTheme.privooDeepPurple.withValues(alpha: 0.05)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedOption == option['value']
                            ? AppTheme.privooDeepPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: RadioListTile<String>(
                      value: option['value'],
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        if (value != null) {
                          _saveSetting(value, option['label']);
                        }
                      },
                      activeColor: AppTheme.privooDeepPurple,
                      title: Row(
                        children: [
                          Icon(option['icon'], color: option['color']),
                          const SizedBox(width: 12),
                          Text(
                            option['label'],
                            style: TextStyle(
                              fontWeight: _selectedOption == option['value']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(left: 36, top: 4),
                        child: Text(
                          option['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  )),

                  const SizedBox(height: 24),

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
                            'يمكنك تغيير هذا الإعداد في أي وقت. سيتم تطبيق الإعداد على جميع المحادثات الجديدة.',
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