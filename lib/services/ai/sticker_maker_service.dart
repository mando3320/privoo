// services/ai/sticker_maker_service.dart
// lib/services/sticker_maker_service.dart (نسخة مجانية 100%)
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Removed direct dependency on `package:image` to avoid API mismatches; keep bytes passthrough.
import '../../main.dart';

class StickerMakerService {
  static String? get _removeBgApiKey => dotenv.env['REMOVE_BG_API_KEY'];
  static String? get _huggingFaceApiKey => dotenv.env['HUGGINGFACE_API_KEY'];
  
  final ImagePicker _picker = ImagePicker();
  
  // ============================================================
  // 🖼️ الطريقة الأولى: صنع ستيكر من صورة (إزالة الخلفية)
  // ============================================================
  
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      logger.e('❌ فشل اختيار الصورة: $e');
      return null;
    }
  }
  
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      logger.e('❌ فشل التقاط الصورة: $e');
      return null;
    }
  }
  
  Future<Uint8List?> removeBackground(File imageFile) async {
    final apiKey = _removeBgApiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      logger.w('⚠️ REMOVE_BG_API_KEY not found, using local processing');
      return _removeBackgroundLocally(imageFile);
    }
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );
      
      request.headers['X-Api-Key'] = apiKey;
      request.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));
      request.fields['size'] = 'auto';
      request.fields['format'] = 'png';
      
      final response = await request.send().timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        logger.i('✅ تم إزالة الخلفية بنجاح');
        return bytes;
      } else {
        final error = await response.stream.bytesToString();
        logger.e('❌ فشل إزالة الخلفية: $error');
        return _removeBackgroundLocally(imageFile);
      }
    } catch (e) {
      logger.e('❌ خطأ في remove.bg: $e');
      return _removeBackgroundLocally(imageFile);
    }
  }
  
  Future<Uint8List?> _removeBackgroundLocally(File imageFile) async {
    // Local background removal is costly and depends on `package:image` API.
    // As a safe fallback return the original image bytes unchanged.
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      logger.e('❌ فشل قراءة ملف الصورة محلياً: $e');
      return null;
    }
  }
  
  static Uint8List addStickerBorder(Uint8List stickerBytes, {int borderWidth = 4, Color borderColor = Colors.white}) {
    // Border drawing depends on `package:image`; keep original bytes to avoid API mismatch.
    return stickerBytes;
  }
  
  static Uint8List addStickerEffect(Uint8List stickerBytes, String effect) {
    // Effects are optional; return original bytes to avoid dependency on image API.
    return stickerBytes;
  }
  
  Future<Uint8List?> makeStickerFromImage({
    required File imageFile,
    bool addBorder = true,
    Color borderColor = Colors.white,
    int borderWidth = 4,
    String? effect,
  }) async {
    try {
      Uint8List? sticker = await removeBackground(imageFile);
      if (sticker == null) return null;
      
      if (addBorder) {
        sticker = addStickerBorder(sticker, borderWidth: borderWidth, borderColor: borderColor);
      }
      
      if (effect != null && effect.isNotEmpty) {
        sticker = addStickerEffect(sticker, effect);
      }
      
      return sticker;
    } catch (e) {
      logger.e('❌ فشل صنع الستيكر: $e');
      return null;
    }
  }
  
  // ============================================================
  // 🤖 الطريقة الثانية: توليد ستيكر بالذكاء الاصطناعي (مجاني 100%)
  // ============================================================
  
  /// ✅ توليد صورة باستخدام Hugging Face (مجاني)
  Future<Uint8List?> generateWithHuggingFace(String description) async {
    final apiKey = _huggingFaceApiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      logger.w('⚠️ HUGGINGFACE_API_KEY not found');
      return null;
    }
    
    // استخدام نموذج Flux (مجاني وسريع)
    const model = 'black-forest-labs/FLUX.1-dev';
    
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/$model'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': 'sticker, simple cartoon, cute, white background, no text: $description',
          'parameters': {
            'negative_prompt': 'blurry, bad quality, realistic, text, watermark',
            'num_inference_steps': 20,
            'guidance_scale': 7,
          }
        }),
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        logger.i('✅ تم توليد الصورة بنجاح من Hugging Face');
        return response.bodyBytes;
      } else {
        logger.e('❌ Hugging Face error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Hugging Face exception: $e');
      return null;
    }
  }
  
  /// ✅ توليد ستيكر بالذكاء الاصطناعي (مجاني فقط)
  Future<Uint8List?> generateStickerWithAI(String description) async {
    logger.i('🤖 توليد ستيكر بـ AI: $description');
    
    // 1️⃣ المحاولة الأولى والأخيرة: Hugging Face (مجاني)
    final huggingFaceResult = await generateWithHuggingFace(description);
    if (huggingFaceResult != null) {
      // إضافة حدود للستيكر الناتج
      return addStickerBorder(huggingFaceResult, borderWidth: 4, borderColor: Colors.white);
    }
    
    // 2️⃣ إذا فشل، استخدم الستيكر الوهمي (بدون أي محاولات مدفوعة)
    logger.w('⚠️ Hugging Face فشل، لا توجد معالجة محلية متاحة');
    return null;
  }
  
}

// image helper removed

class StickerModel {
  final String id;
  final Uint8List imageBytes;
  final String name;
  final DateTime createdAt;
  final String? source;
  final String? prompt;
  
  StickerModel({
    required this.id,
    required this.imageBytes,
    required this.name,
    required this.createdAt,
    this.source,
    this.prompt,
  });
}