import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/menu/presentation/productCardLayout.dart';

void main() {
  testWidgets('product card reserves content space on a narrow phone', (
    tester,
  ) async {
    double? extent;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          devicePixelRatio: 2,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              extent = menuProductCardExtent(
                context,
                horizontalPadding: 32,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // A fixed 0.72 aspect ratio used to leave roughly 50 px too little room
    // below the square image on narrow devices. Keep enough vertical reserve
    // for two title lines, two description lines, price and cart controls.
    expect(extent, greaterThanOrEqualTo(280));
  });

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

  test('menu price formatting keeps the numeric value unchanged', () {
    expect(formatMenuPrice(2500), '2 500 ₸');
    expect(formatMenuPrice(2590), '2 590 ₸');
    expect(formatMenuPrice(0), '0 ₸');
  });
}
