// widgets/privoo_reply_signature.dart
import 'package:flutter/material.dart';

class PrivooReplySignature extends StatelessWidget {
  final String reply;
  const PrivooReplySignature({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple[700],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            reply,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'تم الرد من فريق privoo\nقائد المشروع MaNdOoOoO',
          style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
