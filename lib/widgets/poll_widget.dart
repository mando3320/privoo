// widgets/poll_widget.dart
import 'package:flutter/material.dart';

class PollOption {
  final String id;
  final String text;
  int votes;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });
}

class PollWidget extends StatefulWidget {
  final String? pollId;
  final String? question;
  final List<PollOption> options;
  final String? selectedOptionId;
  final Function(String optionId)? onVote;

  const PollWidget({
    super.key,
    this.pollId,
    this.question,
    this.options = const [],
    this.selectedOptionId,
    this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedOptionId;
  }

  void vote(String id) {
    if (selected != null) return;

    setState(() {
      selected = id;
      final option = widget.options.firstWhere((e) => e.id == id);
      option.votes += 1;
    });

    widget.onVote?.call(id);
  }

  int get totalVotes => widget.options.fold(0, (sum, item) => sum + item.votes);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question ?? (widget.pollId != null ? "Poll ID: ${widget.pollId}" : "Poll"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...widget.options.map((option) {
            final percent = totalVotes == 0
                ? 0.0
                : option.votes / totalVotes;

            return GestureDetector(
              onTap: () => vote(option.id),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected == option.id
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.text),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(percent * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}