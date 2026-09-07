import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

void main() {
  group('SearchResult analytics metadata', () {
    test('preserves canonical searchQueryLogId from response meta', () {
      final result = SearchResult.fromJson({
        'restaurants': const [],
        'products': const [],
        'meta': {
          'query': 'плов',
          'normalizedQuery': 'плов',
          'resultsCount': 0,
          'searchQueryLogId': 'search-log-123',
        },
      });

      expect(result.searchQueryLogId, 'search-log-123');
    });

    test('keeps searchQueryLogId null when backend did not provide one', () {
      final result = SearchResult.fromJson({
        'restaurants': const [],
        'products': const [],
        'meta': {
          'query': 'плов',
          'normalizedQuery': 'плов',
          'resultsCount': 0,
          'searchQueryLogId': null,
        },
      });

      expect(result.searchQueryLogId, isNull);
    });
  });
}
