import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/menu/presentation/productCardLayout.dart';

void main() {
  testWidgets('image decode target follows displayed product-card size', (
    tester,
  ) async {
    int? cacheSize;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          devicePixelRatio: 3,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              cacheSize = menuProductImageCacheSize(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(cacheSize, inInclusiveRange(128, 2048));
    expect(cacheSize, lessThan(1024));
  });
}
