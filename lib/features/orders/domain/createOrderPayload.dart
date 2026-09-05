import 'package:flutter/foundation.dart';

enum OrderFulfillmentType {
  delivery,
  pickup,
}

extension OrderFulfillmentTypePayload on OrderFulfillmentType {
  String get wireName {
    switch (this) {
      case OrderFulfillmentType.delivery:
        return 'DELIVERY';
      case OrderFulfillmentType.pickup:
        return 'PICKUP';
    }
  }
}

class CreateOrderItemPayload {
  const CreateOrderItemPayload({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  bool get isValid {
    return productId.trim().isNotEmpty && quantity > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId.trim(),
      'quantity': quantity,
    };
  }
}

class CreateOrderPayload {
  const CreateOrderPayload({
    required this.restaurantId,
    required this.fulfillmentType,
    required this.items,
    this.addressId,
    this.phone,
    this.leaveAtDoor = false,
    this.comment,
    this.promoCode,
  });

  final String restaurantId;
  final OrderFulfillmentType fulfillmentType;
  final String? addressId;

  /// Optional.
  /// Backend already has fallback:
  /// body.phone -> address.contactPhone -> currentUser.phone
  final String? phone;

  /// Backend DTO supports optional leaveAtDoor.
  /// Flutter sends false by default for stable behavior.
  final bool leaveAtDoor;

  final String? comment;
  final String? promoCode;
  final List<CreateOrderItemPayload> items;

  bool get isValid {
    final hasRequiredAddress = fulfillmentType == OrderFulfillmentType.pickup ||
        (addressId?.trim().isNotEmpty ?? false);

    return restaurantId.trim().isNotEmpty &&
        hasRequiredAddress &&
        validItems.isNotEmpty;
  }

  List<CreateOrderItemPayload> get validItems {
    return items.where((item) => item.isValid).toList();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'restaurantId': restaurantId.trim(),
      // Checkout is blocked in release builds until the real payment provider
      // is connected. Debug builds use the positive payment stub, so mark
      // those test orders as CASH instead of creating a CARD/PENDING order
      // that production correctly expires after the unpaid-card timeout.
      'paymentMethod': kReleaseMode ? 'CARD' : 'CASH',
      'fulfillmentType': fulfillmentType.wireName,
      'leaveAtDoor':
          fulfillmentType == OrderFulfillmentType.pickup ? false : leaveAtDoor,
      'items': validItems.map((item) => item.toJson()).toList(),
    };

    if (fulfillmentType == OrderFulfillmentType.delivery) {
      data['addressId'] = addressId?.trim();
    }

    final normalizedPhone = _normalizeOptional(phone);
    final normalizedComment = _normalizeOptional(comment);
    final normalizedPromoCode = _normalizeOptional(promoCode);

    if (normalizedPhone != null) {
      data['phone'] = normalizedPhone;
    }

    if (normalizedComment != null) {
      data['comment'] = normalizedComment;
    }

    if (normalizedPromoCode != null) {
      data['promoCode'] = normalizedPromoCode;
    }

    return data;
  }

  static String? _normalizeOptional(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}
