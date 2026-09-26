import 'package:flutter/widgets.dart';

/// Decodes network images near the physical size they occupy on screen.
///
/// This avoids decoding multi-megapixel restaurant/product images for small
/// scrolling cards while keeping the image sharp at the device pixel ratio.
int imageDecodeWidth(
  BuildContext context,
  double logicalWidth, {
  int minPixels = 64,
  int maxPixels = 2048,
}) {
  final pixels = (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
  return pixels.clamp(minPixels, maxPixels).toInt();
}
