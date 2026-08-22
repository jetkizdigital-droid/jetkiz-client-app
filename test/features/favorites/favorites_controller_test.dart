import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesApi.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';

void main() {
  group('FavoritesController', () {
    test('removeProduct success leaves product removed', () async {
      final api = _FakeFavoritesApi()
        ..productsResponse = _productsResponse(['p1']);
      final controller = FavoritesController.forTesting(api);

      await controller.refreshProducts();
      await controller.removeProduct('p1');

      expect(controller.isProductFavorite('p1'), isFalse);
      expect(controller.products, isEmpty);
      expect(api.removeProductCalls, 1);
    });

    test('removeProduct failure rolls back product ids and records', () async {
      final api = _FakeFavoritesApi()
        ..productsResponse = _productsResponse(['p1'])
        ..removeProductError = Exception('delete failed');
      final controller = FavoritesController.forTesting(api);

      await controller.refreshProducts();

      await expectLater(
        controller.removeProduct('p1'),
        throwsA(isA<Exception>()),
      );

      expect(controller.isProductFavorite('p1'), isTrue);
      expect(controller.products.map((item) => item.product.id), ['p1']);
    });

    test('removeRestaurant success leaves restaurant removed', () async {
      final api = _FakeFavoritesApi()
        ..restaurantsResponse = _restaurantsResponse(['r1']);
      final controller = FavoritesController.forTesting(api);

      await controller.refreshRestaurants();
      await controller.removeRestaurant('r1');

      expect(controller.isRestaurantFavorite('r1'), isFalse);
      expect(controller.restaurants, isEmpty);
      expect(api.removeRestaurantCalls, 1);
    });

    test('removeRestaurant failure rolls back restaurant ids and records',
        () async {
      final api = _FakeFavoritesApi()
        ..restaurantsResponse = _restaurantsResponse(['r1'])
        ..removeRestaurantError = Exception('delete failed');
      final controller = FavoritesController.forTesting(api);

      await controller.refreshRestaurants();

      await expectLater(
        controller.removeRestaurant('r1'),
        throwsA(isA<Exception>()),
      );

      expect(controller.isRestaurantFavorite('r1'), isTrue);
      expect(controller.restaurants.map((item) => item.restaurant.id), ['r1']);
    });

    test('double toggle is protected while product id is busy', () async {
      final completer = Completer<void>();
      final api = _FakeFavoritesApi()..addProductCompleter = completer;
      final controller = FavoritesController.forTesting(api);

      final firstToggle = controller.toggleProduct('p1');
      await Future<void>.delayed(Duration.zero);
      await controller.toggleProduct('p1');

      expect(api.addProductCalls, 1);
      expect(controller.isProductBusy('p1'), isTrue);

      completer.complete();
      await firstToggle;

      expect(controller.isProductBusy('p1'), isFalse);
    });

    test('refresh during busy product remove does not overwrite local state',
        () async {
      final completer = Completer<void>();
      final api = _FakeFavoritesApi()
        ..productsResponse = _productsResponse(['p1'])
        ..removeProductCompleter = completer;
      final controller = FavoritesController.forTesting(api);

      await controller.refreshProducts();

      final remove = controller.removeProduct('p1');
      await Future<void>.delayed(Duration.zero);

      api.productsResponse = _productsResponse(['p1']);
      await controller.refreshProducts();

      expect(controller.isProductFavorite('p1'), isFalse);
      expect(controller.products, isEmpty);

      completer.complete();
      await remove;

      expect(controller.isProductFavorite('p1'), isFalse);
    });
  });
}

class _FakeFavoritesApi extends FavoritesApi {
  _FakeFavoritesApi() : super(ApiClient());

  FavoriteRestaurantsResponse restaurantsResponse = _restaurantsResponse([]);
  FavoriteProductsResponse productsResponse = _productsResponse([]);

  Object? removeRestaurantError;
  Object? removeProductError;
  Completer<void>? addProductCompleter;
  Completer<void>? removeProductCompleter;

  int addProductCalls = 0;
  int removeRestaurantCalls = 0;
  int removeProductCalls = 0;

  @override
  Future<FavoriteIdsResponse> getFavoriteIds() async {
    return FavoriteIdsResponse(
      restaurantIds:
          restaurantsResponse.items.map((item) => item.restaurant.id).toList(),
      productIds:
          productsResponse.items.map((item) => item.product.id).toList(),
    );
  }

  @override
  Future<FavoriteRestaurantsResponse> getFavoriteRestaurants() async {
    return restaurantsResponse;
  }

  @override
  Future<FavoriteProductsResponse> getFavoriteProducts() async {
    return productsResponse;
  }

  @override
  Future<void> addProductFavorite(String productId) async {
    addProductCalls++;
    await addProductCompleter?.future;
    productsResponse = _productsResponse([productId]);
  }

  @override
  Future<void> removeRestaurantFavorite(String restaurantId) async {
    removeRestaurantCalls++;
    if (removeRestaurantError != null) throw removeRestaurantError!;
    restaurantsResponse = _restaurantsResponse(
      restaurantsResponse.items
          .map((item) => item.restaurant.id)
          .where((id) => id != restaurantId),
    );
  }

  @override
  Future<void> removeProductFavorite(String productId) async {
    removeProductCalls++;
    await removeProductCompleter?.future;
    if (removeProductError != null) throw removeProductError!;
    productsResponse = _productsResponse(
      productsResponse.items
          .map((item) => item.product.id)
          .where((id) => id != productId),
    );
  }
}

FavoriteRestaurantsResponse _restaurantsResponse(Iterable<String> ids) {
  final items = ids.map(_restaurantRecord).toList();
  return FavoriteRestaurantsResponse(
    items: items,
    meta: FavoriteMeta(total: items.length),
  );
}

FavoriteProductsResponse _productsResponse(Iterable<String> ids) {
  final items = ids.map(_productRecord).toList();
  return FavoriteProductsResponse(
    items: items,
    meta: FavoriteMeta(total: items.length),
  );
}

FavoriteRestaurantRecord _restaurantRecord(String id) {
  return FavoriteRestaurantRecord(
    id: 'favorite-$id',
    createdAt: DateTime(2026),
    restaurant: _restaurant(id),
  );
}

FavoriteProductRecord _productRecord(String id) {
  return FavoriteProductRecord(
    id: 'favorite-$id',
    createdAt: DateTime(2026),
    product: FavoriteProduct(
      id: id,
      title: 'Product $id',
      price: 1200,
      isAvailable: true,
      restaurantId: 'r1',
      restaurant: _restaurant('r1'),
    ),
  );
}

FavoriteRestaurant _restaurant(String id) {
  return FavoriteRestaurant(
    id: id,
    name: 'Restaurant $id',
    ratingAvg: 4.8,
    ratingCount: 12,
    status: 'OPEN',
    isInApp: true,
    isAcceptingOrders: true,
  );
}
