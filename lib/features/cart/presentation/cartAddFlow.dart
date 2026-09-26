import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';

Future<CartAddResult> addItemWithRestaurantConfirmation({
  required BuildContext context,
  required String productId,
  required String restaurantId,
  required String restaurantName,
  required String title,
  String? titleRu,
  String? titleKk,
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
        titleRu: titleRu,
        titleKk: titleKk,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        description: description,
        weight: weight,
      );

  final result = add();
  if (result != CartAddResult.rejectedDifferentRestaurant) return result;
  if (!context.mounted) return result;

  final restaurantLabel = restaurantName.trim();
  final language = AppLocalizationScope.of(context).language;
  final confirmationMessage = language == AppLanguage.kk
      ? restaurantLabel.isEmpty
          ? 'Себетте басқа мейрамхананың тағамдары бар. Себетті тазалап, басқа мейрамхананың тағамдарын қосу керек пе?'
          : 'Себетте басқа мейрамхананың тағамдары бар. Себетті тазалап, «$restaurantLabel» мейрамханасының тағамдарын қосу керек пе?'
      : restaurantLabel.isEmpty
          ? 'В корзине уже есть блюда из другого ресторана. Очистить корзину и добавить блюда из другого ресторана?'
          : 'В корзине уже есть блюда из другого ресторана. Очистить корзину и добавить блюда из «$restaurantLabel»?';
  final replace = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const LocalizedText('В корзине другой ресторан'),
      content: Text(confirmationMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const LocalizedText('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const LocalizedText('Очистить и добавить'),
        ),
      ],
    ),
  );

  if (replace != true) return CartAddResult.rejectedDifferentRestaurant;

  return cart.replaceCartWithItem(
    productId: productId,
    restaurantId: restaurantId,
    title: title,
    titleRu: titleRu,
    titleKk: titleKk,
    price: price,
    quantity: quantity,
    imageUrl: imageUrl,
    description: description,
    weight: weight,
  );
}
