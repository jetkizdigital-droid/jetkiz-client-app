import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';

class FavoritesApi {
  final ApiClient apiClient;

  const FavoritesApi(this.apiClient);

  Future<FavoriteIdsResponse> getFavoriteIds() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/favorites/ids',
    );

    final json = response.data ?? const <String, dynamic>{};
    return FavoriteIdsResponse.fromJson(json);
  }

  Future<FavoriteRestaurantsResponse> getFavoriteRestaurants() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/favorites/restaurants',
    );

    final json = response.data ?? const <String, dynamic>{};
    return FavoriteRestaurantsResponse.fromJson(json);
  }

  Future<FavoriteProductsResponse> getFavoriteProducts() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/favorites/products',
    );

    final json = response.data ?? const <String, dynamic>{};
    return FavoriteProductsResponse.fromJson(json);
  }

  Future<FavoriteAllResponse> getAllFavorites() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/favorites',
    );

    final json = response.data ?? const <String, dynamic>{};
    return FavoriteAllResponse.fromJson(json);
  }

  Future<void> addRestaurantFavorite(String restaurantId) async {
    await apiClient.dio.post<void>(
      '/favorites/restaurants/$restaurantId',
    );
  }

  Future<void> removeRestaurantFavorite(String restaurantId) async {
    await apiClient.dio.delete<void>(
      '/favorites/restaurants/$restaurantId',
    );
  }

  Future<void> addProductFavorite(String productId) async {
    await apiClient.dio.post<void>(
      '/favorites/products/$productId',
    );
  }

  Future<void> removeProductFavorite(String productId) async {
    await apiClient.dio.delete<void>(
      '/favorites/products/$productId',
    );
  }

  Future<bool> isRestaurantFavorite(String restaurantId) async {
    final ids = await getFavoriteIds();
    return ids.restaurantIds.contains(restaurantId);
  }

  Future<bool> isProductFavorite(String productId) async {
    final ids = await getFavoriteIds();
    return ids.productIds.contains(productId);
  }

  Future<void> toggleRestaurantFavorite({
    required String restaurantId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await removeRestaurantFavorite(restaurantId);
    } else {
      await addRestaurantFavorite(restaurantId);
    }
  }

  Future<void> toggleProductFavorite({
    required String productId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await removeProductFavorite(productId);
    } else {
      await addProductFavorite(productId);
    }
  }

  String extractMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }

      final errorText = data['error'];
      if (errorText is String && errorText.trim().isNotEmpty) {
        return errorText.trim();
      }
    }

    return error.message ?? 'Не удалось выполнить запрос';
  }
}
