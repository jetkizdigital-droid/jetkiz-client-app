import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';

class RestaurantReviewsApi {
  RestaurantReviewsApi(this.apiClient);

  final ApiClient apiClient;

  Future<RestaurantReviewPageData> getRestaurantReviews(
    String restaurantId, {
    int page = 1,
    int limit = 20,
    bool includeUser = true,
    bool includeOrder = false,
    String? from,
    String? to,
  }) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/restaurants/$restaurantId/reviews',
      queryParameters: {
        'page': page,
        'limit': limit,
        'includeUser': includeUser,
        'includeOrder': includeOrder,
        if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
        if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      },
    );

    final json = response.data ?? const <String, dynamic>{};
    return RestaurantReviewPageData.fromJson(json);
  }
}
