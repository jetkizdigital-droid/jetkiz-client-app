import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';

/// Provider-agnostic saved-card boundary.
///
/// PayLink card-on-file is implemented only through the JETKIZ backend. Flutter
/// never receives provider card tokens and never handles PAN/CVV. New cards are
/// tokenized during a real hosted checkout using the backend `saveCard` option.
abstract interface class PaymentCardProvisioningApi {
  Future<List<SavedPaymentCard>> listCards();

  Future<void> deleteCard(String cardId);

  Future<void> setDefaultCard(String cardId);
}
