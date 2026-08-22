import 'package:flutter/material.dart';

class ReviewTextInputSection extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ReviewTextInputSection({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 5,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Поделитесь впечатлениями...',
        border: OutlineInputBorder(),
      ),
    );
  }
}
