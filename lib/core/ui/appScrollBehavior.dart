import 'package:flutter/material.dart';

/// One scroll feel for the whole client:
/// - Android/desktop use clamping physics, avoiding forced iOS-style bounce.
/// - iOS/macOS keep native bouncing.
/// - the platform overscroll glow is suppressed so long lists stay visually
///   stable while preserving normal drag/fling behavior.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = getPlatform(context);

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const BouncingScrollPhysics();
    }

    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
