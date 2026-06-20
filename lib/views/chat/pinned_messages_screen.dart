// lib/views/chat/pinned_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/message_model.dart';

class PinnedMessagesScreen extends StatelessWidget {
  final String chatId;

  const PinnedMessagesScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل المثبتة')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .eq('is_pinned', true)
            .order('timestamp', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return const Center(child: Text('لا توجد رسائل مثبتة'));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index];
              final message = MessageModel.fromSupabase(data);
              return ListTile(
                title: Text(message.content.length > 50
                    ? '${message.content.substring(0, 50)}...'
                    : message.content),
                subtitle: Text('من: ${message.senderId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.push_pin, color: Colors.amber),
                  onPressed: () async {
                    await Supabase.instance.client
                        .from('messages')
                        .update({'is_pinned': false})
                        .eq('id', message.id);
                    setState(() {});
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}