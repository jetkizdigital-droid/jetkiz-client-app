from pathlib import Path

restaurant = Path('lib/features/menu/presentation/restaurantMenuPage.dart')
text = restaurant.read_text(encoding='utf-8')

old_grid = """          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: menuProductCardExtent(
              context,
              horizontalPadding: 32,
            ),
          ),"""
new_grid = """          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),"""
assert text.count(old_grid) == 1, text.count(old_grid)
text = text.replace(old_grid, new_grid, 1)

old_title = """                      LocalizedText(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if ((item.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        LocalizedText(
                          item.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5F5F5F),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ],"""
new_title = """                      LocalizedText(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),"""
assert text.count(old_title) == 1, text.count(old_title)
text = text.replace(old_title, new_title, 1)

old_price = """                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: LocalizedText(
                          formatMenuPrice(item.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),"""
new_price = """                    Expanded(
                      child: LocalizedText(
                        item.priceText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),"""
assert text.count(old_price) == 1, text.count(old_price)
text = text.replace(old_price, new_price, 1)
restaurant.write_text(text, encoding='utf-8')

category = Path('lib/features/menu/presentation/categoryProductsPage.dart')
text = category.read_text(encoding='utf-8')

old_grid = """          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: menuProductCardExtent(
              context,
              horizontalPadding: 30,
            ),
          ),"""
new_grid = """          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),"""
assert text.count(old_grid) == 1, text.count(old_grid)
text = text.replace(old_grid, new_grid, 1)

old_title = """                child: LocalizedText(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),"""
new_title = """                child: LocalizedText(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),"""
assert text.count(old_title) == 1, text.count(old_title)
text = text.replace(old_title, new_title, 1)

old_price = """                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: LocalizedText(
                        formatMenuPrice(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),"""
new_price = """                  Expanded(
                    child: LocalizedText(
                      '${product.price}₸',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),"""
assert text.count(old_price) == 1, text.count(old_price)
text = text.replace(old_price, new_price, 1)
category.write_text(text, encoding='utf-8')

helper = Path('lib/features/menu/presentation/productCardLayout.dart')
helper.write_text("""import 'dart:math' as math;

import 'package:flutter/material.dart';

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
""", encoding='utf-8')

test = Path('test/features/menu/product_card_layout_test.dart')
test.write_text("""import 'package:flutter/material.dart';
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
""", encoding='utf-8')
