import 'package:equatable/equatable.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurantAvailability.dart';

/// Jetkiz mobile
/// Restaurant menu domain models.
///
/// Backend public endpoint:
/// - GET /restaurants/:id/menu
///
/// Top-level response:
/// {
///   "restaurant": { ... },
///   "categories": [ ... ],
///   "items": [ ... ],
///   "products": [ ... ] // optional duplicate of items
/// }
///
/// Mobile source of truth:
/// - items[]
/// - if items[] is empty, products[] is used as safe fallback.
class RestaurantMenuData extends Equatable {
  const RestaurantMenuData({
    required this.restaurant,
    required this.categories,
    required this.items,
  });

  final RestaurantMenuRestaurant restaurant;
  final List<RestaurantMenuCategory> categories;
  final List<RestaurantMenuItem> items;

  bool get isEmpty => items.isEmpty;

  bool get hasItems => items.isNotEmpty;

  List<RestaurantMenuItem> get availableItems {
    return items.where((item) => item.isAvailable).toList();
  }

  List<RestaurantMenuGroup> get groupedItems {
    final categoryMeta = <String, RestaurantMenuCategory>{};

    for (final category in categories) {
      if (category.id.trim().isNotEmpty) {
        categoryMeta[category.id] = category;
      }
    }

    final groupedMap = <String, List<RestaurantMenuItem>>{};
    final uncategorized = <RestaurantMenuItem>[];

    for (final item in items) {
      final categoryId = item.categoryId?.trim();

      if (categoryId == null || categoryId.isEmpty) {
        uncategorized.add(item);
        continue;
      }

      groupedMap.putIfAbsent(categoryId, () => <RestaurantMenuItem>[]);
      groupedMap[categoryId]!.add(item);
    }

    final result = <RestaurantMenuGroup>[];

    final sortedEntries = groupedMap.entries.toList()
      ..sort((a, b) {
        final aCategory = categoryMeta[a.key];
        final bCategory = categoryMeta[b.key];

        final aOrder =
            aCategory?.sortOrder ?? a.value.first.categorySortOrder ?? 999999;
        final bOrder =
            bCategory?.sortOrder ?? b.value.first.categorySortOrder ?? 999999;

        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }

        final aTitle = aCategory?.title ?? a.value.first.categoryTitle;
        final bTitle = bCategory?.title ?? b.value.first.categoryTitle;

        return aTitle.compareTo(bTitle);
      });

    for (final entry in sortedEntries) {
      final itemsInCategory = List<RestaurantMenuItem>.from(entry.value)
        ..sort((a, b) => a.title.compareTo(b.title));

      final firstItem = itemsInCategory.first;

      final category = categoryMeta[entry.key] ??
          RestaurantMenuCategory(
            id: entry.key,
            code: firstItem.categoryCode ?? '',
            titleRu: firstItem.categoryNameRu ?? 'Без названия',
            titleKk: firstItem.categoryNameKk ?? firstItem.categoryNameRu ?? '',
            sortOrder: firstItem.categorySortOrder ?? 999999,
            iconUrl: null,
          );

      result.add(
        RestaurantMenuGroup(
          category: category,
          items: itemsInCategory,
        ),
      );
    }

    if (uncategorized.isNotEmpty) {
      final itemsWithoutCategory = List<RestaurantMenuItem>.from(uncategorized)
        ..sort((a, b) => a.title.compareTo(b.title));

      result.add(
        RestaurantMenuGroup(
          category: const RestaurantMenuCategory(
            id: 'uncategorized',
            code: 'uncategorized',
            titleRu: 'Без категории',
            titleKk: 'Санатсыз',
            sortOrder: 999999,
            iconUrl: null,
          ),
          items: itemsWithoutCategory,
        ),
      );
    }

    return result;
  }

  factory RestaurantMenuData.fromJson(Map<String, dynamic> json) {
    final rawItems = _asList(json['items']);
    final rawProducts = _asList(json['products']);

    final itemsSource = rawItems.isNotEmpty ? rawItems : rawProducts;

    return RestaurantMenuData(
      restaurant: RestaurantMenuRestaurant.fromJson(
        _asMap(json['restaurant']),
      ),
      categories: _parseCategories(json['categories']),
      items: _parseItems(itemsSource),
    );
  }

  static List<RestaurantMenuCategory> _parseCategories(dynamic value) {
    return _asList(value)
        .whereType<Map>()
        .map((item) {
          return RestaurantMenuCategory.fromJson(
            Map<String, dynamic>.from(item),
          );
        })
        .where((category) => category.id.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        if (a.sortOrder != b.sortOrder) {
          return a.sortOrder.compareTo(b.sortOrder);
        }

        return a.title.compareTo(b.title);
      });
  }

  static List<RestaurantMenuItem> _parseItems(dynamic value) {
    return _asList(value)
        .whereType<Map>()
        .map((item) {
          return RestaurantMenuItem.fromJson(
            Map<String, dynamic>.from(item),
          );
        })
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [
        restaurant,
        categories,
        items,
      ];
}

