import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';

Future<CartAddResult> addItemWithRestaurantConfirmation({
  required BuildContext context,
  required String productId,
  required String restaurantId,
  required String restaurantName,
  required String title,
  required int price,
  required int quantity,
  String? imageUrl,
  String? description,
  String? weight,
}) async {
  final cart = CartRepository.instance;

  CartAddResult add() => cart.addItem(
        productId: productId,
        restaurantId: restaurantId,
        title: title,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        description: description,
        weight: weight,
      );

  final result = add();
  if (result != CartAddResult.rejectedDifferentRestaurant) return result;
  if (!context.mounted) return result;

  final normalizedRestaurantName = restaurantName.trim().isEmpty
      ? 'другого ресторана'
      : '«${restaurantName.trim()}»';
  final replace = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('В корзине другой ресторан'),
      content: Text(
        'В корзине уже есть блюда из другого ресторана. '
        'Очистить корзину и добавить блюда из $normalizedRestaurantName?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Очистить и добавить'),
        ),
      ],
    ),
  );

  if (replace != true) return CartAddResult.rejectedDifferentRestaurant;

  return cart.replaceCartWithItem(
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
