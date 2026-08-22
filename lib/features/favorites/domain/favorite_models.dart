import 'package:jetkiz_mobile/core/config/appConfig.dart';

class FavoriteIdsResponse {
  const FavoriteIdsResponse({
    required this.restaurantIds,
    required this.productIds,
  });

  final List<String> restaurantIds;
  final List<String> productIds;

  factory FavoriteIdsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteIdsResponse(
      restaurantIds: _readStringList(json, const ['restaurantIds']),
      productIds: _readStringList(json, const ['productIds']),
    );
  }
}

class FavoriteMeta {
  const FavoriteMeta({
    required this.total,
  });

  final int total;

  factory FavoriteMeta.fromJson(Map<String, dynamic> json) {
    return FavoriteMeta(
      total: _readInt(json, const ['total']),
    );
  }
}

class FavoriteRestaurantsResponse {
  const FavoriteRestaurantsResponse({
    required this.items,
    required this.meta,
  });

  final List<FavoriteRestaurantRecord> items;
  final FavoriteMeta meta;

  factory FavoriteRestaurantsResponse.fromJson(Map<String, dynamic> json) {
    final itemsRaw = _extractList(json, const ['items']) ??
        _extractList(json, const ['data', 'items']) ??
        _extractList(json, const ['result', 'items']) ??
        const [];

    final metaRaw = _extractMap(json, const ['meta']) ??
        _extractMap(json, const ['data', 'meta']) ??
        _extractMap(json, const ['result', 'meta']) ??
        <String, dynamic>{'total': itemsRaw.length};

    return FavoriteRestaurantsResponse(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (e) => FavoriteRestaurantRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      meta: FavoriteMeta.fromJson(metaRaw),
    );
  }
}

class FavoriteProductsResponse {
  const FavoriteProductsResponse({
    required this.items,
    required this.meta,
  });

  final List<FavoriteProductRecord> items;
  final FavoriteMeta meta;

  factory FavoriteProductsResponse.fromJson(Map<String, dynamic> json) {
    final itemsRaw = _extractList(json, const ['items']) ??
        _extractList(json, const ['data', 'items']) ??
        _extractList(json, const ['result', 'items']) ??
        const [];

    final metaRaw = _extractMap(json, const ['meta']) ??
        _extractMap(json, const ['data', 'meta']) ??
        _extractMap(json, const ['result', 'meta']) ??
        <String, dynamic>{'total': itemsRaw.length};

    return FavoriteProductsResponse(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (e) => FavoriteProductRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      meta: FavoriteMeta.fromJson(metaRaw),
    );
  }
}

class FavoriteAllResponse {
  const FavoriteAllResponse({
    required this.restaurants,
    required this.products,
    required this.restaurantCount,
    required this.productCount,
    required this.total,
  });

  final List<FavoriteRestaurantRecord> restaurants;
  final List<FavoriteProductRecord> products;
  final int restaurantCount;
  final int productCount;
  final int total;

