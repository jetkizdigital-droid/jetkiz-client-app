import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Computes enough vertical space for a two-column product card while keeping
/// the product image square. The content reserve is independent from device
/// width, so title/description/price controls do not overlap on narrow phones.
double menuProductCardExtent(
  BuildContext context, {
  required double horizontalPadding,
  double crossAxisSpacing = 14,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final gridWidth = math.max(0.0, screenWidth - horizontalPadding);
  final cardWidth = math.max(0.0, (gridWidth - crossAxisSpacing) / 2);
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final scaleExtra = math.max(0.0, math.min(0.8, textScale - 1.0)) * 72;

  return math.max(270.0, cardWidth + 146 + scaleExtra);
}

/// Decode food images close to their actual on-screen size instead of keeping
/// unnecessarily large source bitmaps in memory while scrolling the menu.
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

String formatMenuPrice(int value) {
  final negative = value < 0;
  final raw = value.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index++) {
    if (index > 0 && (raw.length - index) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(raw[index]);
  }

  return '${negative ? '-' : ''}${buffer.toString()} ₸';
}
