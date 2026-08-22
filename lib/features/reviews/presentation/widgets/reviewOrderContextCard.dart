import 'package:flutter/material.dart';

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
          Text(
            restaurantName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Ваш заказ доставлен'),
        ],
      ),
    );
  }
}
