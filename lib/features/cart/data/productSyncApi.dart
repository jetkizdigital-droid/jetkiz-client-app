import 'package:jetkiz_mobile/core/network/apiClient.dart';

abstract class ProductSyncClient {
  Future<List<ProductSyncItem>> syncProducts(List<String> productIds);
}

typedef ProductSyncTransport = Future<dynamic> Function(
    List<String> productIds);

class ProductSyncApi implements ProductSyncClient {
  ProductSyncApi(
    this._apiClient, {
    ProductSyncTransport? transport,
  }) : _transport = transport;

  static const int batchLimit = 50;

  final ApiClient _apiClient;
  final ProductSyncTransport? _transport;

  @override
  Future<List<ProductSyncItem>> syncProducts(List<String> productIds) async {
    final ids = _dedupeProductIds(productIds);
    if (ids.isEmpty) return const <ProductSyncItem>[];

    final results = <ProductSyncItem>[];

    for (var start = 0; start < ids.length; start += batchLimit) {
      final end =
          start + batchLimit > ids.length ? ids.length : start + batchLimit;
      final batch = ids.sublist(start, end);

      final data = await _postBatch(batch);

      for (final item in _readItems(data)) {
        results.add(
          ProductSyncItem.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }

    return results;
  }

  Future<dynamic> _postBatch(List<String> batch) async {
    final transport = _transport;
    if (transport != null) {
      return transport(batch);
    }

    final response = await _apiClient.dio.post<dynamic>(
      '/products/sync',
      data: {
        'productIds': batch,
      },
    );

    return response.data;
  }

  static List<String> _dedupeProductIds(List<String> productIds) {
    final seen = <String>{};
    final result = <String>[];

    for (final raw in productIds) {
      final id = raw.trim();
      if (id.isEmpty || seen.contains(id)) continue;

      seen.add(id);
      result.add(id);
    }

    return result;
  }

  static List<Map> _readItems(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().toList();
    }

    if (data is Map) {
      for (final key in const ['items', 'products', 'data']) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map>().toList();
        }
      }
    }

    return const <Map>[];
  }
}

enum ProductSyncState {
  ok,
  unavailable,
  notFound,
}

class ProductSyncItem {
  const ProductSyncItem({
    required this.id,
    required this.exists,
    required this.state,
    required this.price,
    required this.isAvailable,
    required this.restaurantId,
    required this.titleRu,
    required this.titleKk,
    required this.effectiveImageUrl,
    required this.restaurant,
  });

  final String id;
  final bool exists;
  final ProductSyncState state;
  final int? price;
  final bool isAvailable;
  final String? restaurantId;
  final String? titleRu;
  final String? titleKk;
  final String? effectiveImageUrl;
  final ProductSyncRestaurant? restaurant;

  factory ProductSyncItem.fromJson(Map<String, dynamic> json) {
    final exists = _readBool(json['exists']);
    final state = _readState(json['state'], exists: exists);

    return ProductSyncItem(
      id: _readString(json['id']),
      exists: exists,
      state: state,
      price: _readNullableInt(json['price']),
      isAvailable: _readBool(json['isAvailable'],
          fallback: state == ProductSyncState.ok),
      restaurantId: _readNullableString(json['restaurantId']),
      titleRu: _readNullableString(json['titleRu']),
      titleKk: _readNullableString(json['titleKk']),
      effectiveImageUrl: _readNullableString(json['effectiveImageUrl']),
      restaurant: json['restaurant'] is Map
          ? ProductSyncRestaurant.fromJson(
              Map<String, dynamic>.from(json['restaurant'] as Map),
            )
          : null,
    );
  }
}

class ProductSyncRestaurant {
  const ProductSyncRestaurant({
    required this.id,
    required this.status,
    required this.isInApp,
    required this.isAcceptingOrders,
  });

  final String id;
  final String status;
  final bool isInApp;
  final bool isAcceptingOrders;

  factory ProductSyncRestaurant.fromJson(Map<String, dynamic> json) {
    return ProductSyncRestaurant(
      id: _readString(json['id']),
      status: _readString(json['status'], fallback: 'CLOSED'),
      isInApp: _readBool(json['isInApp']),
      isAcceptingOrders: _readBool(json['isAcceptingOrders']),
    );
  }
}

ProductSyncState _readState(dynamic value, {required bool exists}) {
  if (!exists) return ProductSyncState.notFound;

  final text = value?.toString().trim().toUpperCase() ?? '';

  switch (text) {
    case 'OK':
      return ProductSyncState.ok;
    case 'UNAVAILABLE':
      return ProductSyncState.unavailable;
    case 'NOT_FOUND':
    case 'NOTFOUND':
      return ProductSyncState.notFound;
    default:
      return ProductSyncState.unavailable;
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

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  return int.tryParse(text) ?? double.tryParse(text)?.round();
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase() ?? '';
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;

  return fallback;
}
