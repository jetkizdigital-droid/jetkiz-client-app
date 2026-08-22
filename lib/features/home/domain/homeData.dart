/// Jetkiz mobile
/// Home screen backend contract.
/// Uses:
/// - GET /home-cms/public
/// - GET /restaurants/public/list
///
/// Notes for future GPT:
/// - promo comes from Home CMS
/// - categories are home sections configured in admin
/// - each category may contain products[]
/// - pinned restaurants come from restaurants/public/list -> pinned
/// - image urls can be relative (/uploads/...) and must be resolved with AppConfig.baseUrl
/// - product.restaurant must include status/isInApp/isAcceptingOrders/runtimeStatus when possible,
///   so Flutter can hide products from closed restaurants before checkout.
library;

import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurantAvailability.dart';

class HomePromo {
  final String titleRu;
  final String titleKk;
  final String? imageUrl;
  final bool isActive;

  const HomePromo({
    required this.titleRu,
    required this.titleKk,
    required this.imageUrl,
    required this.isActive,
  });

  factory HomePromo.fromJson(Map<String, dynamic> json) {
    return HomePromo(
      titleRu: _readString(json['titleRu']),
      titleKk: _readString(json['titleKk']),
      imageUrl: _readNullableString(json['imageUrl']),
      isActive: _readBool(json['isActive']),
    );
  }

  String get title => titleRu.isNotEmpty ? titleRu : titleKk;

  String? get fullImageUrl => _resolveImageUrl(imageUrl);
}

class HomeCategoryProductRestaurant {
  final String id;
  final String nameRu;
  final String nameKk;

  /// Admin status:
  /// OPEN / CLOSED / BLOCKED / ARCHIVED / HIDDEN.
  final String status;

  /// Runtime status calculated by backend using workingHours:
  /// OPEN / CLOSED.
  ///
  /// If backend does not send runtimeStatus, Flutter falls back to admin status
  /// to avoid hiding all products by mistake.
  final String runtimeStatus;

  final bool isInApp;
  final bool isAcceptingOrders;
  final String? blockedAt;
  final String? workingHours;

  const HomeCategoryProductRestaurant({
    required this.id,
    required this.nameRu,
    required this.nameKk,
    required this.status,
    required this.runtimeStatus,
    required this.isInApp,
    required this.isAcceptingOrders,
    required this.blockedAt,
    required this.workingHours,
  });

  factory HomeCategoryProductRestaurant.fromJson(Map<String, dynamic> json) {
    return HomeCategoryProductRestaurant(
      id: _readString(json['id']),
      nameRu: _readString(json['nameRu'] ?? json['name']),
      nameKk: _readString(json['nameKk']),
      status: _readString(json['status']),
      runtimeStatus: _readString(json['runtimeStatus']),
      isInApp: json.containsKey('isInApp') ? _readBool(json['isInApp']) : true,
      isAcceptingOrders: json.containsKey('isAcceptingOrders')
          ? _readBool(json['isAcceptingOrders'])
          : false,
      blockedAt: _readNullableString(json['blockedAt']),
      workingHours: _readNullableString(json['workingHours']),
    );
  }

  String get name => nameRu.isNotEmpty ? nameRu : nameKk;

  String get statusUpper => status.trim().toUpperCase();

  String get runtimeStatusUpper => runtimeStatus.trim().toUpperCase();

  bool get isAdminClosed {
    return statusUpper == 'CLOSED' ||
        statusUpper == 'BLOCKED' ||
        statusUpper == 'ARCHIVED' ||
        statusUpper == 'HIDDEN';
  }

  bool get isRuntimeClosed {
    return runtimeStatusUpper == 'CLOSED';
  }

  RestaurantAvailability get availability {
    return RestaurantAvailability(
      status: runtimeStatus.trim().isNotEmpty ? runtimeStatus : status,
      isInApp: isInApp,
      isAcceptingOrders: isAcceptingOrders,
    );
  }

