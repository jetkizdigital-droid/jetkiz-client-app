/*
  Restaurant domain model for Jetkiz mobile.

  Backend public contract:
  - GET /restaurants/public/list
  - GET /restaurants/public/all

  Real backend fields:
  id, number, slug, nameRu, nameKk, phone, address, workingHours,
  coverImageUrl, ratingAvg, ratingCount, status, isInApp,
  restaurantCommissionPctOverride, isPinned, sortOrder, useRandom.

  Do not require logo/banner/deliveryFee/minOrderAmount.
  They are optional/future fields.
*/

import 'package:equatable/equatable.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurantAvailability.dart';

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
    required this.descriptionRu,
    required this.descriptionKk,
    required this.coverImageUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.status,
    required this.isInApp,
    required this.isAcceptingOrders,
    required this.isPinned,
    required this.sortOrder,
    required this.useRandom,
    required this.restaurantCommissionPctOverride,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.isPickupEnabled,
    required this.pickupPreparationMinutes,
  });

  final String id;
  final int number;
  final String slug;

  final String nameRu;
  final String nameKk;

  final String? phone;
  final String? address;
  final String? workingHours;

  final String? descriptionRu;
  final String? descriptionKk;

  final String? coverImageUrl;

  final double ratingAvg;
  final int ratingCount;

  final String status;
  final bool isInApp;
  final bool isAcceptingOrders;

  final bool isPinned;
  final int sortOrder;
  final bool useRandom;

  final num? restaurantCommissionPctOverride;

  /// Future-safe optional fields. Current backend may not return them.
  final int? deliveryFee;
  final int? minOrderAmount;
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

  bool get hasRating {
    return ratingAvg > 0 && ratingCount > 0;
  }

  String get displayName {
    final ru = nameRu.trim();
    if (ru.isNotEmpty) return ru;

    final kk = nameKk.trim();
    if (kk.isNotEmpty) return kk;

    final slugValue = slug.trim();
    if (slugValue.isNotEmpty) return slugValue;

    return 'Ресторан';
  }

  String get displayDescription {
    final ru = descriptionRu?.trim() ?? '';
    if (ru.isNotEmpty) return ru;

    final kk = descriptionKk?.trim() ?? '';
    if (kk.isNotEmpty) return kk;

    final addr = address?.trim() ?? '';
    if (addr.isNotEmpty) return addr;

    return 'Доставка еды';
  }

  String get statusText {
    return availability.label;
  }

  String get ratingText {
    if (!hasRating) return '—';
    return ratingAvg.toStringAsFixed(ratingAvg % 1 == 0 ? 0 : 1);
  }

  String get reviewsText {
    if (ratingCount <= 0) return 'Нет отзывов';
    return '$ratingCount отзывов';
  }

  String get subtitle {
    final hours = workingHours?.trim();
    if (hours != null && hours.isNotEmpty) {
      return hours;
    }

    final addr = address?.trim();
    if (addr != null && addr.isNotEmpty) {
      return addr;
    }

    return isOpen ? 'Доставка 30–35 мин' : availability.reason;
  }

  String? get fullCoverImageUrl => normalizeImageUrl(coverImageUrl);

  String? get formattedDeliveryFee {
    final fee = deliveryFee;

    if (fee == null) return null;
    if (fee <= 0) return 'Бесплатно';

    return '$fee ₸';
  }

  String? get formattedMinOrderAmount {
    final amount = minOrderAmount;

    if (amount == null || amount <= 0) return null;

    return 'Мин. заказ $amount ₸';
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: _readString(json['id']),
      number: _readInt(json['number']),
      slug: _readString(json['slug']),
      nameRu: _readString(json['nameRu'] ?? json['name']),
      nameKk: _readString(json['nameKk']),
      phone: _readNullableString(json['phone']),
      address: _readNullableString(json['address']),
      workingHours: _readNullableString(json['workingHours']),
      descriptionRu: _readNullableString(json['descriptionRu']),
      descriptionKk: _readNullableString(json['descriptionKk']),
      coverImageUrl: _readNullableString(
        json['coverImageUrl'] ??
            json['imageUrl'] ??
            json['image'] ??
            json['banner'] ??
            json['logo'],
      ),
      ratingAvg: _readDouble(json['ratingAvg']),
      ratingCount: _readInt(json['ratingCount']),
      status: _readString(json['status'], fallback: 'CLOSED'),
      isInApp: _readBool(json['isInApp'], fallback: true),
      isAcceptingOrders: _readBool(
        json['isAcceptingOrders'],
        fallback: false,
      ),
      isPinned: _readBool(json['isPinned']),
      sortOrder: _readInt(json['sortOrder']),
      useRandom: _readBool(json['useRandom']),
      restaurantCommissionPctOverride:
          _readNullableNum(json['restaurantCommissionPctOverride']),
      deliveryFee: _readNullableInt(
        json['deliveryFee'] ??
            json['deliveryBaseFee'] ??
            json['baseDeliveryFee'],
      ),
      minOrderAmount: _readNullableInt(json['minOrderAmount']),
      isPickupEnabled: _readBool(json['isPickupEnabled'], fallback: true),
      pickupPreparationMinutes:
          _readNullableInt(json['pickupPreparationMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'slug': slug,
      'nameRu': nameRu,
      'nameKk': nameKk,
      'phone': phone,
      'address': address,
      'workingHours': workingHours,
      'descriptionRu': descriptionRu,
      'descriptionKk': descriptionKk,
      'coverImageUrl': coverImageUrl,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'status': status,
      'isInApp': isInApp,
      'isAcceptingOrders': isAcceptingOrders,
      'isPinned': isPinned,
      'sortOrder': sortOrder,
      'useRandom': useRandom,
      'restaurantCommissionPctOverride': restaurantCommissionPctOverride,
      'deliveryFee': deliveryFee,
      'minOrderAmount': minOrderAmount,
      'isPickupEnabled': isPickupEnabled,
      'pickupPreparationMinutes': pickupPreparationMinutes,
    };
  }

  Restaurant copyWith({
    String? id,
    int? number,
    String? slug,
    String? nameRu,
    String? nameKk,
    String? phone,
    String? address,
    String? workingHours,
    String? descriptionRu,
    String? descriptionKk,
    String? coverImageUrl,
    double? ratingAvg,
    int? ratingCount,
    String? status,
    bool? isInApp,
    bool? isAcceptingOrders,
    bool? isPinned,
    int? sortOrder,
    bool? useRandom,
    num? restaurantCommissionPctOverride,
    int? deliveryFee,
    int? minOrderAmount,
    bool? isPickupEnabled,
    int? pickupPreparationMinutes,
  }) {
    return Restaurant(
      id: id ?? this.id,
      number: number ?? this.number,
      slug: slug ?? this.slug,
      nameRu: nameRu ?? this.nameRu,
      nameKk: nameKk ?? this.nameKk,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      workingHours: workingHours ?? this.workingHours,
      descriptionRu: descriptionRu ?? this.descriptionRu,
      descriptionKk: descriptionKk ?? this.descriptionKk,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      status: status ?? this.status,
      isInApp: isInApp ?? this.isInApp,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      useRandom: useRandom ?? this.useRandom,
      restaurantCommissionPctOverride: restaurantCommissionPctOverride ??
          this.restaurantCommissionPctOverride,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      isPickupEnabled: isPickupEnabled ?? this.isPickupEnabled,
      pickupPreparationMinutes:
          pickupPreparationMinutes ?? this.pickupPreparationMinutes,
    );
  }

  static String? normalizeImageUrl(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
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

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 0;

    return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return int.tryParse(text) ?? double.tryParse(text)?.round();
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 0;

    return double.tryParse(text) ?? 0;
  }

  static num? _readNullableNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return num.tryParse(text);
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
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
        descriptionRu,
        descriptionKk,
        coverImageUrl,
        ratingAvg,
        ratingCount,
        status,
        isInApp,
        isAcceptingOrders,
        isPinned,
        sortOrder,
        useRandom,
        restaurantCommissionPctOverride,
        deliveryFee,
        minOrderAmount,
        isPickupEnabled,
        pickupPreparationMinutes,
      ];
}