class RestaurantMenuRestaurant extends Equatable {
  const RestaurantMenuRestaurant({
    required this.id,
    required this.number,
    required this.status,
    required this.isInApp,
    required this.isAcceptingOrders,
    required this.nameRu,
    required this.nameKk,
    required this.slug,
    required this.isPickupEnabled,
    required this.pickupPreparationMinutes,
  });

  final String id;
  final int? number;
  final String status;
  final bool isInApp;
  final bool isAcceptingOrders;
  final String nameRu;
  final String nameKk;
  final String slug;
  final bool isPickupEnabled;
  final int? pickupPreparationMinutes;

  RestaurantAvailability get availability {
    return RestaurantAvailability(
      status: status,
      isInApp: isInApp,
      isAcceptingOrders: isAcceptingOrders,
    );
  }

  bool get isOpen => availability.isOpen;

  bool get canOrder => availability.canOrder;

  String get displayName {
    final ru = nameRu.trim();
    if (ru.isNotEmpty) return ru;

    final kk = nameKk.trim();
    if (kk.isNotEmpty) return kk;

    final slugValue = slug.trim();
    if (slugValue.isNotEmpty) return slugValue;

    return 'Ресторан';
  }

  factory RestaurantMenuRestaurant.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuRestaurant(
      id: _readString(json['id']),
      number: _readNullableInt(json['number']),
      status: _readString(json['status'], fallback: 'CLOSED'),
      isInApp: _readBool(json['isInApp'], fallback: false),
      isAcceptingOrders: _readBool(
        json['isAcceptingOrders'],
        fallback: false,
      ),
      nameRu: _readString(json['nameRu'] ?? json['name']),
      nameKk: _readString(json['nameKk']),
      slug: _readString(json['slug']),
      isPickupEnabled: _readBool(json['isPickupEnabled'], fallback: true),
      pickupPreparationMinutes:
          _readNullableInt(json['pickupPreparationMinutes']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        status,
        isInApp,
        isAcceptingOrders,
        nameRu,
        nameKk,
        slug,
        isPickupEnabled,
        pickupPreparationMinutes,
      ];
}

class RestaurantMenuCategory extends Equatable {
  const RestaurantMenuCategory({
    required this.id,
    required this.code,
    required this.titleRu,
    required this.titleKk,
    required this.sortOrder,
    required this.iconUrl,
  });

  final String id;
  final String code;
  final String titleRu;
  final String titleKk;
  final int sortOrder;
  final String? iconUrl;

  String get title {
    final ru = titleRu.trim();
    if (ru.isNotEmpty) return ru;

    final kk = titleKk.trim();
    if (kk.isNotEmpty) return kk;

    return 'Без категории';
  }

  factory RestaurantMenuCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuCategory(
      id: _readString(json['id']),
      code: _readString(json['code']),
      titleRu: _readString(json['titleRu'] ?? json['title']),
      titleKk: _readString(json['titleKk']),
      sortOrder: _readInt(json['sortOrder']),
      iconUrl: normalizeUrl(json['iconUrl']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        titleRu,
        titleKk,
        sortOrder,
        iconUrl,
      ];
}

class RestaurantMenuItem extends Equatable {
  const RestaurantMenuItem({
    required this.id,
    required this.titleRu,
    required this.titleKk,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.categoryId,
    required this.categoryNameRu,
    required this.categoryNameKk,
    required this.categoryCode,
    required this.categorySortOrder,
    required this.weight,
    required this.composition,
    required this.description,
    required this.isDrink,
    required this.images,
  });

  final String id;
  final String titleRu;
  final String titleKk;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  final String? categoryId;
  final String? categoryNameRu;
  final String? categoryNameKk;
  final String? categoryCode;
  final int? categorySortOrder;
  final String? weight;
  final String? composition;
  final String? description;
  final bool isDrink;
  final List<RestaurantMenuItemImage> images;

  bool get canAddToCart {
    return id.trim().isNotEmpty && isAvailable && price >= 0;
  }

