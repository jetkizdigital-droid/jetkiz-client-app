/*
  Restaurants API for Jetkiz mobile.

  Backend public endpoints:
  - GET /restaurants/public/list
      Home page contract:
      {
        "pinned": [ ... ],
        "items": [ ... ]
      }

  - GET /restaurants/public/all
      All restaurants page contract:
      {
        "items": [ ... ]
      }

  Do not use GET /restaurants for mobile client.
  It is an admin/backend management endpoint.
*/

import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurant.dart';

class RestaurantsApi {
  RestaurantsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<RestaurantsResponse> getPublicRestaurants({
    bool random = true,
  }) async {
    final response = await _apiClient.dio.get(
      '/restaurants/public/list',
      queryParameters: {
        if (random) 'random': '1',
      },
    );

    final data = _asMap(response.data);

    return RestaurantsResponse(
      pinned: _parseRestaurants(data['pinned']),
      items: _parseRestaurants(data['items']),
    );
  }

  Future<List<Restaurant>> getAllPublicRestaurants({
    bool random = true,
  }) async {
    final response = await _apiClient.dio.get(
      '/restaurants/public/all',
      queryParameters: {
        if (random) 'random': '1',
      },
    );

    final data = _asMap(response.data);

    return _parseRestaurants(data['items']);
  }

  List<Restaurant> _parseRestaurants(dynamic value) {
    final rawItems = _asList(value);

    return rawItems
        .whereType<Map>()
        .map((item) => Restaurant.fromJson(Map<String, dynamic>.from(item)))
        .where((restaurant) => restaurant.id.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }

    return const [];
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

  List<Restaurant> get combined {
    final byId = <String, Restaurant>{};

    for (final restaurant in pinned) {
      byId[restaurant.id] = restaurant;
    }

    for (final restaurant in items) {
      byId[restaurant.id] = restaurant;
    }

    return byId.values.toList();
  }
}