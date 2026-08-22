import 'cartItem.dart';

/// Aggregated cart state for the client app.
/// Delivery fee is loaded from backend pricing screens,
/// so the empty cart keeps it at zero by default.
class CartState {
  const CartState({
    required this.items,
    required this.deliveryFee,
  });

  final List<CartItem> items;
  final int deliveryFee;

  bool get isEmpty => items.isEmpty;

  bool get hasBlockingItems => items.any((item) => !item.canOrder);

  CartItem? get firstBlockingItem {
    for (final item in items) {
      if (!item.canOrder) return item;
    }

    return null;
  }

  int get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get total => subtotal + deliveryFee;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  String? get restaurantId => items.isEmpty ? null : items.first.restaurantId;

  CartState copyWith({
    List<CartItem>? items,
    int? deliveryFee,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  factory CartState.empty() {
    return const CartState(
      items: [],
      deliveryFee: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryFee': deliveryFee,
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
            .where((item) {
            return item.productId.trim().isNotEmpty &&
                item.restaurantId.trim().isNotEmpty &&
                item.quantity > 0;
          }).toList()
        : <CartItem>[];

    return CartState(
      items: items,
      deliveryFee: _readInt(json['deliveryFee']),
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return 0;

  return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
}
