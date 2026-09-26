import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant menu keeps lazy sliver rendering and bounded image decoding', () {
    final source = File(
      'lib/features/menu/presentation/restaurantMenuPage.dart',
    ).readAsStringSync();

    expect(source, contains('SliverList.separated('));
    expect(source, contains('cacheExtent: 600'));
    expect(source, contains('cacheWidth: cacheWidth'));
    expect(source, contains('RepaintBoundary('));
    expect(
      source,
      isNot(
        contains(
          'physics: const BouncingScrollPhysics(\n'
          '                            parent: AlwaysScrollableScrollPhysics(),',
        ),
      ),
    );
  });

  test('search results are built lazily instead of expanding all cards', () {
    final source = File(
      'lib/features/search/presentation/searchPage.dart',
    ).readAsStringSync();

    expect(source, contains('CustomScrollView('));
    expect(source, contains('SliverList.builder('));
    expect(source, contains('cacheExtent: 600'));
    expect(source, contains('cacheWidth: cacheWidth'));
    expect(
      source,
      isNot(contains('...result.products.asMap().entries.map(')),
    );
    expect(
      source,
      isNot(contains('...result.restaurants.asMap().entries.map(')),
    );
  });
}
