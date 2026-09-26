import 'dart:math' as math;

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

/// Returns a safe decode width for a BoxFit.cover destination when the source
/// aspect ratio is unknown. The height contributes to the requested width so
/// common landscape food photos are not decoded too narrowly and then scaled
/// back up in the UI.
int imageDecodeWidthForCover(
  BuildContext context, {
  required double logicalWidth,
  required double logicalHeight,
  double maxLandscapeAspectRatio = 2,
  int minPixels = 64,
  int maxPixels = 2048,
}) {
  final requiredLogicalWidth = math.max(
    logicalWidth,
    logicalHeight * maxLandscapeAspectRatio,
  );

  return imageDecodeWidth(
    context,
    requiredLogicalWidth,
    minPixels: minPixels,
    maxPixels: maxPixels,
  );
}