  bool get isOpenForOrders {
    if (blockedAt != null && blockedAt!.trim().isNotEmpty) return false;
    if (isAdminClosed) return false;
    if (runtimeStatusUpper.isNotEmpty && isRuntimeClosed) return false;
    return availability.canOrder;
  }
}

class HomeCategoryProductData {
  final String id;
  final String titleRu;
  final String titleKk;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  final String restaurantId;
  final HomeCategoryProductRestaurant restaurant;

  const HomeCategoryProductData({
    required this.id,
    required this.titleRu,
    required this.titleKk,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.restaurantId,
    required this.restaurant,
  });

  factory HomeCategoryProductData.fromJson(Map<String, dynamic> json) {
    return HomeCategoryProductData(
      id: _readString(json['id']),
      titleRu: _readString(json['titleRu'] ?? json['title'] ?? json['name']),
      titleKk: _readString(json['titleKk']),
      price: _readInt(json['price']),
      imageUrl: _readNullableString(json['imageUrl']),
      isAvailable: json.containsKey('isAvailable')
          ? _readBool(json['isAvailable'])
          : true,
      restaurantId: _readString(json['restaurantId']),
      restaurant: HomeCategoryProductRestaurant.fromJson(
        _readMap(json['restaurant']) ?? const <String, dynamic>{},
      ),
    );
  }

  String get title => titleRu.isNotEmpty ? titleRu : titleKk;

  bool get isOrderable {
    return isAvailable && restaurant.isOpenForOrders;
  }

  String? get fullImageUrl => _resolveImageUrl(imageUrl);
}

class HomeCategoryProductLink {
  final String id;
  final String productId;
  final int sortOrder;
  final bool isActive;
  final HomeCategoryProductData? product;

  const HomeCategoryProductLink({
    required this.id,
    required this.productId,
    required this.sortOrder,
    required this.isActive,
    required this.product,
  });

  factory HomeCategoryProductLink.fromJson(Map<String, dynamic> json) {
    return HomeCategoryProductLink(
      id: _readString(json['id']),
      productId: _readString(json['productId']),
      sortOrder: _readInt(json['sortOrder']),
      isActive:
          json.containsKey('isActive') ? _readBool(json['isActive']) : true,
      product: json['product'] is Map
          ? HomeCategoryProductData.fromJson(
              Map<String, dynamic>.from(json['product'] as Map),
            )
          : null,
    );
  }
}

class HomeCategoryData {
  final String id;
  final String titleRu;
  final String titleKk;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final List<HomeCategoryProductLink> products;

  const HomeCategoryData({
    required this.id,
    required this.titleRu,
    required this.titleKk,
    required this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.products,
  });

