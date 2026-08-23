import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

class ReviewRatingSection extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const ReviewRatingSection({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LocalizedText(
          'Оцените заказ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () => onChanged(i + 1),
              icon: Icon(
                Icons.star,
                size: 32,
                color: i < rating ? Colors.orange : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