  String get title {
    final ru = titleRu.trim();
    if (ru.isNotEmpty) return ru;

    final kk = titleKk.trim();
    if (kk.isNotEmpty) return kk;

    return 'Товар';
  }

  String get priceText => '$price ₸';

  String get availabilityText {
    return isAvailable ? 'В наличии' : 'Недоступно';
  }

  String get categoryTitle {
    final ru = categoryNameRu?.trim() ?? '';
    if (ru.isNotEmpty) return ru;

    final kk = categoryNameKk?.trim() ?? '';
    if (kk.isNotEmpty) return kk;

    return 'Без категории';
  }

  String? get mainImageUrl {
    if (images.isNotEmpty) {
      final mainImages = images.where((image) => image.isMain).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (mainImages.isNotEmpty) {
        return mainImages.first.url;
      }

      final sortedImages = List<RestaurantMenuItemImage>.from(images)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return sortedImages.first.url;
    }

    return imageUrl;
  }

  String get compactMetaText {
    final parts = <String>[];

    final compositionText = composition?.trim() ?? '';
    final descriptionText = description?.trim() ?? '';
    final weightText = weight?.trim() ?? '';

    if (compositionText.isNotEmpty) {
      parts.add(compositionText);
    } else if (descriptionText.isNotEmpty) {
      parts.add(descriptionText);
    }

    if (weightText.isNotEmpty) {
      parts.add(weightText);
    }

    return parts.join('\n');
  }

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItem(
      id: _readString(json['id']),
      titleRu: _readString(json['titleRu'] ?? json['name']),
      titleKk: _readString(json['titleKk']),
      price: _readInt(json['price']),
      imageUrl: normalizeUrl(json['imageUrl']),
      isAvailable: _readBool(json['isAvailable'], fallback: true),
      categoryId: _readNullableString(json['categoryId']),
      categoryNameRu: _readNullableString(json['categoryNameRu']),
      categoryNameKk: _readNullableString(json['categoryNameKk']),
      categoryCode: _readNullableString(json['categoryCode']),
      categorySortOrder: _readNullableInt(json['categorySortOrder']),
      weight: _readNullableString(json['weight']),
      composition: _readNullableString(json['composition']),
      description: _readNullableString(json['description']),
      isDrink: _readBool(json['isDrink']),
      images: _parseImages(json['images']),
    );
  }

  static List<RestaurantMenuItemImage> _parseImages(dynamic value) {
    return _asList(value)
        .whereType<Map>()
        .map((item) {
          return RestaurantMenuItemImage.fromJson(
            Map<String, dynamic>.from(item),
          );
        })
        .where((image) => image.url.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        if (a.isMain != b.isMain) {
          return a.isMain ? -1 : 1;
        }

        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  @override
  List<Object?> get props => [
        id,
        titleRu,
        titleKk,
        price,
        imageUrl,
        isAvailable,
        categoryId,
        categoryNameRu,
        categoryNameKk,
        categoryCode,
        categorySortOrder,
        weight,
        composition,
        description,
        isDrink,
        images,
      ];
}

class RestaurantMenuItemImage extends Equatable {
  const RestaurantMenuItemImage({
    required this.id,
    required this.url,
    required this.isMain,
    required this.sortOrder,
  });

  final String id;
  final String url;
  final bool isMain;
  final int sortOrder;

  factory RestaurantMenuItemImage.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItemImage(
      id: _readString(json['id']),
      url: normalizeUrl(json['url']) ?? '',
      isMain: _readBool(json['isMain']),
      sortOrder: _readInt(json['sortOrder']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        isMain,
        sortOrder,
      ];
}

class RestaurantMenuGroup extends Equatable {
  const RestaurantMenuGroup({
    required this.category,
    required this.items,
  });

  final RestaurantMenuCategory category;
  final List<RestaurantMenuItem> items;

  bool get isEmpty => items.isEmpty;

  int get availableCount {
    return items.where((item) => item.isAvailable).length;
  }

  @override
  List<Object?> get props => [
        category,
        items,
      ];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }

  return const [];
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return fallback;
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
  if (text.isEmpty) return 0;

  return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return int.tryParse(text) ?? double.tryParse(text)?.round();
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase() ?? '';

  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }

  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }

  return fallback;
}

String? normalizeUrl(dynamic value) {
  final raw = _readNullableString(value);

  if (raw == null) {
    return null;
  }

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  if (raw.startsWith('/')) {
    return '${AppConfig.baseUrl}$raw';
  }

  return '${AppConfig.baseUrl}/$raw';
}
