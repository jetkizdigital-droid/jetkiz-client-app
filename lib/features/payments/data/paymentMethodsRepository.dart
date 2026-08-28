import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';

/// Client-side façade for saved payment methods.
///
/// The payment provider contract is intentionally not implemented yet.
/// Once PayLink confirms card tokenization/card-on-file capabilities, this
/// repository becomes the single place that talks to JETKIZ backend payment
/// method endpoints. Card PAN/CVV must never be stored in Flutter.
class PaymentMethodsRepository {
  PaymentMethodsRepository._();

  static final PaymentMethodsRepository instance = PaymentMethodsRepository._();

  Future<List<SavedPaymentCard>> getSavedCards() async {
    return const <SavedPaymentCard>[];
  }

  Future<void> setDefaultCard(String cardId) async {
    throw const PaymentMethodsUnavailableException();
  }

  Future<void> deleteCard(String cardId) async {
    throw const PaymentMethodsUnavailableException();
  }
}

class PaymentMethodsUnavailableException implements Exception {
  const PaymentMethodsUnavailableException();
}
