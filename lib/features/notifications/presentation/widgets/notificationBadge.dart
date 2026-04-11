import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.offset = const Offset(6, -6),
    this.minSize = 18,
  });

  final int count;
  final Widget child;
  final Offset offset;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }

    final label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: offset.dx,
          top: offset.dy,
          child: Container(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white,
                width: 1.4,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}