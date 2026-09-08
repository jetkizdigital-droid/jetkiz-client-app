enum PaymentCardBrand {
  visa,
  mastercard,
  unknown,
}

class SavedPaymentCard {
  const SavedPaymentCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.provider,
    this.issuerBank,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
  });

  final String id;
  final String last4;
  final PaymentCardBrand brand;
  final String provider;
  final String? issuerBank;

  /// Kept optional for forward compatibility. The current PayLink backend
  /// intentionally exposes only display-safe metadata returned by the provider.
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;

  String get maskedNumber => '•••• $last4';

  String get brandLabel {
    switch (brand) {
      case PaymentCardBrand.visa:
        return 'Visa';
      case PaymentCardBrand.mastercard:
        return 'Mastercard';
      case PaymentCardBrand.unknown:
        return 'Карта';
    }
  }

  String? get expiryLabel {
    final month = expiryMonth;
    final year = expiryYear;
    if (month == null || year == null) return null;

    final normalizedYear = year % 100;
    return '${month.toString().padLeft(2, '0')}/${normalizedYear.toString().padLeft(2, '0')}';
  }

  factory SavedPaymentCard.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final last4 = json['last4']?.toString().trim() ?? '';
    final provider = json['provider']?.toString().trim() ?? '';

    if (id.isEmpty || !RegExp(r'^\d{4}$').hasMatch(last4) || provider.isEmpty) {
      throw const FormatException('Invalid saved payment method payload');
    }

    return SavedPaymentCard(
      id: id,
      last4: last4,
      brand: parsePaymentCardBrand(json['brand']?.toString()),
      provider: provider,
      issuerBank: _readNullableString(json['issuerBank']),
      expiryMonth: _readNullableInt(json['expiryMonth']),
      expiryYear: _readNullableInt(json['expiryYear']),
      isDefault: json['isDefault'] == true,
    );
  }

  static String? _readNullableString(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty || normalized.toLowerCase() == 'null'
        ? null
        : normalized;
  }

  static int? _readNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

PaymentCardBrand parsePaymentCardBrand(String? raw) {
  final normalized =
      raw?.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  switch (normalized) {
    case 'VISA':
      return PaymentCardBrand.visa;
    case 'MASTERCARD':
    case 'MAESTRO':
      return PaymentCardBrand.mastercard;
    default:
      return PaymentCardBrand.unknown;
  }
}
