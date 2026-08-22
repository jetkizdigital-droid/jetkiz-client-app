import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

class SearchApi {
  final ApiClient apiClient;

  const SearchApi(this.apiClient);

  Future<SearchResult> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return const SearchResult(
        restaurants: [],
        products: [],
      );
    }

    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'q': trimmed,
      },
    );

    final json = response.data ?? const <String, dynamic>{};

    return SearchResult.fromJson(json);
  }
}
