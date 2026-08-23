import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

class ReviewSubmitBar extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool loading;

  const ReviewSubmitBar({
    super.key,
    required this.onSubmit,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ElevatedButton(
        onPressed: loading ? null : onSubmit,
        child: loading
            ? const CircularProgressIndicator()
            : const LocalizedText('Отправить отзыв'),
      ),
    );
  }
}
