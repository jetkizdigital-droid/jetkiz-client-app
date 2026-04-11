/*
  Restaurant domain model for Jetkiz mobile.

  Контекст для будущих сессий ChatGPT:
  - Модель построена по реальному backend ответу:
      GET /restaurants/public/list
  - Ответ backend имеет структуру:
      {
        "pinned": [ ...restaurants ],
        "items": [ ...restaurants ]
      }
  - restaurant.id приходит как UUID string
  - coverImageUrl приходит как относительный путь, например:
      /uploads/restaurants/1773049462082-991858577.jpg
  - Для отображения изображения на клиенте нужен полный URL:
      AppConfig.baseUrl + coverImageUrl
  - address может быть null
  - workingHours может быть null
  - ratingAvg может быть int или double, поэтому приводим к double
*/

import 'package:equatable/equatable.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';

class Restaurant extends Equatable {
  const Restaurant({
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
    required this.isInApp,
    required this.restaurantCommissionPctOverride,
    required this.isPinned,
    required this.sortOrder,
    required this.useRandom,
  });

  final String id;
  final int number;
  final String slug;
  final String nameRu;
  final String nameKk;
  final String phone;
  final String? address;
  final String? workingHours;
  final String? coverImageUrl;
  final double ratingAvg;
  final int ratingCount;
  final String status;
  final bool isInApp;
  final num? restaurantCommissionPctOverride;
  final bool isPinned;
  final int sortOrder;
  final bool useRandom;

  bool get isOpen => status.trim().toUpperCase() == 'OPEN';

  String get displayName {
    final ru = nameRu.trim();
    if (ru.isNotEmpty) return ru;

    final kk = nameKk.trim();
    if (kk.isNotEmpty) return kk;

    return 'Ресторан';
  }

  String? get fullCoverImageUrl => _normalizeImageUrl(coverImageUrl);

  String get subtitle {
    final hours = workingHours?.trim();
    if (hours != null && hours.isNotEmpty) {
      return hours;
    }

    final addr = address?.trim();
    if (addr != null && addr.isNotEmpty) {
      return addr;
    }

    return 'Доставка 30–35 мин';
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: (json['id'] ?? '').toString(),
      number: _readInt(json['number']),
      slug: (json['slug'] ?? '').toString(),
      nameRu: (json['nameRu'] ?? '').toString(),
      nameKk: (json['nameKk'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: _readNullableString(json['address']),
      workingHours: _readNullableString(json['workingHours']),
      coverImageUrl: _readNullableString(json['coverImageUrl']),
      ratingAvg: _readDouble(json['ratingAvg']),
      ratingCount: _readInt(json['ratingCount']),
      status: (json['status'] ?? '').toString(),
      isInApp: json['isInApp'] == true,
      restaurantCommissionPctOverride:
          json['restaurantCommissionPctOverride'] as num?,
      isPinned: json['isPinned'] == true,
      sortOrder: _readInt(json['sortOrder']),
      useRandom: json['useRandom'] == true,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static String? _normalizeImageUrl(String? value) {
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

  @override
  List<Object?> get props => [
        id,
        number,
        slug,
        nameRu,
        nameKk,
        phone,
        address,
        workingHours,
        coverImageUrl,
        ratingAvg,
        ratingCount,
        status,
        isInApp,
        restaurantCommissionPctOverride,
        isPinned,
        sortOrder,
        useRandom,
      ];
}