import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/localization/localizedValue.dart';

class SearchResult {
  const SearchResult({
    required this.restaurants,
    required this.products,
  });

  final List<SearchRestaurantItem> restaurants;
  final List<SearchProductItem> products;

  bool get isEmpty => restaurants.isEmpty && products.isEmpty;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final restaurantsRaw = _extractList(json, const ['restaurants']) ??
        _extractList(json, const ['items', 'restaurants']) ??
        _extractList(json, const ['data', 'restaurants']) ??
        _extractList(json, const ['result', 'restaurants']) ??
        const [];

    final productsRaw = _extractList(json, const ['products']) ??
        _extractList(json, const ['items', 'products']) ??
        _extractList(json, const ['data', 'products']) ??
        _extractList(json, const ['result', 'products']) ??
        _extractList(json, const ['dishes']) ??
        _extractList(json, const ['items', 'dishes']) ??
        _extractList(json, const ['drinks']) ??
        _extractList(json, const ['items', 'drinks']) ??
        const [];

    return SearchResult(
      restaurants: restaurantsRaw
          .whereType<Map>()
          .map(
            (e) => SearchRestaurantItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      products: productsRaw
          .whereType<Map>()
          .map((e) => SearchProductItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static List<dynamic>? _extractList(
    Map<String, dynamic> json,
    List<String> path,
  ) {
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
}

class SearchRestaurantItem {
  const SearchRestaurantItem({
    required this.id,
    required this.name,
    required this.ratingAvg,
    this.address,
    this.workingHours,
    this.coverImageUrl,
  });

  final String id;

  /// Restaurant names are brand/proper names and intentionally do not switch
  /// with the UI language.
  final String name;
  final double ratingAvg;
  final String? address;
  final String? workingHours;
  final String? coverImageUrl;

  factory SearchRestaurantItem.fromJson(Map<String, dynamic> json) {
    return SearchRestaurantItem(
      id: _readString(json, const ['id']),
      name: _readString(
        json,
        const ['name'],
        fallbackKeys: ['nameRu', 'nameKk', 'titleRu', 'title'],
      ),
      ratingAvg: _readDouble(
        json,
        const ['ratingAvg'],
        fallbackKeys: ['rating', 'avgRating'],
      ),
      address: _readNullableString(json, const ['address']),
      workingHours: _readNullableString(
        json,
        const ['workingHours'],
        fallbackKeys: ['working_hours'],
      ),
      coverImageUrl: _normalizeImageUrl(
        _readNullableString(
          json,
          const ['coverImageUrl'],
          fallbackKeys: ['imageUrl', 'cover', 'image'],
        ),
      ),
    );
  }
}

class SearchProductItem {
  const SearchProductItem({
    required this.id,
    required this.titleRu,
    required this.price,
    required this.restaurantId,
    required this.restaurantName,
    this.titleKk,
    this.imageUrl,
    this.categoryTitleRu,
    this.categoryTitleKk,
    this.description,
    this.weight,
    this.isDrink = false,
  });

  final String id;
  final String titleRu;
  final String? titleKk;
  final int price;
  final String restaurantId;
  final String restaurantName;
  final String? imageUrl;
  final String? categoryTitleRu;
  final String? categoryTitleKk;
  final String? description;
  final String? weight;
  final bool isDrink;

  String get title => LocalizedValue.select(
        ru: titleRu,
        kk: titleKk,
        fallback: 'Товар',
      );

  String? get categoryTitle {
    final ru = categoryTitleRu?.trim() ?? '';
    final kk = categoryTitleKk?.trim() ?? '';
    if (ru.isEmpty && kk.isEmpty) return null;
    return LocalizedValue.select(
      ru: ru,
      kk: kk,
      fallback: ru.isNotEmpty ? ru : kk,
    );
  }

  factory SearchProductItem.fromJson(Map<String, dynamic> json) {
    final restaurantMap = _readMap(
      json,
      const ['restaurant'],
    );

    final categoryMap = _readMap(
      json,
      const ['category'],
    );

    return SearchProductItem(
      id: _readString(json, const ['id']),
      titleRu: _readString(
        json,
        const ['titleRu'],
        fallbackKeys: ['title', 'name', 'nameRu'],
      ),
      titleKk: _readNullableString(
        json,
        const ['titleKk'],
        fallbackKeys: ['nameKk'],
      ),
      price: _readInt(json, const ['price']),
      restaurantId: _readString(
        json,
        const ['restaurantId'],
        fallbackKeys: restaurantMap == null ? [] : ['restaurant.id'],
        fallbackValue: restaurantMap?['id']?.toString() ?? '',
      ),
      restaurantName: _readString(
        json,
        const ['restaurantName'],
        fallbackKeys: restaurantMap == null
            ? ['restaurantTitle']
            : [
                'restaurant.name',
                'restaurant.nameRu',
                'restaurant.nameKk',
                'restaurant.titleRu',
              ],
        fallbackValue: restaurantMap == null
            ? ''
            : (restaurantMap['name'] ??
                    restaurantMap['nameRu'] ??
                    restaurantMap['nameKk'] ??
                    restaurantMap['titleRu'] ??
                    '')
                .toString(),
      ),
      imageUrl: _normalizeImageUrl(
        _readNullableString(
          json,
          const ['effectiveImageUrl'],
          fallbackKeys: ['imageUrl', 'fullImageUrl'],
        ),
      ),
      categoryTitleRu: categoryMap == null
          ? _readNullableString(
              json,
              const ['categoryTitleRu'],
              fallbackKeys: ['categoryTitle'],
            )
          : _nullableValue(
              categoryMap['titleRu'] ??
                  categoryMap['title'] ??
                  categoryMap['name'],
            ),
      categoryTitleKk: categoryMap == null
          ? _readNullableString(json, const ['categoryTitleKk'])
          : _nullableValue(categoryMap['titleKk']),
      description: _readNullableString(json, const ['description']),
      weight: _readNullableString(json, const ['weight']),
      isDrink: _readBool(
        json,
        const ['isDrink'],
        fallbackKeys: ['drink'],
      ),
    );
  }
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
    final dynamic value;
    if (key.contains('.')) {
      value = _readValue(json, key.split('.'));
    } else {
      value = json[key];
    }

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

String? _nullableValue(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int _readInt(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _readValue(json, primaryPath);
  final parsedDirect = _parseInt(direct);
  if (parsedDirect != null) {
    return parsedDirect;
  }

  for (final key in fallbackKeys) {
    final dynamic value;
    if (key.contains('.')) {
      value = _readValue(json, key.split('.'));
    } else {
      value = json[key];
    }

    final parsed = _parseInt(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _readValue(json, primaryPath);
  final parsedDirect = _parseDouble(direct);
  if (parsedDirect != null) {
    return parsedDirect;
  }

  for (final key in fallbackKeys) {
    final dynamic value;
    if (key.contains('.')) {
      value = _readValue(json, key.split('.'));
    } else {
      value = json[key];
    }

    final parsed = _parseDouble(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> primaryPath, {
  List<String> fallbackKeys = const [],
}) {
  final direct = _readValue(json, primaryPath);
  final parsedDirect = _parseBool(direct);
  if (parsedDirect != null) {
    return parsedDirect;
  }

  for (final key in fallbackKeys) {
    final dynamic value;
    if (key.contains('.')) {
      value = _readValue(json, key.split('.'));
    } else {
      value = json[key];
    }

    final parsed = _parseBool(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return false;
}

Map<String, dynamic>? _readMap(
  Map<String, dynamic> json,
  List<String> path,
) {
  final value = _readValue(json, path);
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
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
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  if (value is int) {
    return value != 0;
  }
  return null;
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
