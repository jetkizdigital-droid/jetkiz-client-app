import 'package:flutter/foundation.dart';

import '../domain/cartItem.dart';
import '../domain/cartState.dart';

enum CartAddResult {
  added,
  updated,
  rejectedDifferentRestaurant,
  rejectedInvalidItem,
}

class CartRepository extends ChangeNotifier {
  CartRepository._();

  static final CartRepository instance = CartRepository._();

  CartState _state = CartState.empty();

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

      nextItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );

      _state = _state.copyWith(items: nextItems);
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

      return item.copyWith(quantity: item.quantity + 1);
    }).toList();

    _state = _state.copyWith(items: nextItems);
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
    notifyListeners();
  }

  void remove(String productId) {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) return;

    final nextItems = _state.items
        .where((item) => item.productId != normalizedProductId)
        .toList();

    _state = _state.copyWith(items: nextItems);
    notifyListeners();
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
    notifyListeners();
  }

  static String? _normalizeOptional(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}