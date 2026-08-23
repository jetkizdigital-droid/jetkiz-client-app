import 'package:jetkiz_mobile/core/localization/localizedValue.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurantAvailability.dart';

enum CartItemSyncState {
  ok,
  unavailable,
  notFound,
}

/// Local cart snapshot. Product title keeps both backend languages so changing
/// the app language does not require rebuilding the cart or re-adding items.
class CartItem {
  const CartItem({
    required this.productId,
    required this.restaurantId,
    String? title,
    this.titleRu = '',
    this.titleKk = '',
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.description,
    this.weight,
    this.syncState = CartItemSyncState.ok,
    this.restaurantStatus = 'OPEN',
    this.restaurantIsInApp = true,
    this.restaurantIsAcceptingOrders = true,
  }) : _legacyTitle = title ?? '';

  final String productId;
  final String restaurantId;
  final String titleRu;
  final String titleKk;
  final String _legacyTitle;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? description;
  final String? weight;
  final CartItemSyncState syncState;
  final String restaurantStatus;
  final bool restaurantIsInApp;
  final bool restaurantIsAcceptingOrders;

  String get title => LocalizedValue.select(
        ru: titleRu.isNotEmpty ? titleRu : _legacyTitle,
        kk: titleKk,
        fallback: _legacyTitle.isNotEmpty
            ? _legacyTitle
            : (LocalizedValue.language.name == 'kk' ? 'Тауар' : 'Товар'),
      );

  int get totalPrice => price * quantity;

  bool get exists => syncState != CartItemSyncState.notFound;

  bool get productIsAvailable => syncState == CartItemSyncState.ok;

  RestaurantAvailability get restaurantAvailability {
    return RestaurantAvailability(
      status: restaurantStatus,
      isInApp: restaurantIsInApp,
      isAcceptingOrders: restaurantIsAcceptingOrders,
      // Product sync does not contain a schedule. CartPage performs the
      // authoritative schedule check through the public restaurant endpoint.
      allowMissingWorkingHours: true,
    );
  }

  bool get canOrder {
    return exists && productIsAvailable && restaurantAvailability.canOrder;
  }

  String get blockingReason {
    if (!exists) {
      return 'Больше недоступно';
    }

    if (!productIsAvailable) {
      return 'Недоступно';
    }

    final availability = restaurantAvailability;

    if (!availability.isOpen) {
      return availability.reason;
    }

    if (!availability.isAcceptingOrders) {
      return availability.reason;
    }

    return availability.reason;
  }

  CartItem copyWith({
    String? productId,
    String? restaurantId,
    String? title,
    String? titleRu,
    String? titleKk,
    int? price,
    int? quantity,
    String? imageUrl,
    String? description,
    String? weight,
    CartItemSyncState? syncState,
    String? restaurantStatus,
    bool? restaurantIsInApp,
    bool? restaurantIsAcceptingOrders,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      restaurantId: restaurantId ?? this.restaurantId,
      title: title ?? _legacyTitle,
      titleRu: titleRu ?? this.titleRu,
      titleKk: titleKk ?? this.titleKk,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      syncState: syncState ?? this.syncState,
      restaurantStatus: restaurantStatus ?? this.restaurantStatus,
      restaurantIsInApp: restaurantIsInApp ?? this.restaurantIsInApp,
      restaurantIsAcceptingOrders:
          restaurantIsAcceptingOrders ?? this.restaurantIsAcceptingOrders,
    );
  }

  Map<String, dynamic> toJson() {
    final stableLegacyTitle = titleRu.trim().isNotEmpty ? titleRu : _legacyTitle;
    return {
      'productId': productId,
      'restaurantId': restaurantId,
      'title': stableLegacyTitle,
      'titleRu': titleRu,
      'titleKk': titleKk,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
      'weight': weight,
      'syncState': syncState.name,
      'restaurantStatus': restaurantStatus,
      'restaurantIsInApp': restaurantIsInApp,
      'restaurantIsAcceptingOrders': restaurantIsAcceptingOrders,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final legacyTitle = _readString(json['title'], fallback: 'Товар');
    return CartItem(
      productId: _readString(json['productId']),
      restaurantId: _readString(json['restaurantId']),
      title: legacyTitle,
      titleRu: _readString(json['titleRu'], fallback: legacyTitle),
      titleKk: _readString(json['titleKk']),
      price: _readInt(json['price']),
      quantity: _readInt(json['quantity'], fallback: 1),
      imageUrl: _readNullableString(json['imageUrl']),
      description: _readNullableString(json['description']),
      weight: _readNullableString(json['weight']),
      syncState: _readSyncState(json['syncState']),
      restaurantStatus: _readString(json['restaurantStatus'], fallback: 'OPEN'),
      restaurantIsInApp: _readBool(json['restaurantIsInApp'], fallback: true),
      restaurantIsAcceptingOrders: _readBool(
        json['restaurantIsAcceptingOrders'],
        fallback: true,
      ),
    );
  }
}

CartItemSyncState _readSyncState(dynamic value) {
  final text = value?.toString().trim().toUpperCase() ?? '';

  switch (text) {
    case 'UNAVAILABLE':
      return CartItemSyncState.unavailable;
    case 'NOTFOUND':
    case 'NOT_FOUND':
      return CartItemSyncState.notFound;
    case 'OK':
    default:
      return CartItemSyncState.ok;
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
  return text;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return fallback;

  return int.tryParse(text) ?? double.tryParse(text)?.round() ?? fallback;
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase() ?? '';
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;

  return fallback;
}
