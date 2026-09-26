import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app applies one platform-native scroll behavior', () {
    final app = File('lib/app/app.dart').readAsStringSync();
    final behavior =
        File('lib/core/ui/appScrollBehavior.dart').readAsStringSync();

    expect(app, contains('scrollBehavior: const AppScrollBehavior()'));
    expect(behavior, contains('ClampingScrollPhysics'));
    expect(behavior, contains('BouncingScrollPhysics'));
  });

  test('restaurant menu avoids stacked sticky headers and forced bounce', () {
    final source = File(
      'lib/features/menu/presentation/restaurantMenuPage.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('_SmoothScrollBehavior')));
    expect(source, isNot(contains('physics: const BouncingScrollPhysics')));
    expect(
      'SliverPersistentHeader'.allMatches(source).length,
      2,
      reason:
          'One occurrence is the actual sticky search/categories header and one is its delegate base class.',
    );
    expect(
      source,
      contains(
        'SliverToBoxAdapter(\n                              child: RepaintBoundary(',
      ),
    );
  });

  test('long category and search pages stay lazily built', () {
    final category = File(
      'lib/features/categories/presentation/categoryProductsPage.dart',
    ).readAsStringSync();
    final search = File(
      'lib/features/search/presentation/searchPage.dart',
    ).readAsStringSync();

    expect(category, isNot(contains('shrinkWrap: true')));
    expect(category, isNot(contains('GridView.builder')));
    expect(category, contains('ListView.separated'));
    expect(category, contains('ListView.builder'));
    expect(category, contains('isScrollControlled: true'));

    expect(search, contains('ListView.builder'));
    expect(search, isNot(contains('...result.products.asMap().entries.map')));
    expect(
      search,
      isNot(contains('...result.restaurants.asMap().entries.map')),
    );
  });

  test('scrolling thumbnails decode close to their display width', () {
    for (final path in [
      'lib/features/search/presentation/searchPage.dart',
      'lib/features/cart/presentation/cartPage.dart',
      'lib/features/orders/presentation/ordersPage.dart',
      'lib/features/favorites/presentation/favoritesPage.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('imageDecodeWidth('),
        reason: '$path should avoid full-resolution thumbnail decoding',
      );
    }
  });
}
