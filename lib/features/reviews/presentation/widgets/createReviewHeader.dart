import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

class CreateReviewHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CreateReviewHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          const Expanded(
            child: LocalizedText(
              'Оставить отзыв',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
