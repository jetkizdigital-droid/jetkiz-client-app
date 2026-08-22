import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';

import 'cartPersistence.dart';
import 'productSyncApi.dart';
import '../domain/cartItem.dart';
import '../domain/cartState.dart';

enum CartAddResult {
  added,
  updated,
  rejectedDifferentRestaurant,
  rejectedInvalidItem,
}

class CartSyncResult {
  const CartSyncResult({
    required this.priceChanged,
    required this.hasBlockingItems,
    required this.failed,
  });

  const CartSyncResult.empty()
      : priceChanged = false,
        hasBlockingItems = false,
        failed = false;

  const CartSyncResult.failure()
      : priceChanged = false,
        hasBlockingItems = false,
        failed = true;

  final bool priceChanged;
  final bool hasBlockingItems;
  final bool failed;
}

class CartRepository extends ChangeNotifier {
  CartRepository._({
    ProductSyncClient? productSyncClient,
    CartPersistence? persistence,
  })  : _productSyncClient = productSyncClient ?? ProductSyncApi(ApiClient()),
        _persistence = persistence ?? const SharedPreferencesCartPersistence();

  @visibleForTesting
  CartRepository.forTesting({
    required ProductSyncClient productSyncClient,
    required CartPersistence persistence,
  })  : _productSyncClient = productSyncClient,
        _persistence = persistence;

  static final CartRepository instance = CartRepository._();

  final ProductSyncClient _productSyncClient;
  final CartPersistence _persistence;

  CartState _state = CartState.empty();
  Future<CartSyncResult>? _syncFuture;
  Future<void>? _restoreFuture;
  bool _hasPendingPriceUpdateNotification = false;

  CartState get state => _state;

  List<CartItem> get items => List.unmodifiable(_state.items);

  bool get isEmpty => _state.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get subtotal => _state.subtotal;

  int get total => _state.total;

  int get deliveryFee => _state.deliveryFee;

  int get totalQuantity => _state.totalQuantity;

  String? get restaurantId => _state.restaurantId;

  bool get hasRestaurant => restaurantId != null && restaurantId!.isNotEmpty;

  bool get hasBlockingItems => _state.hasBlockingItems;

  CartItem? get firstBlockingItem => _state.firstBlockingItem;

  bool get hasPendingPriceUpdateNotification {
    return _hasPendingPriceUpdateNotification;
  }

  bool consumePendingPriceUpdateNotification() {
    if (!_hasPendingPriceUpdateNotification) return false;

    _hasPendingPriceUpdateNotification = false;
    _persistence.savePendingPriceUpdateNotification(false);
    return true;
  }

  Future<void> restore() {
    _restoreFuture ??= _restoreFromStorage();
    return _restoreFuture!;
  }

  Future<void> _restoreFromStorage() async {
    final restored = await _persistence.load();
    _hasPendingPriceUpdateNotification =
        await _persistence.loadPendingPriceUpdateNotification();

    if (restored == null) {
      if (_hasPendingPriceUpdateNotification) {
        notifyListeners();
      }
      return;
    }

    _state = restored;
    notifyListeners();

    if (!_state.isEmpty) {
      await syncWithServer();
    }
  }

  bool belongsToRestaurant(String nextRestaurantId) {
    final currentRestaurantId = restaurantId?.trim() ?? '';
    final targetRestaurantId = nextRestaurantId.trim();

    if (targetRestaurantId.isEmpty) return false;
    if (currentRestaurantId.isEmpty) return true;

    return currentRestaurantId == targetRestaurantId;
  }

  bool hasDifferentRestaurant(String nextRestaurantId) {
    final currentRestaurantId = restaurantId?.trim() ?? '';
    final targetRestaurantId = nextRestaurantId.trim();

    if (currentRestaurantId.isEmpty || targetRestaurantId.isEmpty) {
      return false;
    }

    return currentRestaurantId != targetRestaurantId;
  }

