class OrderHistoryItem {
  const OrderHistoryItem({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.paymentStatus,
    required this.restaurant,
    required this.itemsCount,
    required this.previewItems,
  });

  final String id;
  final int number;
  final DateTime createdAt;
  final String status;
  final int total;
  final String paymentStatus;
  final OrderHistoryRestaurant restaurant;
  final int itemsCount;
  final List<OrderPreviewItem> previewItems;

  bool get isActive {
    switch (status.toUpperCase()) {
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
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'PAID':
        return true;
      default:
        return false;
    }
  }

  bool get isCanceled => status.toUpperCase() == 'CANCELED';

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: (json['id'] ?? '').toString(),
      number: _parseInt(json['number']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      status: (json['status'] ?? '').toString(),
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
    required this.title,
    required this.quantity,
  });

  final String title;
  final int quantity;

  factory OrderPreviewItem.fromJson(Map<String, dynamic> json) {
    return OrderPreviewItem(
      title: (json['title'] ?? '').toString(),
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