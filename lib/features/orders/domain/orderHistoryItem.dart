import 'package:jetkiz_mobile/core/localization/localizedValue.dart';

class OrderHistoryItem {
  const OrderHistoryItem({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.status,
    this.fulfillmentType = 'DELIVERY',
    required this.total,
    required this.paymentStatus,
    required this.restaurant,
    required this.itemsCount,
    required this.previewItems,
    this.pickupCode,
    this.pickupCodeExpiresAt,
    this.pickupCodeVerifiedAt,
  });

  final String id;
  final int number;
  final DateTime createdAt;
  final String status;
  final String fulfillmentType;
  final int total;
  final String paymentStatus;
  final OrderHistoryRestaurant restaurant;
  final int itemsCount;
  final List<OrderPreviewItem> previewItems;
  final String? pickupCode;
  final DateTime? pickupCodeExpiresAt;
  final DateTime? pickupCodeVerifiedAt;

  String get statusUpper => status.trim().toUpperCase();

  String get fulfillmentTypeUpper => fulfillmentType.trim().toUpperCase();

  bool get isPickup => fulfillmentTypeUpper == 'PICKUP';

  bool get canShowPickupCode {
    final code = pickupCode?.trim() ?? '';
    if (!isPickup || code.isEmpty || pickupCodeVerifiedAt != null) {
      return false;
    }

    switch (statusUpper) {
      case 'DELIVERED':
      case 'CANCELED':
      case 'CANCELLED':
      case 'REJECTED':
        return false;
      default:
        return true;
    }
  }

  bool get isActive {
    switch (statusUpper) {
      case 'CREATED':
      case 'ACCEPTED':
      case 'COOKING':
      case 'READY':
      case 'ON_THE_WAY':
        return true;
      default:
        return false;
    }
  }

  bool get isCompleted {
    switch (statusUpper) {
      case 'DELIVERED':
      case 'PAID':
        return true;
      default:
        return false;
    }
  }

  bool get isCanceled =>
      statusUpper == 'CANCELED' || statusUpper == 'CANCELLED';

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: (json['id'] ?? '').toString(),
      number: _parseInt(json['number']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      status: (json['status'] ?? '').toString(),
      fulfillmentType: (json['fulfillmentType'] ?? 'DELIVERY').toString(),
      total: _parseInt(json['total']),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      restaurant: OrderHistoryRestaurant.fromJson(
        _readMap(json['restaurant']) ?? const <String, dynamic>{},
      ),
      itemsCount: _parseInt(json['itemsCount']),
      previewItems: _readList(json['previewItems'])
          .whereType<Map>()
          .map((e) => OrderPreviewItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pickupCode: _nullableString(json['pickupCode']),
      pickupCodeExpiresAt: _parseDateTime(json['pickupCodeExpiresAt']),
      pickupCodeVerifiedAt: _parseDateTime(json['pickupCodeVerifiedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _nullableString(dynamic value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty || raw.toLowerCase() == 'null' ? null : raw;
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

class OrderHistoryRestaurant {
  const OrderHistoryRestaurant({
    required this.id,
    required this.slug,
    required this.nameRu,
    this.coverImageUrl,
    this.ratingAvg,
    this.ratingCount,
    this.status,
  });

  final String id;
  final String slug;
  final String nameRu;
  final String? coverImageUrl;
  final double? ratingAvg;
  final int? ratingCount;
  final String? status;

  /// Restaurant name is a brand/proper name and is not translated by locale.
  String get displayName {
    final name = nameRu.trim();
    return name.isEmpty ? 'Ресторан' : name;
  }

  String? get fullCoverImageUrl => _normalizeImageUrl(coverImageUrl);

  factory OrderHistoryRestaurant.fromJson(Map<String, dynamic> json) {
    return OrderHistoryRestaurant(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      nameRu: (json['nameRu'] ?? json['name'] ?? '').toString(),
      coverImageUrl: _normalizeImageUrl(json['coverImageUrl']?.toString()),
      ratingAvg: _parseDouble(json['ratingAvg']),
      ratingCount: _parseNullableInt(json['ratingCount']),
      status: json['status']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _normalizeImageUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return raw;
  }
}

class OrderPreviewItem {
  const OrderPreviewItem({
    String? title,
    this.titleRu = '',
    this.titleKk = '',
    required this.quantity,
  }) : _legacyTitle = title ?? '';

  final String titleRu;
  final String titleKk;
  final String _legacyTitle;
  final int quantity;

  String get title => LocalizedValue.select(
        ru: titleRu.isNotEmpty ? titleRu : _legacyTitle,
        kk: titleKk,
        fallback: _legacyTitle,
      );

  factory OrderPreviewItem.fromJson(Map<String, dynamic> json) {
    final legacyTitle = (json['title'] ?? '').toString();
    return OrderPreviewItem(
      title: legacyTitle,
      titleRu: (json['titleRu'] ?? legacyTitle).toString(),
      titleKk: (json['titleKk'] ?? '').toString(),
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

class OrdersHistoryPageData {
  const OrdersHistoryPageData({
    required this.items,
    required this.total,
  });

  final List<OrderHistoryItem> items;
  final int total;

  factory OrdersHistoryPageData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : const [];
    return OrdersHistoryPageData(
      items: rawItems
          .whereType<Map>()
          .map((e) => OrderHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: _parseInt(json['total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
