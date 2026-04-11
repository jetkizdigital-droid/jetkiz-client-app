import 'package:flutter/material.dart';

class ReviewQuickReactionsSection extends StatefulWidget {
  const ReviewQuickReactionsSection({super.key});

  @override
  State<ReviewQuickReactionsSection> createState() =>
      _ReviewQuickReactionsSectionState();
}

class _ReviewQuickReactionsSectionState
    extends State<ReviewQuickReactionsSection> {
  final reactions = ['👍', '❤️', '🔥', '😋'];
  final selected = <int>{};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(reactions.length, (i) {
        final active = selected.contains(i);

        return GestureDetector(
          onTap: () {
            setState(() {
              active ? selected.remove(i) : selected.add(i);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(reactions[i]),
          ),
        );
      }),
    );
  }
}