import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/message_model.dart';

class PinnedMessagesScreen extends StatelessWidget {
  final String chatId;

  const PinnedMessagesScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل المثبتة')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('isPinned', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data?.docs ?? [];

          if (messages.isEmpty) {
            return const Center(child: Text('لا توجد رسائل مثبتة'));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index].data() as Map<String, dynamic>;
              final message = MessageModel.fromMap(messages[index].id, data);
              return ListTile(
                title: Text(message.content.length > 50
                    ? '${message.content.substring(0, 50)}...'
                    : message.content),
                subtitle: Text('من: ${message.senderId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.push_pin, color: Colors.amber),
                  onPressed: () async {
                    await messages[index].reference.update({'isPinned': false});
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