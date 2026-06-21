// views/sticker/sticker_maker_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/ai/sticker_maker_service.dart';
import '../../services/hive_storage_service.dart';
import '../../main.dart';

class StickerMakerScreen extends StatefulWidget {
  final Function(Uint8List)? onStickerCreated;
  final String? chatId;
  
  const StickerMakerScreen({
    super.key, 
    this.onStickerCreated,
    this.chatId,
  });

  @override
  State<StickerMakerScreen> createState() => _StickerMakerScreenState();
}

class _StickerMakerScreenState extends State<StickerMakerScreen> with SingleTickerProviderStateMixin {
  final StickerMakerService _service = StickerMakerService();
  final TextEditingController _aiPromptController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // ✅ حالة الستيكرات
  Uint8List? _currentSticker;
  bool _isLoading = false;
  int _selectedTab = 0; // 0: من صورة, 1: بالذكاء الاصطناعي, 2: مكتبتي
  
  // ✅ خيارات الستيكر
  bool _addBorder = true;
  Color _borderColor = Colors.white;
  int _borderWidth = 4;
  bool _addShadow = true;
  bool _addGlow = false;
  double _rotation = 0;
  double _scale = 1.0;
  
  // ✅ مكتبة الستيكرات
  List<Map<String, dynamic>> _savedStickers = [];
  List<Map<String, dynamic>> _filteredStickers = [];
  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'وجه', 'حيوانات', 'طعام', 'قلوب', 'نجوم', 'مخصص'];
  
  // ✅ ستيكرات متحركة (GIF)
  bool _isGif = false;
  Uint8List? _gifData;
  
  // ✅ ستيكرات مقترحة
  final List<Map<String, String>> _suggestedPrompts = [
    {'icon': '😊', 'text': 'وجه مبتسم'},
    {'icon': '🐱', 'text': 'قطة لطيفة'},
    {'icon': '❤️', 'text': 'قلب أحمر'},
    {'icon': '⭐', 'text': 'نجمة متوهجة'},
    {'icon': '🌸', 'text': 'وردة وردية'},
    {'icon': '🔥', 'text': 'نار مشتعلة'},
    {'icon': '🌈', 'text': 'قوس قزح'},
    {'icon': '🦋', 'text': 'فراشة جميلة'},
    {'icon': '🍕', 'text': 'بيتزا لذيذة'},
    {'icon': '🚀', 'text': 'صاروخ فضائي'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedStickers();
  }

  @override
  void dispose() {
    _aiPromptController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 📚 تحميل الستيكرات المحفوظة
  // ============================================================
  
  Future<void> _loadSavedStickers() async {
    try {
      final stickers = await HiveStorageService.getSetting('saved_stickers') as List? ?? [];
      setState(() {
        _savedStickers = List<Map<String, dynamic>>.from(stickers);
        _filteredStickers = _savedStickers;
      });
    } catch (e) {
      logger.e('❌ فشل تحميل الستيكرات: $e');
    }
  }

  // ============================================================
  // 💾 حفظ الستيكر
  // ============================================================
  
  Future<void> _saveSticker(Uint8List stickerData, {String? category, String? name}) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final sticker = {
        'id': id,
        'data': stickerData,
        'category': category ?? 'مخصص',
        'name': name ?? 'ستيكر $id',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      _savedStickers.insert(0, sticker);
      _filteredStickers = _savedStickers;
      
      await HiveStorageService.saveSetting('saved_stickers', _savedStickers);
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('💾 تم حفظ الستيكر في مكتبتك')),
        );
      }
    } catch (e) {
      logger.e('❌ فشل حفظ الستيكر: $e');
    }
  }

  // ============================================================
  // 🗑️ حذف ستيكر
  // ============================================================
  
  Future<void> _deleteSticker(String id) async {
    try {
      setState(() {
        _savedStickers.removeWhere((s) => s['id'] == id);
        _filteredStickers = _savedStickers;
      });
      
      await HiveStorageService.saveSetting('saved_stickers', _savedStickers);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ تم حذف الستيكر')),
        );
      }
    } catch (e) {
      logger.e('❌ فشل حذف الستيكر: $e');
    }
  }

  // ============================================================
  // 🏗️ بناء الواجهة
  // ============================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 صنع ستيكر'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'من صورة'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI'),
            Tab(icon: Icon(Icons.collections), text: 'مكتبتي'),
          ],
          onTap: (index) => setState(() => _selectedTab = index),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildImageTab(),
                _buildAITab(),
                _buildLibraryTab(),
              ],
            ),
          ),
          
          if (_currentSticker != null) _buildPreviewSection(),
          
          if (_currentSticker != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendSticker,
                      icon: const Icon(Icons.send),
                      label: const Text('إرسال ستيكر'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveSticker(_currentSticker!),
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 📷 تبويب الصورة
  // ============================================================
  
  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'اختر صورة لتحويلها إلى ستيكر',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إزالة الخلفية تلقائياً',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.photo_library,
                label: 'المعرض',
                onPressed: _isLoading ? null : _pickImageFromGallery,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.camera_alt,
                label: 'الكاميرا',
                onPressed: _isLoading ? null : _pickImageFromCamera,
                color: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // ✅ ستيكرات سريعة
          const Text(
            'ستيكرات سريعة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildQuickStickerButton(
                    icon: prompt['icon']!,
                    label: prompt['text']!,
                    onPressed: () => _generateQuickSticker(prompt['text']!),
                  ),
                );
              },
            ),
          ),
          
          if (_currentSticker != null) ...[
            const Divider(height: 32),
            _buildStickerOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 50),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildQuickStickerButton({
    required String icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🤖 تبويب الذكاء الاصطناعي
  // ============================================================
  
  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
          const SizedBox(height: 16),
          const Text(
            'صِف الستيكر الذي تريده',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'مثال: قطة مبتسمة، قلب أحمر، نجمة متوهجة...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          // ✅ اقتراحات سريعة
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((p) {
              return ActionChip(
                label: Text('${p['icon']} ${p['text']}'),
                onPressed: () {
                  _aiPromptController.text = p['text']!;
                },
                backgroundColor: Colors.purple.shade100,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _aiPromptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب وصف الستيكر هنا...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _aiPromptController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ✅ خيارات AI
          Row(
            children: [
              Expanded(
                child: _buildAIOptionButton(
                  icon: Icons.style,
                  label: 'ستيكر عادي',
                  isSelected: !_isGif,
                  onPressed: () => setState(() => _isGif = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAIOptionButton(
                  icon: Icons.animation,
                  label: 'ستيكر متحرك',
                  isSelected: _isGif,
                  onPressed: () => setState(() => _isGif = true),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _isLoading || _aiPromptController.text.trim().isEmpty
                ? null
                : _generateStickerWithAI,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_isGif ? 'توليد ستيكر متحرك' : 'توليد ستيكر'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIOptionButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.purple : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.purple : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📚 تبويب المكتبة
  // ============================================================
  
  Widget _buildLibraryTab() {
    return Column(
      children: [
        // ✅ شريط البحث والتصفية
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 بحث في الستيكرات...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterStickers('');
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: _filterStickers,
              ),
              const SizedBox(height: 8),
              // ✅ فئات
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                            _filterStickers(_searchController.text);
                          });
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.purple.shade100,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // ✅ عرض الستيكرات
        Expanded(
          child: _filteredStickers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.collections, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'لا توجد نتائج'
                            : 'لا توجد ستيكرات محفوظة',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (_searchController.text.isEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedTab = 0),
                          icon: const Icon(Icons.add),
                          label: const Text('اصنع ستيكر جديد'),
                        ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredStickers.length,
                  itemBuilder: (context, index) {
                    final sticker = _filteredStickers[index];
                    final data = sticker['data'] as Uint8List;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentSticker = data);
                      },
                      onLongPress: () => _showStickerOptions(sticker),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                data,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 40);
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sticker['category'] ?? 'مخصص',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _filterStickers(String query) {
    setState(() {
      final searchLower = query.toLowerCase();
      _filteredStickers = _savedStickers.where((sticker) {
        final matchesSearch = sticker['name']?.toString().toLowerCase().contains(searchLower) ?? true;
        final matchesCategory = _selectedCategory == 'الكل' || sticker['category'] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // ============================================================
  // 🎨 خيارات الستيكر
  // ============================================================
  
  Widget _buildStickerOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'خيارات الستيكر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // ✅ صف الخيارات
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOptionChip(
                label: 'حدود',
                icon: Icons.border_all,
                value: _addBorder,
                onToggle: (v) => setState(() => _addBorder = v),
              ),
              _buildOptionChip(
                label: 'ظل',
                icon: Icons.shadow,
                value: _addShadow,
                onToggle: (v) => setState(() => _addShadow = v),
              ),
              _buildOptionChip(
                label: 'توهج',
                icon: Icons.flare,
                value: _addGlow,
                onToggle: (v) => setState(() => _addGlow = v),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // ✅ لون الحدود
          if (_addBorder)
            Row(
              children: [
                const Text('لون الحدود:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Colors.white, Colors.black, Colors.red, Colors.blue,
                      Colors.green, Colors.yellow, Colors.purple, Colors.orange,
                      Colors.pink, Colors.teal,
                    ].map((color) => GestureDetector(
                      onTap: () => setState(() => _borderColor = color),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _borderColor == color ? Colors.purple : Colors.grey,
                            width: _borderColor == color ? 3 : 1,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // ✅ سمك الحدود
          if (_addBorder)
            Row(
              children: [
                const Text('سمك:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _borderWidth.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 5,
                    onChanged: (value) => setState(() => _borderWidth = value.toInt()),
                  ),
                ),
                Text('$_borderWidth'),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // ✅ التدوير والتكبير
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('تدوير'),
                    Slider(
                      value: _rotation,
                      min: -3.14,
                      max: 3.14,
                      onChanged: (value) => setState(() => _rotation = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('تكبير'),
                    Slider(
                      value: _scale,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (value) => setState(() => _scale = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _applyStickerOptions,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: const Text('تطبيق التغييرات'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required IconData icon,
    required bool value,
    required Function(bool) onToggle,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: value,
      onSelected: onToggle,
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.purple.shade100,
    );
  }

  // ============================================================
  // 👁️ معاينة الستيكر
  // ============================================================
  
  Widget _buildPreviewSection() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.rotate(
                angle: _rotation,
                child: Transform.scale(
                  scale: _scale,
                  child: Image.memory(
                    _currentSticker!,
                    height: 130,
                    width: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.purple),
                  onPressed: _shareSticker,
                  tooltip: 'مشاركة',
                ),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.blue),
                  onPressed: () => _saveSticker(_currentSticker!),
                  tooltip: 'حفظ',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _clearSticker,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🎯 دوال الصنع
  // ============================================================
  
  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _service.pickImageFromGallery();
      if (imageFile != null) {
        await _makeSticker(imageFile);
      }
    } catch (e) {
      _showError('فشل اختيار الصورة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickImageFromCamera() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _service.pickImageFromCamera();
      if (imageFile != null) {
        await _makeSticker(imageFile);
      }
    } catch (e) {
      _showError('فشل التقاط الصورة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _makeSticker(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final sticker = await _service.makeStickerFromImage(
        imageFile: imageFile,
        addBorder: _addBorder,
        borderColor: _borderColor,
        borderWidth: _borderWidth,
        addShadow: _addShadow,
        addGlow: _addGlow,
      );
      
      if (sticker != null && mounted) {
        setState(() => _currentSticker = sticker);
        _showSuccess('✅ تم صنع الستيكر بنجاح');
      }
    } catch (e) {
      _showError('❌ فشل صنع الستيكر: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateStickerWithAI() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isGif) {
        // ✅ توليد ستيكر متحرك (GIF)
        final gifData = await _service.generateAnimatedSticker(prompt);
        if (gifData != null && mounted) {
          setState(() {
            _currentSticker = gifData;
            _isGif = true;
          });
          _showSuccess('✨ تم توليد الستيكر المتحرك بنجاح');
        }
      } else {
        // ✅ توليد ستيكر عادي
        final sticker = await _service.generateStickerWithAI(prompt);
        if (sticker != null && mounted) {
          setState(() => _currentSticker = sticker);
          _showSuccess('✨ تم توليد الستيكر بنجاح');
        }
      }
    } catch (e) {
      _showError('❌ فشل التوليد: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQuickSticker(String prompt) async {
    _aiPromptController.text = prompt;
    await _generateStickerWithAI();
  }
  
  Future<void> _applyStickerOptions() async {
    if (_currentSticker == null) return;
    
    setState(() => _isLoading = true);
    try {
      Uint8List newSticker = _currentSticker!;
      
      if (_addBorder) {
        newSticker = StickerMakerService.addStickerBorder(
          newSticker,
          borderWidth: _borderWidth,
          borderColor: _borderColor,
        );
      }
      
      if (_addShadow) {
        newSticker = StickerMakerService.addShadow(newSticker);
      }
      
      if (_addGlow) {
        newSticker = StickerMakerService.addGlow(newSticker);
      }
      
      setState(() => _currentSticker = newSticker);
      _showSuccess('تم تطبيق التغييرات');
    } catch (e) {
      _showError('❌ فشل تطبيق التغييرات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🛠️ دوال مساعدة
  // ============================================================
  
  void _sendSticker() {
    if (_currentSticker != null && widget.onStickerCreated != null) {
      widget.onStickerCreated!(_currentSticker!);
      Navigator.pop(context);
    } else if (_currentSticker != null) {
      // ✅ إرسال إلى المحادثة الحالية
      Navigator.pop(context, _currentSticker);
    }
  }
  
  void _clearSticker() {
    setState(() {
      _currentSticker = null;
      _isGif = false;
    });
  }
  
  Future<void> _shareSticker() async {
    if (_currentSticker == null) return;
    
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_currentSticker!);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎨 ستيكر من Privoo',
      );
    } catch (e) {
      _showError('❌ فشل المشاركة: $e');
    }
  }
  
  void _showStickerOptions(Map<String, dynamic> sticker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send, color: Colors.green),
              title: const Text('إرسال'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentSticker = sticker['data'] as Uint8List);
                _sendSticker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف'),
              onTap: () {
                Navigator.pop(context);
                _deleteSticker(sticker['id'] as String);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎨 صنع ستيكر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📌 كيفية الصنع:'),
            SizedBox(height: 8),
            Text('1. اختر صورة من المعرض أو الكاميرا'),
            Text('2. انتظر حتى تتم إزالة الخلفية'),
            Text('3. أضف حدود أو ظل حسب الرغبة'),
            Text('4. احفظ أو أرسل الستيكر'),
            SizedBox(height: 12),
            Text('🤖 أو استخدم الذكاء الاصطناعي:'),
            SizedBox(height: 8),
            Text('• اكتب وصفاً للستيكر'),
            Text('• اختر عادي أو متحرك'),
            Text('• انتظر التوليد'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}