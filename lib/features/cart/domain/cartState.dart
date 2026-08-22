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
}
