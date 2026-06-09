// views/settings/local_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';

class LocalWebViewScreen extends StatefulWidget {
  final String assetPath; // e.g. 'web/privacy_policy.html'
  final String? title;

  const LocalWebViewScreen({super.key, required this.assetPath, this.title});

  @override
  State<LocalWebViewScreen> createState() => _LocalWebViewScreenState();
}

class _LocalWebViewScreenState extends State<LocalWebViewScreen> {
  String? _html;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final content = await rootBundle.loadString(widget.assetPath);
      if (!mounted) return;
      setState(() {
        _html = content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _html = '<h3>فشل تحميل الصفحة</h3><p>لا يمكن العثور على المورد ${widget.assetPath}.</p>';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'صفحة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _html != null
                    ? Html(data: _html!)
                    : const Text('لا يوجد محتوى'),
              ),
            ),
    );
  }
}
