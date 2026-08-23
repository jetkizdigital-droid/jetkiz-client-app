import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

class ReviewOrderContextCard extends StatelessWidget {
  final String restaurantName;

  const ReviewOrderContextCard({
    super.key,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          LocalizedText(
            restaurantName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const LocalizedText('Ваш заказ доставлен'),
        ],
      ),
    );
  }
}
