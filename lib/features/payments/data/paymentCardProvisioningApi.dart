import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';

/// Boundary reserved for provider-backed card tokenization/card-on-file.
///
/// This is deliberately not connected to any guessed PayLink endpoint.
/// The implementation must only be added after provider documentation is
/// confirmed.
abstract interface class PaymentCardProvisioningApi {
  Future<List<SavedPaymentCard>> listCards();

  Future<void> deleteCard(String cardId);

  Future<void> setDefaultCard(String cardId);
}
