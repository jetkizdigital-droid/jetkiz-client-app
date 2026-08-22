import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesApi.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController._() : _api = FavoritesApi(ApiClient());

  @visibleForTesting
  FavoritesController.forTesting(this._api);

  static final FavoritesController instance = FavoritesController._();

  final FavoritesApi _api;

  final Set<String> _restaurantIds = <String>{};
  final Set<String> _productIds = <String>{};
  final Set<String> _busyRestaurantIds = <String>{};
  final Set<String> _busyProductIds = <String>{};

  List<FavoriteRestaurantRecord> _restaurants = const [];
  List<FavoriteProductRecord> _products = const [];

  bool _idsLoaded = false;
  bool _restaurantsLoaded = false;
  bool _productsLoaded = false;
  bool _isInitializing = false;
  bool _isRestaurantsLoading = false;
  bool _isProductsLoading = false;
  String? _restaurantError;
  String? _productError;
  DateTime? _lastUpdated;

  Set<String> get restaurantIds => Set.unmodifiable(_restaurantIds);
  Set<String> get productIds => Set.unmodifiable(_productIds);
  Set<String> get busyRestaurantIds => Set.unmodifiable(_busyRestaurantIds);
  Set<String> get busyProductIds => Set.unmodifiable(_busyProductIds);
  List<FavoriteRestaurantRecord> get restaurants =>
      List.unmodifiable(_restaurants);
  List<FavoriteProductRecord> get products => List.unmodifiable(_products);

  bool get idsLoaded => _idsLoaded;
  bool get restaurantsLoaded => _restaurantsLoaded;
  bool get productsLoaded => _productsLoaded;
  bool get isInitializing => _isInitializing;
  bool get isRestaurantsLoading => _isRestaurantsLoading;
  bool get isProductsLoading => _isProductsLoading;
  String? get restaurantError => _restaurantError;
  String? get productError => _productError;
  DateTime? get lastUpdated => _lastUpdated;

  bool get isStale {
    final updated = _lastUpdated;
    if (updated == null) return true;
    return DateTime.now().difference(updated) > const Duration(minutes: 2);
  }

  bool isRestaurantFavorite(String id) => _restaurantIds.contains(id);
  bool isProductFavorite(String id) => _productIds.contains(id);
  bool isRestaurantBusy(String id) => _busyRestaurantIds.contains(id);
  bool isProductBusy(String id) => _busyProductIds.contains(id);

  Future<void> initialize() async {
    if (_idsLoaded || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      final ids = await _api.getFavoriteIds();
      _restaurantIds
        ..clear()
        ..addAll(ids.restaurantIds);
      _productIds
        ..clear()
        ..addAll(ids.productIds);
      _idsLoaded = true;
      _lastUpdated = DateTime.now();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshIfStale() async {
    if (!isStale) return;
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshRestaurants(),
      refreshProducts(),
    ]);
  }

  Future<void> refreshRestaurants() async {
    if (_isRestaurantsLoading) return;

    _isRestaurantsLoading = true;
    _restaurantError = null;
    notifyListeners();

    try {
      final response = await _api.getFavoriteRestaurants();
      final reconciled = _reconcileRestaurantRefresh(response.items);
      _restaurants = reconciled;
      _restaurantIds
        ..clear()
        ..addAll(reconciled.map((item) => item.restaurant.id));
      _restaurantsLoaded = true;
      _idsLoaded = true;
      _lastUpdated = DateTime.now();
    } on DioException catch (error) {
      _restaurantError = _api.extractMessage(error);
    } catch (_) {
      _restaurantError = 'Не удалось загрузить избранные рестораны';
    } finally {
      _isRestaurantsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    if (_isProductsLoading) return;

    _isProductsLoading = true;
    _productError = null;
    notifyListeners();

    try {
      final response = await _api.getFavoriteProducts();
      final reconciled = _reconcileProductRefresh(response.items);
      _products = reconciled;
      _productIds
        ..clear()
        ..addAll(reconciled.map((item) => item.product.id));
      _productsLoaded = true;
      _idsLoaded = true;
      _lastUpdated = DateTime.now();
    } on DioException catch (error) {
      _productError = _api.extractMessage(error);
    } catch (_) {
      _productError = 'Не удалось загрузить избранные блюда';
    } finally {
      _isProductsLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRestaurant(String id) async {
    if (_busyRestaurantIds.contains(id)) return;

    if (_restaurantIds.contains(id)) {
      await removeRestaurant(id);
    } else {
      await _addRestaurant(id);
    }
  }

  Future<void> toggleProduct(String id) async {
    if (_busyProductIds.contains(id)) return;

    if (_productIds.contains(id)) {
      await removeProduct(id);
    } else {
      await _addProduct(id);
    }
  }

  Future<void> _addRestaurant(String id) async {
    _busyRestaurantIds.add(id);
    _restaurantIds.add(id);
    notifyListeners();

    try {
      await _api.addRestaurantFavorite(id);
      await refreshRestaurants();
    } catch (_) {
      _restaurantIds.remove(id);
      rethrow;
    } finally {
      _busyRestaurantIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> _addProduct(String id) async {
    _busyProductIds.add(id);
    _productIds.add(id);
    notifyListeners();

    try {
      await _api.addProductFavorite(id);
      await refreshProducts();
    } catch (_) {
      _productIds.remove(id);
      rethrow;
    } finally {
      _busyProductIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> removeRestaurant(String id) async {
    if (_busyRestaurantIds.contains(id)) return;

    final previousIds = Set<String>.from(_restaurantIds);
    final previousRestaurants =
        List<FavoriteRestaurantRecord>.from(_restaurants);

    _busyRestaurantIds.add(id);
    _restaurantIds.remove(id);
    _restaurants =
        _restaurants.where((item) => item.restaurant.id != id).toList();
    notifyListeners();

    try {
      await _api.removeRestaurantFavorite(id);
    } catch (_) {
      _restaurantIds
        ..clear()
        ..addAll(previousIds);
      _restaurants = previousRestaurants;
      rethrow;
    } finally {
      _busyRestaurantIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> removeProduct(String id) async {
    if (_busyProductIds.contains(id)) return;

    final previousIds = Set<String>.from(_productIds);
    final previousProducts = List<FavoriteProductRecord>.from(_products);

    _busyProductIds.add(id);
    _productIds.remove(id);
    _products = _products.where((item) => item.product.id != id).toList();
    notifyListeners();

    try {
      await _api.removeProductFavorite(id);
    } catch (_) {
      _productIds
        ..clear()
        ..addAll(previousIds);
      _products = previousProducts;
      rethrow;
    } finally {
      _busyProductIds.remove(id);
      notifyListeners();
    }
  }

  List<FavoriteRestaurantRecord> _reconcileRestaurantRefresh(
    List<FavoriteRestaurantRecord> refreshed,
  ) {
    if (_busyRestaurantIds.isEmpty) return refreshed;

    final localIds = Set<String>.from(_restaurantIds);
    final localById = {
      for (final item in _restaurants) item.restaurant.id: item,
    };

    final next = refreshed.where((item) {
      final id = item.restaurant.id;
      return !_busyRestaurantIds.contains(id) || localIds.contains(id);
    }).toList();
    final nextIds = next.map((item) => item.restaurant.id).toSet();

    for (final id in _busyRestaurantIds) {
      if (!localIds.contains(id)) {
        next.removeWhere((item) => item.restaurant.id == id);
        nextIds.remove(id);
        continue;
      }

      if (nextIds.contains(id)) continue;
      final localItem = localById[id];
      if (localItem != null) {
        next.add(localItem);
        nextIds.add(id);
      }
    }

    return next;
  }

  List<FavoriteProductRecord> _reconcileProductRefresh(
    List<FavoriteProductRecord> refreshed,
  ) {
    if (_busyProductIds.isEmpty) return refreshed;

    final localIds = Set<String>.from(_productIds);
    final localById = {
      for (final item in _products) item.product.id: item,
    };

    final next = refreshed.where((item) {
      final id = item.product.id;
      return !_busyProductIds.contains(id) || localIds.contains(id);
    }).toList();
    final nextIds = next.map((item) => item.product.id).toSet();

    for (final id in _busyProductIds) {
      if (!localIds.contains(id)) {
        next.removeWhere((item) => item.product.id == id);
        nextIds.remove(id);
        continue;
      }

      if (nextIds.contains(id)) continue;
      final localItem = localById[id];
      if (localItem != null) {
        next.add(localItem);
        nextIds.add(id);
      }
    }

    return next;
  }
}
