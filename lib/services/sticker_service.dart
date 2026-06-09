// lib/services/sticker_service.dart
import 'package:flutter/material.dart';

class StickerService {
  static const List<Map<String, String>> defaultStickers = [
    {'code': '😀', 'name': 'ابتسامة'},
    {'code': '😂', 'name': 'ضحك'},
    {'code': '🥰', 'name': 'حب'},
    {'code': '😎', 'name': 'رائع'},
    {'code': '😢', 'name': 'حزين'},
    {'code': '😡', 'name': 'غاضب'},
    {'code': '🎉', 'name': 'احتفال'},
    {'code': '❤️', 'name': 'قلب'},
    {'code': '🔥', 'name': 'ممتاز'},
    {'code': '✅', 'name': 'تم'},
    {'code': '🙏', 'name': 'شكراً'},
    {'code': '👍', 'name': 'أعجبني'},
    {'code': '👎', 'name': 'لم يعجبني'},
  ];

  static List<Map<String, String>> getStickers() {
    return defaultStickers;
  }

  static String parseStickers(String text) {
    // استبدال رموز النص بالإيموجي (إذا أردت)
    return text;
  }
}

class StickerPicker extends StatelessWidget {
  final Function(String) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
        ),
        itemCount: StickerService.defaultStickers.length,
        itemBuilder: (context, index) {
          final sticker = StickerService.defaultStickers[index];
          return InkWell(
            onTap: () => onStickerSelected(sticker['code']!),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  sticker['code']!,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}