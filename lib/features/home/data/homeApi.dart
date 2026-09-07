/// Jetkiz mobile
/// Home API layer.
/// Uses only ApiClient.
/// Endpoints:
/// - GET /home-cms/public
/// - GET /restaurants/public/list
///
/// Notes for future GPT:
/// - home screen is backend-first
/// - pinned restaurants are loaded separately from restaurants/public/list
/// - categories may contain empty products[] and UI must handle that safely
library;

import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/home/domain/homeData.dart';

class HomeApi {
  final ApiClient apiClient;

  const HomeApi(this.apiClient);

  Future<HomeData> getHomeData() async {
    // CMS and restaurant availability are independent requests. Run them in
    // parallel so the home screen is not blocked by their combined latency.
    final responses = await Future.wait([
      apiClient.dio.get<Map<String, dynamic>>('/home-cms/public'),
      apiClient.dio.get<Map<String, dynamic>>('/restaurants/public/list'),
    ]);

    final homeResponse = responses[0];
    final restaurantsResponse = responses[1];

    final homeJson = homeResponse.data ?? const <String, dynamic>{};
    final restaurantsJson =
        restaurantsResponse.data ?? const <String, dynamic>{};

    final promoJson = homeJson['promo'];
    final rawCategories = (homeJson['categories'] as List?) ?? const [];

    return HomeData(
      promo: promoJson is Map<String, dynamic>
          ? HomePromo.fromJson(promoJson)
          : null,
      categories: rawCategories
          .whereType<Map<String, dynamic>>()
          .map(HomeCategoryData.fromJson)
          .toList(),
      pinnedRestaurants: _parsePinnedRestaurants(restaurantsJson),
    );
  }

  List<HomeRestaurantData> _parsePinnedRestaurants(
    Map<String, dynamic> restaurantsJson,
  ) {
    final rawPinned = (restaurantsJson['pinned'] as List?) ?? const [];
    return rawPinned
        .whereType<Map<String, dynamic>>()
        .map(HomeRestaurantData.fromJson)
        .toList();
  }
}
