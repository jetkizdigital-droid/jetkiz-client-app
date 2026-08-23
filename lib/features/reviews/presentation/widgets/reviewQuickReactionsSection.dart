import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

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
              color: active ? const Color(0xFF489F2A) : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: LocalizedText(reactions[i]),
          ),
        );
      }),
    );
  }
}
