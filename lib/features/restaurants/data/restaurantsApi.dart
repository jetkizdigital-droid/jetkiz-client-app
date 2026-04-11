/*
  Restaurants API for Jetkiz mobile.

  Контекст для будущих сессий ChatGPT:
  - Использует реальный backend endpoint:
      GET /restaurants/public/list
  - Этот endpoint предназначен именно для клиентского приложения.
  - Не использовать GET /restaurants для мобильного клиента,
    потому что это admin list.
  - Ответ backend:
      {
        "pinned": [ ... ],
        "items": [ ... ]
      }
  - На главный экран сейчас загружаем pinned + items по их назначению.
  - Для отдельной страницы всех ресторанов использовать items.
  - pinned сохранён для отдельного блока "Популярное / Закреплённое".
*/

import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurant.dart';

class RestaurantsApi {
  RestaurantsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<RestaurantsResponse> getPublicRestaurants() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/restaurants/public/list',
    );

    final data = response.data ?? const <String, dynamic>{};

    final pinnedJson = _extractList(data, const ['pinned']) ?? const [];
    final itemsJson = _extractList(data, const ['items']) ?? const [];

    final pinned = pinnedJson
        .whereType<Map>()
        .map((item) => Restaurant.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final items = itemsJson
        .whereType<Map>()
        .map((item) => Restaurant.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return RestaurantsResponse(
      pinned: pinned,
      items: items,
    );
  }

  Future<List<Restaurant>> getAllPublicRestaurants() async {
    final result = await getPublicRestaurants();
    return result.items;
  }

  List<dynamic>? _extractList(
    Map<String, dynamic> json,
    List<String> path,
  ) {
    dynamic current = json;

    for (final part in path) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current is List ? current : null;
  }
}

class RestaurantsResponse {
  const RestaurantsResponse({
    required this.pinned,
    required this.items,
  });

  final List<Restaurant> pinned;
  final List<Restaurant> items;

  bool get isEmpty => pinned.isEmpty && items.isEmpty;
}