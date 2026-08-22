class UpdateProfileDto {
  const UpdateProfileDto({
    required this.firstName,
    this.lastName,
    this.email,
  });

  final String firstName;
  final String? lastName;
  final String? email;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': _normalizeNullable(lastName),
      'email': _normalizeNullable(email),
    };
  }

  static String? _normalizeNullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  UpdateProfileDto copyWith({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return UpdateProfileDto(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}
