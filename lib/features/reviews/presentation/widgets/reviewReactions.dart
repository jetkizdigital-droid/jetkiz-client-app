import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';

class ReviewReactions extends StatelessWidget {
  const ReviewReactions({
    super.key,
    required this.items,
    this.onAddReaction,
  });

  final List<ReviewReactionItem> items;
  final VoidCallback? onAddReaction;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final item in items) {
      grouped[item.type] = (grouped[item.type] ?? 0) + 1;
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...entries.map(
          (entry) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_emoji(entry.key)} ${entry.value}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onAddReaction,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 18,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }

  String _emoji(String type) {
    switch (type.toUpperCase()) {
      case 'LIKE':
        return '👍';
      case 'LOVE':
        return '❤️';
      case 'FIRE':
        return '🔥';
      case 'USEFUL':
        return '😊';
      case 'YUMMY':
        return '😋';
      default:
        return '•';
    }
  }
}