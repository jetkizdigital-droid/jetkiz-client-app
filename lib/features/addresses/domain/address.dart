/// Jetkiz mobile context:
/// Address — сохранённый адрес клиента.
///
/// Backend contract:
/// - GET /addresses/my
/// - POST /addresses
/// - PUT /addresses/:id
/// - DELETE /addresses/:id
///
/// Address belongs to current authenticated user.
/// In checkout flow order must use addressId of selected saved address.
class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.floor,
    required this.door,
    required this.entrance,
    required this.intercom,
    required this.contactPhone,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String address;
  final String? floor;
  final String? door;
  final String? entrance;
  final String? intercom;
  final String? contactPhone;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: _readString(json['id']),
      userId: _readString(json['userId']),
      title: _readString(json['title'], fallback: 'Адрес'),
      address: _readString(json['address']),
      floor: _readNullableString(json['floor']),
      door: _readNullableString(json['door']),
      entrance: _readNullableString(json['entrance']),
      intercom: _readNullableString(json['intercom']),
      contactPhone: _readNullableString(json['contactPhone']),
      comment: _readNullableString(json['comment']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  bool get isValid => id.trim().isNotEmpty && address.trim().isNotEmpty;

  String get displayTitle {
    final value = title.trim();
    return value.isEmpty ? 'Адрес' : value;
  }

  String get shortDetails {
    final parts = <String>[
      if (_hasText(entrance)) 'Подъезд ${entrance!.trim()}',
      if (_hasText(floor)) 'Этаж ${floor!.trim()}',
      if (_hasText(door)) 'Кв./офис ${door!.trim()}',
    ];

    return parts.join(' • ');
  }

  String get fullSubtitle {
    final parts = <String>[
      address.trim(),
      if (_hasText(entrance)) 'Подъезд ${entrance!.trim()}',
      if (_hasText(floor)) 'Этаж ${floor!.trim()}',
      if (_hasText(door)) 'Кв./офис ${door!.trim()}',
      if (_hasText(intercom)) 'Домофон ${intercom!.trim()}',
      if (_hasText(contactPhone)) 'Телефон ${contactPhone!.trim()}',
      if (_hasText(comment)) comment!.trim(),
    ];

    return parts.where((item) => item.trim().isNotEmpty).join(' • ');
  }

  Address copyWith({
    String? id,
    String? userId,
    String? title,
    String? address,
    String? floor,
    String? door,
    String? entrance,
    String? intercom,
    String? contactPhone,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      address: address ?? this.address,
      floor: floor ?? this.floor,
      door: door ?? this.door,
      entrance: entrance ?? this.entrance,
      intercom: intercom ?? this.intercom,
      contactPhone: contactPhone ?? this.contactPhone,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'address': address,
      'floor': floor,
      'door': door,
      'entrance': entrance,
      'intercom': intercom,
      'contactPhone': contactPhone,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime _readDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
