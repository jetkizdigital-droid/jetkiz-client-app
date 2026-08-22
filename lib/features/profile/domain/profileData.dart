import 'package:equatable/equatable.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';

class ProfileData extends Equatable {
  const ProfileData({
    required this.id,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarUrl,
    required this.name,
    required this.restaurantId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String phone;
  final String? role;
  final bool isActive;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatarUrl;
  final String? name;
  final String? restaurantId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: _readString(json['id']),
      phone: _readString(json['phone']),
      role: _readNullableString(json['role']),
      isActive: json['isActive'] != false,
      firstName: _readNullableString(json['firstName']),
      lastName: _readNullableString(json['lastName']),
      email: _readNullableString(json['email']),
      avatarUrl: _readNullableString(json['avatarUrl']),
      name: _readNullableString(json['name']),
      restaurantId: _readNullableString(json['restaurantId']),
      createdAt: DateTime.tryParse(_readString(json['createdAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(_readString(json['updatedAt'])),
    );
  }

  String? get resolvedAvatarUrl {
    final raw = avatarUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = AppConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';

    return '$base$path';
  }

  String get fullName {
    final parts = <String>[
      firstName?.trim() ?? '',
      lastName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    return parts.join(' ').trim();
  }

  String get displayTitle {
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }

    return 'Клиент Jetkiz';
  }

  String get displaySubtitle {
    final trimmedPhone = phone.trim();
    return trimmedPhone.isEmpty ? 'Профиль клиента' : trimmedPhone;
  }

  ProfileData copyWith({
    String? id,
    String? phone,
    String? role,
    bool? isActive,
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    String? name,
    String? restaurantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileData(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      name: name ?? this.name,
      restaurantId: restaurantId ?? this.restaurantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        role,
        isActive,
        firstName,
        lastName,
        email,
        avatarUrl,
        name,
        restaurantId,
        createdAt,
        updatedAt,
      ];
}
