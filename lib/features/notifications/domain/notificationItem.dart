import 'package:jetkiz_mobile/core/localization/localizedValue.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  String? get orderId => data?['orderId']?.toString();

  int? get orderNumber {
    final raw = data?['orderNumber'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String? get status => data?['status']?.toString();

  String get displayTitle {
    final ru = _localizedDataString('titleRu') ?? title;
    final kk = _localizedDataString('titleKk') ?? _legacyKkTitle();
    return LocalizedValue.select(ru: ru, kk: kk, fallback: ru);
  }

  String get displayBody {
    final ru = _localizedDataString('bodyRu') ?? body;
    final kk = _localizedDataString('bodyKk') ?? _legacyKkBody();
    return LocalizedValue.select(ru: ru, kk: kk, fallback: ru);
  }

  String? _localizedDataString(String key) {
    final value = data?[key]?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? _legacyKkTitle() {
    final normalizedStatus = status?.trim().toUpperCase() ?? '';
    final normalizedType = type.trim().toUpperCase();

    switch (normalizedStatus) {
      case 'CREATED':
        return 'Тапсырыс жасалды';
      case 'ACCEPTED':
        return 'Тапсырыс қабылданды';
      case 'COOKING':
        return 'Дайындалып жатыр';
      case 'READY':
        return 'Дайын';
      case 'ON_THE_WAY':
        return 'Жолда';
      case 'DELIVERED':
        return 'Жеткізілді';
      case 'REJECTED':
        return 'Қабылданбады';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Тоқтатылды';
    }

    switch (normalizedType) {
      case 'ORDER_CREATED':
        return 'Тапсырыс жасалды';
      case 'ORDER_ACCEPTED':
        return 'Тапсырыс қабылданды';
      case 'ORDER_COOKING':
        return 'Дайындалып жатыр';
      case 'ORDER_READY':
        return 'Дайын';
      case 'ORDER_ON_THE_WAY':
        return 'Жолда';
      case 'ORDER_DELIVERED':
        return 'Жеткізілді';
      case 'ORDER_CANCELED':
      case 'ORDER_CANCELLED':
        return 'Тоқтатылды';
      default:
        return null;
    }
  }

  String? _legacyKkBody() {
    final number = orderNumber;
    if (number == null) {
      return null;
    }

    final normalizedStatus = status?.trim().toUpperCase() ?? '';
    final normalizedType = type.trim().toUpperCase();

    switch (normalizedStatus) {
      case 'CREATED':
        return '№$number тапсырыс жасалды';
      case 'ACCEPTED':
        return 'Мейрамхана №$number тапсырысты қабылдады';
      case 'COOKING':
        return '№$number тапсырыс дайындалып жатыр';
      case 'READY':
        return '№$number тапсырыс дайын';
      case 'ON_THE_WAY':
        return 'Курьер №$number тапсырысты жеткізіп келеді';
      case 'DELIVERED':
        return '№$number тапсырыс жеткізілді';
      case 'REJECTED':
        return 'Мейрамхана №$number тапсырысты қабылдамады';
      case 'CANCELED':
      case 'CANCELLED':
        return '№$number тапсырыс тоқтатылды';
    }

    switch (normalizedType) {
      case 'ORDER_CREATED':
        return '№$number тапсырыс жасалды';
      case 'ORDER_ACCEPTED':
        return 'Мейрамхана №$number тапсырысты қабылдады';
      case 'ORDER_COOKING':
        return '№$number тапсырыс дайындалып жатыр';
      case 'ORDER_READY':
        return '№$number тапсырыс дайын';
      case 'ORDER_ON_THE_WAY':
        return 'Курьер №$number тапсырысты жеткізіп келеді';
      case 'ORDER_DELIVERED':
        return '№$number тапсырыс жеткізілді';
      case 'ORDER_CANCELED':
      case 'ORDER_CANCELLED':
        return '№$number тапсырыс тоқтатылды';
      default:
        return null;
    }
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      isRead: json['isRead'] == true,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      readAt: _parseDateTime(json['readAt']),
      data: _readMap(json['data']),
    );
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
}

class NotificationsPageData {
  const NotificationsPageData({
    required this.items,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int unreadCount;

  factory NotificationsPageData.fromJson(Map<String, dynamic> json) {
    final itemsRaw = _extractList(json, const ['items']) ??
        _extractList(json, const ['data', 'items']) ??
        _extractList(json, const ['result', 'items']) ??
        const [];

    final unreadCount = _parseInt(json['unreadCount']) ??
        _parseInt((json['meta'] is Map ? json['meta']['unreadCount'] : null)) ??
        itemsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['isRead'] != true)
            .length;

    return NotificationsPageData(
      items: itemsRaw
          .whereType<Map>()
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      unreadCount: unreadCount,
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

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
