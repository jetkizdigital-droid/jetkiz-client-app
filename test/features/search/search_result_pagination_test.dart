import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

void main() {
  test('parses pagination metadata and appends unique product pages', () {
    final first = SearchResult.fromJson({
      'restaurants': [
        {
          'id': 'r1',
          'name': 'Restaurant',
          'ratingAvg': 4.8,
        },
      ],
      'products': [
        {
          'id': 'p1',
          'titleRu': 'Первый',
          'price': 1000,
          'restaurantId': 'r1',
          'restaurantName': 'Restaurant',
        },
      ],
      'meta': {
        'searchQueryLogId': 'log-1',
        'page': 1,
        'limit': 20,
        'hasMore': true,
      },
    });

    final second = SearchResult.fromJson({
      'restaurants': <Object>[],
      'products': [
        {
          'id': 'p1',
          'titleRu': 'Первый',
          'price': 1000,
          'restaurantId': 'r1',
          'restaurantName': 'Restaurant',
        },
        {
          'id': 'p2',
          'titleRu': 'Второй',
          'price': 2000,
          'restaurantId': 'r1',
          'restaurantName': 'Restaurant',
        },
      ],
      'meta': {
        'page': 2,
        'limit': 20,
        'hasMore': false,
      },
    });

    final merged = first.append(second);

    expect(merged.restaurants.map((item) => item.id), ['r1']);
    expect(merged.products.map((item) => item.id), ['p1', 'p2']);
    expect(merged.searchQueryLogId, 'log-1');
    expect(merged.page, 2);
    expect(merged.limit, 20);
    expect(merged.hasMore, isFalse);
  });

  test('keeps backward-compatible pagination defaults', () {
    final result = SearchResult.fromJson({
      'restaurants': <Object>[],
      'products': <Object>[],
      'meta': <String, Object?>{},
    });

    expect(result.page, 1);
    expect(result.limit, 20);
    expect(result.hasMore, isFalse);
  });
}
