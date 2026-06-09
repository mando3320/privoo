// lib/services/sticker_service.dart
import 'package:flutter/material.dart';
import 'emoji_service.dart';

class StickerService {
  // ✅ استخدام الإيموجي الكامل من EmojiService
  static List<Map<String, String>> getStickers() {
    return EmojiService.getAllEmojis();
  }
  
  // ✅ البحث في الإيموجي
  static List<Map<String, String>> searchStickers(String query) {
    if (query.isEmpty) return getStickers();
    return EmojiService.searchEmojis(query);
  }
  
  static String parseStickers(String text) {
    return text;
  }
}

// ✅ StickerPicker محدث مع شريط بحث وتصنيفات
class StickerPicker extends StatefulWidget {
  final Function(String) onStickerSelected;
  
  const StickerPicker({super.key, required this.onStickerSelected});
  
  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  final List<Map<String, List<Map<String, String>>>> _categories = [
    {'😊 الوجوه': EmojiService.smileys},
    {'🚗 وسائل النقل': EmojiService.vehicles},
    {'🐱 حيوانات': EmojiService.animals},
    {'🍕 طعام': EmojiService.food},
    {'⚽ رياضة': EmojiService.sports},
    {'🏳️ أعلام': EmojiService.flags},
    {'💛 رموز': EmojiService.objects},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ شريط البحث
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 بحث عن إيموجي...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        
        // ✅ نتائج البحث
        if (_searchQuery.isNotEmpty)
          Expanded(
            child: _buildSearchResults(),
          )
        else
          Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((cat) => Tab(text: cat.keys.first)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) => _buildEmojiGrid(cat.values.first)).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    final results = EmojiService.searchEmojis(_searchQuery);
    if (results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }
    return _buildEmojiGrid(results);
  }
  
  Widget _buildEmojiGrid(List<Map<String, String>> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return InkWell(
          onTap: () => widget.onStickerSelected(emoji['code']!),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji['code']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  emoji['name']!,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}