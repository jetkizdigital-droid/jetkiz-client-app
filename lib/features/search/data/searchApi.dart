import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

class SearchApi {
  SearchApi(this.apiClient)
      : _sessionId = 'search-${DateTime.now().microsecondsSinceEpoch}';

  final ApiClient apiClient;
  final String _sessionId;

  static const String _appVersion = '1.0.1';

  Future<SearchResult> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return const SearchResult(
        restaurants: [],
        products: [],
      );
    }

    final deviceId = await apiClient.getDeviceId();

    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'q': trimmed,
        'sessionId': _sessionId,
        'deviceId': deviceId,
        'source': 'search_page',
        'platform': _backendPlatformName(),
        'appVersion': _appVersion,
      },
    );

    final json = response.data ?? const <String, dynamic>{};

    return SearchResult.fromJson(json);
  }

  String _backendPlatformName() {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'WEB';
    }
  }
}
