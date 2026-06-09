// lib/views/channels/create_channel_screen.dart
import 'package:flutter/material.dart';

class CreateChannelScreen extends StatelessWidget {
  const CreateChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء قناة جديدة')),
      body: const Center(
        child: Text('سيتم إضافة إنشاء القنوات قريباً'),
      ),
    );
  }
}