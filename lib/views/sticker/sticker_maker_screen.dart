// views/sticker/sticker_maker_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai/sticker_maker_service.dart';
import '../../main.dart';

class StickerMakerScreen extends StatefulWidget {
  final Function(Uint8List)? onStickerCreated;
  
  const StickerMakerScreen({super.key, this.onStickerCreated});

  @override
  State<StickerMakerScreen> createState() => _StickerMakerScreenState();
}

class _StickerMakerScreenState extends State<StickerMakerScreen> with SingleTickerProviderStateMixin {
  final StickerMakerService _service = StickerMakerService();
  final TextEditingController _aiPromptController = TextEditingController();
  
  Uint8List? _currentSticker;
  bool _isLoading = false;
  int _selectedTab = 0;
  bool _addBorder = true;
  Color _borderColor = Colors.white;
  int _borderWidth = 4;
  
  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 صنع ستيكر'),
        centerTitle: true,
        bottom: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'من صورة'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'بالذكاء الاصطناعي'),
          ],
          onTap: (index) => setState(() => _selectedTab = index),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedTab == 0 ? _buildImageTab() : _buildAITab(),
          ),
          
          if (_currentSticker != null) _buildPreviewSection(),
          
          if (_currentSticker != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _sendSticker,
                icon: const Icon(Icons.send),
                label: const Text('إرسال ستيكر'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildImageTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('اختر صورة لتحويلها إلى ستيكر'),
        const SizedBox(height: 8),
        Text(
          'سيتم إزالة الخلفية تلقائياً',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImageFromGallery(),
              icon: const Icon(Icons.photo_library),
              label: const Text('المعرض'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImageFromCamera(),
              icon: const Icon(Icons.camera_alt),
              label: const Text('الكاميرا'),
            ),
          ],
        ),
        
        if (_currentSticker != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          _buildStickerOptions(),
        ],
      ],
    );
  }
  
  Widget _buildStickerOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('خيارات الستيكر', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('إضافة حدود'),
            value: _addBorder,
            onChanged: (value) => setState(() => _addBorder = value),
          ),
          if (_addBorder) ...[
            ListTile(
              title: const Text('لون الحدود'),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: () => _pickBorderColor(),
            ),
            ListTile(
              title: const Text('سمك الحدود'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _borderWidth.toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 5,
                  onChanged: (value) => setState(() => _borderWidth = value.toInt()),
                ),
              ),
            ),
          ],
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _applyStickerOptions,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
            label: const Text('تطبيق التغييرات'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAITab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
          const SizedBox(height: 16),
          const Text('صِف الستيكر الذي تريده'),
          const SizedBox(height: 8),
          Text(
            'مثال: قطة مبتسمة، قلب أحمر، نجمة متوهجة...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _aiPromptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب وصف الستيكر هنا...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _aiPromptController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading || _aiPromptController.text.trim().isEmpty
                ? null
                : () => _generateStickerWithAI(),
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text('توليد ستيكر'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('النتيجة:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Image.memory(_currentSticker!, height: 150, width: 150),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _service.pickImageFromGallery();
      if (imageFile != null) {
        await _makeSticker(imageFile);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickImageFromCamera() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _service.pickImageFromCamera();
      if (imageFile != null) {
        await _makeSticker(imageFile);
      }
    } finally {
      setState(() => _isLoading = false);
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
      );
      
      if (sticker != null && mounted) {
        setState(() => _currentSticker = sticker);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم صنع الستيكر بنجاح')),
        );
      }
    } catch (e) {
      logger.e('خطأ في صنع الستيكر: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل صنع الستيكر: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateStickerWithAI() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final sticker = await _service.generateStickerWithAI(prompt);
      
      if (sticker != null && mounted) {
        setState(() => _currentSticker = sticker);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ تم توليد الستيكر بنجاح')),
        );
      }
    } catch (e) {
      logger.e('خطأ في توليد الستيكر: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل التوليد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
      
      setState(() => _currentSticker = newSticker);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تطبيق التغييرات')),
      );
    } catch (e) {
      logger.e('خطأ في تطبيق التغييرات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickBorderColor() async {
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لون الحدود'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: GridView.count(
            crossAxisCount: 4,
            children: [
              Colors.white, Colors.black, Colors.red, Colors.blue,
              Colors.green, Colors.yellow, Colors.purple, Colors.orange,
              Colors.pink, Colors.teal, Colors.brown, Colors.grey,
            ].map((color) => GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
    
    if (color != null && mounted) {
      setState(() => _borderColor = color);
    }
  }
  
  void _sendSticker() {
    if (_currentSticker != null && widget.onStickerCreated != null) {
      widget.onStickerCreated!(_currentSticker!);
      Navigator.pop(context);
    }
  }
}