  CartAddResult addItem({
    required String productId,
    required String restaurantId,
    required String title,
    required int price,
    required int quantity,
    String? imageUrl,
    String? description,
    String? weight,
  }) {
    final normalizedProductId = productId.trim();
    final normalizedRestaurantId = restaurantId.trim();
    final normalizedTitle = title.trim();

    if (normalizedProductId.isEmpty ||
        normalizedRestaurantId.isEmpty ||
        normalizedTitle.isEmpty ||
        price < 0 ||
        quantity <= 0) {
      return CartAddResult.rejectedInvalidItem;
    }

    if (hasDifferentRestaurant(normalizedRestaurantId)) {
      return CartAddResult.rejectedDifferentRestaurant;
    }

    final nextItems = List<CartItem>.from(_state.items);

    final existingIndex = nextItems.indexWhere(
      (item) => item.productId == normalizedProductId,
    );

    if (existingIndex >= 0) {
      final existing = nextItems[existingIndex];

      if (!existing.canOrder) {
        return CartAddResult.rejectedInvalidItem;
      }

      nextItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
        imageUrl: _normalizeOptional(imageUrl) ?? existing.imageUrl,
        description: _normalizeOptional(description) ?? existing.description,
        weight: _normalizeOptional(weight) ?? existing.weight,
      );

      _state = _state.copyWith(items: nextItems);
      _persistState();
      notifyListeners();

      return CartAddResult.updated;
    }

    nextItems.add(
      CartItem(
        productId: normalizedProductId,
        restaurantId: normalizedRestaurantId,
        title: normalizedTitle,
        price: price,
        quantity: quantity,
        imageUrl: _normalizeOptional(imageUrl),
        description: _normalizeOptional(description),
        weight: _normalizeOptional(weight),
      ),
    );

    _state = _state.copyWith(items: nextItems);
    _persistState();
    notifyListeners();

