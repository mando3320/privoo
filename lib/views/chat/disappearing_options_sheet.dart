import 'package:flutter/material.dart';
import '../../../models/message_model.dart';

class DisappearingOptionsSheet extends StatelessWidget {
  final Function(DisappearDuration) onSelected;

  const DisappearingOptionsSheet({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مدة اختفاء الرسالة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ...DisappearDuration.values.map((duration) {
            return ListTile(
              leading: Icon(
                duration.seconds == 0 ? Icons.timer_off : Icons.timer,
                color: duration.seconds == 0 ? Colors.grey : Colors.blue,
              ),
              title: Text(duration.label),
              onTap: () {
                Navigator.pop(context);
                onSelected(duration);
              },
            );
          }),
        ],
      ),
    );
  }
}