import 'dart:math' as math;

import 'package:flutter/material.dart';

const double menuProductImageAspectRatio = 4 / 3;

String formatMenuPrice(int price) {
  final sign = price < 0 ? '-' : '';
  final digits = price.abs().toString();
  final groups = <String>[];

  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.insert(0, digits.substring(start, end));
  }

  return '$sign${groups.join(' ')} ₸';
}

/// Decode food images close to their actual on-screen size without changing
/// the visual dimensions of the product card.
int menuProductImageCacheSize(
  BuildContext context, {
  double horizontalPadding = 30,
  double crossAxisSpacing = 14,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final gridWidth = math.max(0.0, screenWidth - horizontalPadding);
  final cardWidth = math.max(1.0, (gridWidth - crossAxisSpacing) / 2);
  final imageLogicalWidth = math.max(1.0, cardWidth - 16);
  final decodedPixels =
      (imageLogicalWidth * MediaQuery.devicePixelRatioOf(context)).round();

  return decodedPixels.clamp(128, 2048).toInt();
}