    return CartAddResult.added;
  }

  CartAddResult replaceCartWithItem({
    required String productId,
    required String restaurantId,
    required String title,
    required int price,
    required int quantity,
    String? imageUrl,
    String? description,
    String? weight,
  }) {
    clear();

    return addItem(
      productId: productId,
      restaurantId: restaurantId,
      title: title,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      description: description,
      weight: weight,
    );
  }

  void increment(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return;

    final nextItems = _state.items.map((item) {
      if (item.productId != normalizedProductId) return item;

      if (!item.canOrder) return item;

      return item.copyWith(quantity: item.quantity + 1);
    }).toList();

    _state = _state.copyWith(items: nextItems);
    _persistState();
    notifyListeners();
  }

  void decrement(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return;

    final nextItems = _state.items
        .map((item) {
          if (item.productId != normalizedProductId) return item;

          return item.copyWith(quantity: item.quantity - 1);
        })
        .where((item) => item.quantity > 0)
        .toList();

    _state = _state.copyWith(items: nextItems);
    _persistState();
    notifyListeners();
  }

  void remove(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return;

    final nextItems = _state.items
        .where((item) => item.productId != normalizedProductId)
        .toList();

    _state = _state.copyWith(items: nextItems);
    _persistState();
    notifyListeners();
  }

  Future<CartSyncResult> syncWithServer() {
    if (_state.isEmpty) {
      return Future<CartSyncResult>.value(const CartSyncResult.empty());
    }

    final current = _syncFuture;
    if (current != null) return current;

    _syncFuture = _performSync();

    return _syncFuture!.whenComplete(() {
      _syncFuture = null;
    });
  }

  Future<CartSyncResult> _performSync() async {
    final productIds = _dedupeProductIds(
      _state.items.map((item) => item.productId),
    );
    final requestedProductIds = productIds.toSet();

    if (productIds.isEmpty) {
      return const CartSyncResult.empty();
    }

    final responseItems = await _safeSyncProducts(productIds);
    if (responseItems == null) {
      return const CartSyncResult.failure();
    }

    final byId = <String, ProductSyncItem>{};
    for (final item in responseItems) {
      final id = item.id.trim();
      if (id.isEmpty) continue;
      byId[id] = item;
    }

    var priceChanged = false;
    var stateChanged = false;

    final nextItems = _state.items.map((item) {
      if (!requestedProductIds.contains(item.productId)) {
        return item;
      }

      final synced = byId[item.productId];
      final next = _reconcileItem(item, synced);

      if (next.price != item.price) {
        priceChanged = true;
      }

      if (!_cartItemsEquivalent(item, next)) {
        stateChanged = true;
      }

      return next;
    }).toList();

    final nextState = _state.copyWith(items: nextItems);
    final result = CartSyncResult(
      priceChanged: priceChanged,
      hasBlockingItems: nextState.hasBlockingItems,
      failed: false,
    );

    if (stateChanged) {
      _state = nextState;
      await _persistence.save(_state);

      if (priceChanged) {
        _hasPendingPriceUpdateNotification = true;
        await _persistence.savePendingPriceUpdateNotification(true);
      }

      notifyListeners();
    }

    return result;
  }

  Future<List<ProductSyncItem>?> _safeSyncProducts(
      List<String> productIds) async {
    try {
      return await _productSyncClient.syncProducts(productIds);
    } catch (_) {
      return null;
    }
  }

  CartItem _reconcileItem(CartItem item, ProductSyncItem? synced) {
    if (synced == null) {
      return item.copyWith(
        syncState: CartItemSyncState.unavailable,
        restaurantStatus: 'CLOSED',
        restaurantIsInApp: false,
        restaurantIsAcceptingOrders: false,
      );
    }

    if (!synced.exists || synced.state == ProductSyncState.notFound) {
      return item.copyWith(syncState: CartItemSyncState.notFound);
    }

    final restaurant = synced.restaurant;
    final responseRestaurantId =
        synced.restaurantId?.trim() ?? restaurant?.id.trim() ?? '';
    final resolvedRestaurantId =
        responseRestaurantId.isEmpty ? item.restaurantId : responseRestaurantId;
    final title = _firstNonEmpty([synced.titleRu, synced.titleKk, item.title]);
    final imageUrl = _firstNonEmpty([synced.effectiveImageUrl, item.imageUrl]);
    final price = synced.price ?? item.price;

    final hasConfirmedRestaurant = restaurant != null &&
        restaurant.id.trim().isNotEmpty &&
        resolvedRestaurantId == item.restaurantId;

    final productAvailable = hasConfirmedRestaurant &&
        synced.state == ProductSyncState.ok &&
        synced.isAvailable;

    return item.copyWith(
      title: title,
      price: price < 0 ? item.price : price,
      imageUrl: imageUrl,
      syncState: productAvailable
          ? CartItemSyncState.ok
          : CartItemSyncState.unavailable,
      restaurantStatus: restaurant?.status ?? 'CLOSED',
      restaurantIsInApp: restaurant?.isInApp ?? false,
      restaurantIsAcceptingOrders: restaurant?.isAcceptingOrders ?? false,
    );
  }

  int quantityOf(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return 0;

    for (final item in _state.items) {
      if (item.productId == normalizedProductId) {
        return item.quantity;
      }
    }

    return 0;
  }

  CartItem? itemOf(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return null;

    for (final item in _state.items) {
      if (item.productId == normalizedProductId) {
        return item;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> toOrderItemsJson() {
    if (_state.hasBlockingItems) {
      throw StateError(
        'Cart contains items that cannot be ordered. Sync and resolve cart before creating an order payload.',
      );
    }

    return _state.items
        .where((item) => item.productId.trim().isNotEmpty)
        .where((item) => item.quantity > 0)
        .map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
      };
    }).toList();
  }

  void clear() {
    _state = CartState.empty();
    _hasPendingPriceUpdateNotification = false;
    _persistence.clear();
    notifyListeners();
  }

  void _persistState() {
    if (_state.isEmpty) {
      _persistence.clear();
      return;
    }

    _persistence.save(_state);
  }

  static List<String> _dedupeProductIds(Iterable<String> productIds) {
    final seen = <String>{};
    final result = <String>[];

    for (final raw in productIds) {
      final id = raw.trim();
      if (id.isEmpty || seen.contains(id)) continue;

      seen.add(id);
      result.add(id);
    }

    return result;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }

    return '';
  }

  static bool _cartItemsEquivalent(CartItem left, CartItem right) {
    return left.productId == right.productId &&
        left.restaurantId == right.restaurantId &&
        left.title == right.title &&
        left.price == right.price &&
        left.quantity == right.quantity &&
        left.imageUrl == right.imageUrl &&
        left.description == right.description &&
        left.weight == right.weight &&
        left.syncState == right.syncState &&
        left.restaurantStatus == right.restaurantStatus &&
        left.restaurantIsInApp == right.restaurantIsInApp &&
        left.restaurantIsAcceptingOrders == right.restaurantIsAcceptingOrders;
  }

  static String? _normalizeOptional(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}
