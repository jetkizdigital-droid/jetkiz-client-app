enum ClientPaymentMethodType {
  bankCard,
}

class PaymentMethodSelection {
  const PaymentMethodSelection.bankCard()
      : type = ClientPaymentMethodType.bankCard,
        savedCardId = null;

  const PaymentMethodSelection.savedCard(String cardId)
      : type = ClientPaymentMethodType.bankCard,
        savedCardId = cardId;

  final ClientPaymentMethodType type;
  final String? savedCardId;
}
