import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';

/// Restaurant menu API layer.
///
/// Backend public endpoint:
/// - GET /restaurants/:id/menu
///
/// Expected response:
/// {
///   "restaurant": { ... },
///   "categories": [ ... ],
///   "items": [ ... ],
///   "products": [ ... ] // optional/duplicate
/// }
///
/// Do not call Dio directly from presentation.
class RestaurantMenuApi {
  RestaurantMenuApi(this._apiClient);

  final ApiClient _apiClient;

  Future<RestaurantMenuData> getRestaurantMenu({
    required String restaurantId,
  }) async {
    final id = restaurantId.trim();

    if (id.isEmpty) {
      throw ArgumentError('restaurantId is required');
    }

    final response = await _apiClient.dio.get(
      '/restaurants/$id/menu',
    );

    final data = _asMap(response.data);

    return RestaurantMenuData.fromJson(data);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Invalid restaurant menu response');
  }
}