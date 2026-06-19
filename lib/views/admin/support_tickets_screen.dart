// lib/views/admin/support_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _processingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تذاكر الدعم'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('support_messages')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final tickets = snapshot.data ?? [];
          
          if (tickets.isEmpty) {
            return const Center(child: Text('لا توجد تذاكر دعم'));
          }
          
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final id = ticket['id']?.toString() ?? '';
              final encryptedMessage = ticket['encrypted_message'] ?? 'رسالة مشفرة';
              final status = ticket['status'] ?? 'جديد';
              final isProcessing = _processingId == id;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('تذكرة #${id.substring(0, 8)}'),
                  subtitle: Text('الحالة: $status'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(encryptedMessage),
                          const SizedBox(height: 16),
                          if (ticket['reply'] != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✅ الرد:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(ticket['reply']),
                                ],
                              ),
                            ),
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
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    final reply = _replyController.text.trim();
                                    if (reply.isNotEmpty) {
                                      setState(() => _processingId = id);
                                      try {
                                        await _supabase
                                            .from('support_messages')
                                            .update({
                                              'reply': reply,
                                              'replied_at': DateTime.now().toIso8601String(),
                                              'status': 'replied',
                                            })
                                            .eq('id', id);
                                        
                                        _replyController.clear();
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✅ تم إرسال الرد بنجاح')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('❌ خطأ: $e')),
                                        );
                                      } finally {
                                        setState(() => _processingId = null);
                                      }
                                    }
                                  },
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('إرسال رد'),
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