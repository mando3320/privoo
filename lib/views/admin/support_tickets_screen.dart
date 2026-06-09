// lib/views/admin/support_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تذاكر الدعم'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final tickets = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final data = ticket.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('تذكرة #${ticket.id.substring(0, 8)}'),
                  subtitle: Text('الحالة: ${data['status'] ?? "جديد"}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(data['encrypted_message'] ?? 'رسالة مشفرة'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _replyController,
                            decoration: const InputDecoration(
                              hintText: 'اكتب ردك...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final reply = _replyController.text.trim();
                              if (reply.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('support_messages')
                                    .doc(ticket.id)
                                    .update({
                                  'reply': reply,
                                  'repliedAt': FieldValue.serverTimestamp(),
                                  'status': 'replied',
                                });
                                _replyController.clear();
                              }
                            },
                            child: const Text('إرسال رد'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
