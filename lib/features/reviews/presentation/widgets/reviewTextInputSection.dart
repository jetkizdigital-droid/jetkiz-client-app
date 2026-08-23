import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';

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
      decoration: InputDecoration(
        hintText: AppLocalizationScope.of(context)
            .strings
            .localize('Поделитесь впечатлениями...'),
        border: OutlineInputBorder(),
      ),
    );
  }
}