  factory FavoriteAllResponse.fromJson(Map<String, dynamic> json) {
    final restaurantsRaw = _extractList(json, const ['restaurants']) ??
        _extractList(json, const ['data', 'restaurants']) ??
        const [];

    final productsRaw = _extractList(json, const ['products']) ??
        _extractList(json, const ['data', 'products']) ??
        const [];

    final meta = _extractMap(json, const ['meta']) ??
        _extractMap(json, const ['data', 'meta']) ??
        const <String, dynamic>{};

    return FavoriteAllResponse(
      restaurants: restaurantsRaw
          .whereType<Map>()
          .map(
            (e) => FavoriteRestaurantRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      products: productsRaw
          .whereType<Map>()
          .map(
            (e) => FavoriteProductRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      restaurantCount: _readInt(meta, const ['restaurantCount']),
      productCount: _readInt(meta, const ['productCount']),
      total: _readInt(meta, const ['total']),
    );
  }
}

class FavoriteRestaurantRecord {
  const FavoriteRestaurantRecord({
    required this.id,
    required this.createdAt,
    required this.restaurant,
  });

  final String id;
  final DateTime? createdAt;
  final FavoriteRestaurant restaurant;

  factory FavoriteRestaurantRecord.fromJson(Map<String, dynamic> json) {
    return FavoriteRestaurantRecord(
      id: _readString(json, const ['id']),
      createdAt: _parseDate(_readNullableString(json, const ['createdAt'])),
      restaurant: FavoriteRestaurant.fromJson(
        _extractMap(json, const ['restaurant']) ?? const <String, dynamic>{},
      ),
    );
  }
}

class FavoriteProductRecord {
  const FavoriteProductRecord({
    required this.id,
    required this.createdAt,
    required this.product,
  });

  final String id;
  final DateTime? createdAt;
  final FavoriteProduct product;

  factory FavoriteProductRecord.fromJson(Map<String, dynamic> json) {
    return FavoriteProductRecord(
      id: _readString(json, const ['id']),
      createdAt: _parseDate(_readNullableString(json, const ['createdAt'])),
      product: FavoriteProduct.fromJson(
        _extractMap(json, const ['product']) ?? const <String, dynamic>{},
      ),
    );
  }
}

class FavoriteRestaurant {
  const FavoriteRestaurant({
    required this.id,
    required this.name,
    required this.ratingAvg,
    required this.ratingCount,
    required this.status,
    required this.isInApp,
    this.slug,
    this.number,
    this.phone,
    this.address,
    this.workingHours,
    this.description,
    this.coverImageUrl,
    this.isPinned = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final double ratingAvg;
  final int ratingCount;
  final String status;
  final bool isInApp;

  final String? slug;
  final int? number;
  final String? phone;
  final String? address;
  final String? workingHours;
  final String? description;
  final String? coverImageUrl;
  final bool isPinned;
  final int sortOrder;

  factory FavoriteRestaurant.fromJson(Map<String, dynamic> json) {
    return FavoriteRestaurant(
      id: _readString(json, const ['id']),
      name: _readString(
        json,
        const ['nameRu'],
        fallbackKeys: ['name', 'titleRu', 'nameKk', 'title'],
      ),
      ratingAvg: _readDouble(json, const ['ratingAvg']),
      ratingCount: _readInt(json, const ['ratingCount']),
      status: _readString(
        json,
        const ['status'],
        fallbackValue: 'OPEN',
      ),
      isInApp: _readBool(
        json,
        const ['isInApp'],
        fallbackValue: true,
      ),
      slug: _readNullableString(json, const ['slug']),
      number: _readNullableInt(json, const ['number']),
      phone: _readNullableString(json, const ['phone']),
      address: _readNullableString(json, const ['address']),
      workingHours: _readNullableString(json, const ['workingHours']),
      description: _readNullableString(
        json,
        const ['descriptionRu'],
        fallbackKeys: ['description', 'descriptionKk'],
      ),
      coverImageUrl: _normalizeImageUrl(
        _readNullableString(
          json,
          const ['coverImageUrl'],
          fallbackKeys: ['imageUrl', 'cover', 'image'],
        ),
      ),
      isPinned: _readBool(
        json,
        const ['isPinned'],
        fallbackValue: false,
      ),
      sortOrder: _readInt(json, const ['sortOrder']),
    );
  }
}

class FavoriteProduct {
  const FavoriteProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.isAvailable,
    required this.restaurantId,
    required this.restaurant,
    this.categoryId,
    this.weight,
    this.composition,
    this.description,
    this.isDrink = false,
    this.imageUrl,
    this.effectiveImageUrl,
    this.category,
    this.images = const [],
  });

  final String id;
  final String title;
  final int price;
  final bool isAvailable;
  final String restaurantId;
  final FavoriteRestaurant restaurant;

  final String? categoryId;
  final String? weight;
  final String? composition;
  final String? description;
  final bool isDrink;
  final String? imageUrl;
  final String? effectiveImageUrl;
  final FavoriteProductCategory? category;
  final List<FavoriteProductImage> images;

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    final imagesRaw = _extractList(json, const ['images']) ?? const [];

    final parsedImages = imagesRaw
        .whereType<Map>()
        .map(
          (e) => FavoriteProductImage.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    final rawImageUrl = _normalizeImageUrl(
      _readNullableString(
        json,
        const ['imageUrl'],
        fallbackKeys: ['fullImageUrl'],
      ),
    );

    final rawEffectiveImageUrl = _normalizeImageUrl(
      _readNullableString(json, const ['effectiveImageUrl']),
    );

    final fallbackImage = parsedImages.isNotEmpty
        ? parsedImages
            .firstWhere(
              (x) => x.isMain,
              orElse: () => parsedImages.first,
            )
            .url
        : null;

    return FavoriteProduct(
      id: _readString(json, const ['id']),
      title: _readString(
        json,
        const ['titleRu'],
        fallbackKeys: ['title', 'name', 'titleKk', 'nameRu'],
      ),
      price: _readInt(json, const ['price']),
      isAvailable: _readBool(
        json,
        const ['isAvailable'],
        fallbackValue: true,
      ),
      restaurantId: _readString(json, const ['restaurantId']),
      restaurant: FavoriteRestaurant.fromJson(
        _extractMap(json, const ['restaurant']) ?? const <String, dynamic>{},
      ),
      categoryId: _readNullableString(json, const ['categoryId']),
      weight: _readNullableString(json, const ['weight']),
      composition: _readNullableString(json, const ['composition']),
      description: _readNullableString(json, const ['description']),
      isDrink: _readBool(
        json,
        const ['isDrink'],
        fallbackValue: false,
      ),
      imageUrl: rawImageUrl,
      effectiveImageUrl: rawEffectiveImageUrl ?? rawImageUrl ?? fallbackImage,
      category: _extractMap(json, const ['category']) != null
          ? FavoriteProductCategory.fromJson(
              _extractMap(json, const ['category'])!,
            )
          : null,
      images: parsedImages,
    );
  }
}

class FavoriteProductImage {
  const FavoriteProductImage({
    required this.id,
    required this.url,
    required this.isMain,
    required this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String url;
  final bool isMain;
  final int sortOrder;
  final DateTime? createdAt;

  factory FavoriteProductImage.fromJson(Map<String, dynamic> json) {
    return FavoriteProductImage(
      id: _readString(json, const ['id']),
      url: _normalizeImageUrl(_readNullableString(json, const ['url'])) ?? '',
      isMain: _readBool(
        json,
        const ['isMain'],
        fallbackValue: false,
      ),
      sortOrder: _readInt(json, const ['sortOrder']),
      createdAt: _parseDate(_readNullableString(json, const ['createdAt'])),
    );
  }
}

class FavoriteProductCategory {
  const FavoriteProductCategory({
    required this.id,
    required this.title,
    this.code,
    this.iconUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String? code;
  final String? iconUrl;
  final int sortOrder;

  factory FavoriteProductCategory.fromJson(Map<String, dynamic> json) {
    return FavoriteProductCategory(
      id: _readString(json, const ['id']),
      title: _readString(
        json,
        const ['titleRu'],
        fallbackKeys: ['title', 'titleKk', 'name'],
      ),
      code: _readNullableString(json, const ['code']),
      iconUrl: _normalizeImageUrl(_readNullableString(json, const ['iconUrl'])),
      sortOrder: _readInt(json, const ['sortOrder']),
    );
  }
}

List<dynamic>? _extractList(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  return current is List ? current : null;
}

Map<String, dynamic>? _extractMap(
    Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  if (current is Map<String, dynamic>) return current;
  if (current is Map) return Map<String, dynamic>.from(current);

  return null;
}

List<String> _readStringList(Map<String, dynamic> json, List<String> path) {
  final raw = _extractList(json, path) ?? const [];
  return raw
      .map((e) => e.toString())
      .where((e) => e.trim().isNotEmpty)
      .toList();
}

String _readString(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
  String fallbackValue = '',
}) {
  final direct = _readValue(json, primaryPath);
  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString().trim();
  }

  for (final key in fallbackKeys) {
    final value =
        key.contains('.') ? _readValue(json, key.split('.')) : json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  return fallbackValue;
}

String? _readNullableString(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final value = _readString(
    json,
    primaryPath,
    fallbackKeys: fallbackKeys,
  ).trim();

  return value.isEmpty ? null : value;
}

int _readInt(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _parseInt(_readValue(json, primaryPath));
  if (direct != null) return direct;

  for (final key in fallbackKeys) {
    final value =
        key.contains('.') ? _readValue(json, key.split('.')) : json[key];
    final parsed = _parseInt(value);
    if (parsed != null) return parsed;
  }

  return 0;
}

int? _readNullableInt(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _parseInt(_readValue(json, primaryPath));
  if (direct != null) return direct;

  for (final key in fallbackKeys) {
    final value =
        key.contains('.') ? _readValue(json, key.split('.')) : json[key];
    final parsed = _parseInt(value);
    if (parsed != null) return parsed;
  }

  return null;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _parseDouble(_readValue(json, primaryPath));
  if (direct != null) return direct;

  for (final key in fallbackKeys) {
    final value =
        key.contains('.') ? _readValue(json, key.split('.')) : json[key];
    final parsed = _parseDouble(value);
    if (parsed != null) return parsed;
  }

  return 0;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
  bool fallbackValue = false,
}) {
  final direct = _parseBool(_readValue(json, primaryPath));
  if (direct != null) return direct;

  for (final key in fallbackKeys) {
    final value =
        key.contains('.') ? _readValue(json, key.split('.')) : json[key];
    final parsed = _parseBool(value);
    if (parsed != null) return parsed;
  }

  return fallbackValue;
}

dynamic _readValue(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final key in path) {
    if (current is Map<String, dynamic> && current.containsKey(key)) {
      current = current[key];
    } else {
      return null;
    }
  }

  return current;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _normalizeImageUrl(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  if (raw.startsWith('/')) {
    return '${AppConfig.baseUrl}$raw';
  }

  return '${AppConfig.baseUrl}/$raw';
}
