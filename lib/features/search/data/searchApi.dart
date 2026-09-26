import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/config/appBuildInfo.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

class SearchApi {
  SearchApi(this.apiClient)
      : _sessionId = 'search-${DateTime.now().microsecondsSinceEpoch}';

  final ApiClient apiClient;
  final String _sessionId;

  static String get appVersion => AppBuildInfo.fullVersion;

  String get sessionId => _sessionId;

  Future<SearchResult> search(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
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
        'page': page,
        'limit': limit,
        'sessionId': _sessionId,
        'deviceId': deviceId,
        'source': 'search_page',
        'platform': _backendPlatformName(),
        'appVersion': appVersion,
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