  factory HomeCategoryData.fromJson(Map<String, dynamic> json) {
    final rawProducts = (json['products'] as List?) ?? const [];

    return HomeCategoryData(
      id: _readString(json['id']),
      titleRu: _readString(json['titleRu'] ?? json['title'] ?? json['name']),
      titleKk: _readString(json['titleKk']),
      imageUrl: _readNullableString(json['imageUrl']),
      sortOrder: _readInt(json['sortOrder']),
      isActive:
          json.containsKey('isActive') ? _readBool(json['isActive']) : true,
      products: rawProducts
          .whereType<Map>()
          .map(
            (item) => HomeCategoryProductLink.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  String get title => titleRu.isNotEmpty ? titleRu : titleKk;

  String? get fullImageUrl => _resolveImageUrl(imageUrl);
}

class HomeRestaurantData {
  final String id;
  final int number;
  final String slug;
  final String nameRu;
  final String nameKk;
  final String? phone;
  final String? address;
  final String? workingHours;
  final String? coverImageUrl;
  final double ratingAvg;
  final int ratingCount;
  final String status;
  final String runtimeStatus;
  final bool isInApp;
  final bool isAcceptingOrders;
  final String? blockedAt;
  final bool isPinned;
  final int sortOrder;
  final bool useRandom;

  const HomeRestaurantData({
    required this.id,
    required this.number,
    required this.slug,
    required this.nameRu,
    required this.nameKk,
    required this.phone,
    required this.address,
    required this.workingHours,
    required this.coverImageUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.status,
    required this.runtimeStatus,
    required this.isInApp,
    required this.isAcceptingOrders,
    required this.blockedAt,
    required this.isPinned,
    required this.sortOrder,
    required this.useRandom,
  });

  factory HomeRestaurantData.fromJson(Map<String, dynamic> json) {
    return HomeRestaurantData(
      id: _readString(json['id']),
      number: _readInt(json['number']),
      slug: _readString(json['slug']),
      nameRu: _readString(json['nameRu'] ?? json['name']),
      nameKk: _readString(json['nameKk']),
      phone: _readNullableString(json['phone']),
      address: _readNullableString(json['address']),
      workingHours: _readNullableString(json['workingHours']),
      coverImageUrl: _readNullableString(json['coverImageUrl']),
      ratingAvg: _readDouble(json['ratingAvg']),
      ratingCount: _readInt(json['ratingCount']),
      status: _readString(json['status']),
      runtimeStatus: _readString(json['runtimeStatus']),
      isInApp: json.containsKey('isInApp') ? _readBool(json['isInApp']) : true,
      isAcceptingOrders: json.containsKey('isAcceptingOrders')
          ? _readBool(json['isAcceptingOrders'])
          : false,
      blockedAt: _readNullableString(json['blockedAt']),
      isPinned: _readBool(json['isPinned']),
      sortOrder: _readInt(json['sortOrder']),
      useRandom: _readBool(json['useRandom']),
    );
  }

  String get name => nameRu.isNotEmpty ? nameRu : nameKk;

  String get statusUpper => status.trim().toUpperCase();

  String get runtimeStatusUpper => runtimeStatus.trim().toUpperCase();

  RestaurantAvailability get availability {
    return RestaurantAvailability(
      status: runtimeStatus.trim().isNotEmpty ? runtimeStatus : status,
      isInApp: isInApp,
      isAcceptingOrders: isAcceptingOrders,
    );
  }

  bool get isOpenForOrders {
    if (blockedAt != null && blockedAt!.trim().isNotEmpty) return false;

    if (statusUpper == 'CLOSED' ||
        statusUpper == 'BLOCKED' ||
        statusUpper == 'ARCHIVED' ||
        statusUpper == 'HIDDEN') {
      return false;
    }

    if (runtimeStatusUpper == 'CLOSED') {
      return false;
    }

    return availability.canOrder;
  }

  String? get fullCoverImageUrl => _resolveImageUrl(coverImageUrl);
}

class HomeData {
  final HomePromo? promo;
  final List<HomeCategoryData> categories;
  final List<HomeRestaurantData> pinnedRestaurants;

  const HomeData({
    required this.promo,
    required this.categories,
    required this.pinnedRestaurants,
  });
}

String _readString(dynamic value) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }

  return text;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value?.toString().trim() ?? '';

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return 0;
  }

  return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();

  final text = value?.toString().trim() ?? '';

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return 0;
  }

  return double.tryParse(text.replaceAll(',', '.')) ?? 0;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase() ?? '';

  return text == 'true' || text == '1' || text == 'yes';
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);

  return null;
}

String? _resolveImageUrl(String? value) {
  final raw = value?.trim() ?? '';

  if (raw.isEmpty) {
    return null;
  }

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  final baseUrl = AppConfig.baseUrl.trim();

  if (baseUrl.isEmpty) {
    return raw;
  }

  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  final normalizedPath = raw.startsWith('/') ? raw : '/$raw';

  return '$normalizedBase$normalizedPath';
}
