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
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
  });

  final String id;
  final String last4;
  final PaymentCardBrand brand;
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
}
