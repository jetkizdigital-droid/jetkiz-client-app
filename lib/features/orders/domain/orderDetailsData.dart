import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/localization/localizedValue.dart';

class OrderDetailsData {
  const OrderDetailsData({
    required this.id,
    required this.number,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.deliveryDiscountAmount,
    required this.total,
    required this.phone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.ratingGiven,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.leaveAtDoor = false,
    this.deliveredAt,
    this.promisedAt,
    this.fulfillmentType = 'DELIVERY',
    this.pickupCode,
    this.pickupCodeExpiresAt,
    this.pickupCodeVerifiedAt,
    this.restaurant,
    this.address,
    this.items = const [],
  });

  final String id;
  final int number;
  final String status;
  final int subtotal;
  final int deliveryFee;
  final int discountAmount;
  final int deliveryDiscountAmount;
  final int total;
  final String phone;
  final String? comment;
  final bool leaveAtDoor;
  final String paymentMethod;
  final String paymentStatus;
  final bool ratingGiven;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;
  final DateTime? promisedAt;
  final String fulfillmentType;
  final String? pickupCode;
  final DateTime? pickupCodeExpiresAt;
  final DateTime? pickupCodeVerifiedAt;
  final OrderDetailsRestaurant? restaurant;
  final OrderDetailsAddress? address;
  final List<OrderDetailsItem> items;

  String get statusUpper => status.trim().toUpperCase();

  String get fulfillmentTypeUpper => fulfillmentType.trim().toUpperCase();

  bool get isPickup => fulfillmentTypeUpper == 'PICKUP';

  bool get isDelivered => statusUpper == 'DELIVERED';

  bool get canLeaveReview {
    return statusUpper == 'DELIVERED' && !ratingGiven;
  }

  bool get canRepeatOrder => items.isNotEmpty;

  int get finalDiscount => discountAmount + deliveryDiscountAmount;

  factory OrderDetailsData.fromJson(Map<String, dynamic> json) {
    return OrderDetailsData(
      id: (json['id'] ?? '').toString(),
      number: _parseInt(json['number']),
      status: (json['status'] ?? '').toString(),
      subtotal: _parseInt(json['subtotal']),
      deliveryFee: _parseInt(json['deliveryFee']),
      discountAmount: _parseInt(json['discountAmount']),
      deliveryDiscountAmount: _parseInt(json['deliveryDiscountAmount']),
      total: _parseInt(json['total']),
      phone: (json['phone'] ?? '').toString(),
      comment: _nullableString(json['comment']),
      leaveAtDoor: json['leaveAtDoor'] == true,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      ratingGiven: json['ratingGiven'] == true,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      deliveredAt: _parseDateTime(json['deliveredAt']),
      promisedAt: _parseDateTime(json['promisedAt']),
      fulfillmentType: (json['fulfillmentType'] ?? 'DELIVERY').toString(),
      pickupCode: _nullableString(json['pickupCode']),
      pickupCodeExpiresAt: _parseDateTime(json['pickupCodeExpiresAt']),
      pickupCodeVerifiedAt: _parseDateTime(json['pickupCodeVerifiedAt']),
      restaurant: _readMap(json['restaurant']) == null
          ? null
          : OrderDetailsRestaurant.fromJson(
              Map<String, dynamic>.from(_readMap(json['restaurant'])!),
            ),
      address: _readMap(json['address']) == null
          ? null
          : OrderDetailsAddress.fromJson(
              Map<String, dynamic>.from(_readMap(json['address'])!),
            ),
      items: _readList(json['items'])
          .whereType<Map>()
          .map((e) => OrderDetailsItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _nullableString(dynamic value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<dynamic> _readList(dynamic value) {
    return value is List ? value : const [];
  }
}

class OrderDetailsRestaurant {
  const OrderDetailsRestaurant({
    required this.id,
    required this.nameRu,
    this.slug,
    this.nameKk,
    this.coverImageUrl,
    this.status,
  });

  final String id;
  final String nameRu;
  final String? slug;
  final String? nameKk;
  final String? coverImageUrl;
  final String? status;

  /// Restaurant name is a brand/proper name and is not translated by locale.
  String get displayName {
    final primary = nameRu.trim();
    if (primary.isNotEmpty) return primary;
    final fallback = nameKk?.trim() ?? '';
    return fallback.isNotEmpty ? fallback : 'Ресторан';
  }

  String? get resolvedCoverImageUrl {
    final raw = (coverImageUrl ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return '${AppConfig.baseUrl}$raw';
    }
    return '${AppConfig.baseUrl}/$raw';
  }

  factory OrderDetailsRestaurant.fromJson(Map<String, dynamic> json) {
    return OrderDetailsRestaurant(
      id: (json['id'] ?? '').toString(),
      nameRu: (json['nameRu'] ?? json['name'] ?? '').toString(),
      slug: _nullableString(json['slug']),
      nameKk: _nullableString(json['nameKk']),
      coverImageUrl: _nullableString(json['coverImageUrl']),
      status: _nullableString(json['status']),
    );
  }

  static String? _nullableString(dynamic value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }
}

class OrderDetailsAddress {
  const OrderDetailsAddress({
    required this.id,
    required this.title,
    required this.address,
    this.floor,
    this.door,
    this.entrance,
    this.intercom,
    this.contactPhone,
    this.comment,
  });

  final String id;
  final String title;
  final String address;
  final String? floor;
  final String? door;
  final String? entrance;
  final String? intercom;
  final String? contactPhone;
  final String? comment;

  String get formatted {
    final isKk = LocalizedValue.language.name == 'kk';
    final parts = <String>[
      address,
      if ((entrance ?? '').trim().isNotEmpty)
        '${isKk ? 'Кіреберіс' : 'Подъезд'}: $entrance',
      if ((floor ?? '').trim().isNotEmpty) '${isKk ? 'Қабат' : 'Этаж'}: $floor',
      if ((door ?? '').trim().isNotEmpty)
        '${isKk ? 'Пәтер/кеңсе' : 'Кв/офис'}: $door',
    ];
    return parts.join(', ');
  }

  factory OrderDetailsAddress.fromJson(Map<String, dynamic> json) {
    return OrderDetailsAddress(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      floor: _nullableString(json['floor']),
      door: _nullableString(json['door']),
      entrance: _nullableString(json['entrance']),
      intercom: _nullableString(json['intercom']),
      contactPhone: _nullableString(json['contactPhone']),
      comment: _nullableString(json['comment']),
    );
  }

  static String? _nullableString(dynamic value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }
}

class OrderDetailsItem {
  const OrderDetailsItem({
    required this.id,
    required this.productId,
    String? title,
    this.titleRu = '',
    this.titleKk = '',
    required this.price,
    required this.quantity,
  }) : _legacyTitle = title ?? '';

  final String id;
  final String productId;
  final String titleRu;
  final String titleKk;
  final String _legacyTitle;
  final int price;
  final int quantity;

  String get title => LocalizedValue.select(
        ru: titleRu.isNotEmpty ? titleRu : _legacyTitle,
        kk: titleKk,
        fallback: _legacyTitle,
      );

  int get lineTotal => price * quantity;

  factory OrderDetailsItem.fromJson(Map<String, dynamic> json) {
    final legacyTitle = (json['title'] ?? '').toString();
    return OrderDetailsItem(
      id: (json['id'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      title: legacyTitle,
      titleRu: (json['titleRu'] ?? legacyTitle).toString(),
      titleKk: (json['titleKk'] ?? '').toString(),
      price: _parseInt(json['price']),
      quantity: _parseInt(json['quantity']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
