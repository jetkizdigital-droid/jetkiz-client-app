class PaymentProviderCapabilities {
  const PaymentProviderCapabilities({
    required this.supportsHostedCheckout,
    required this.supportsSavedCards,
    required this.supportsSetDefaultCard,
    required this.supportsDeleteCard,
  });

  final bool supportsHostedCheckout;
  final bool supportsSavedCards;
  final bool supportsSetDefaultCard;
  final bool supportsDeleteCard;

  static const pendingProviderConfirmation = PaymentProviderCapabilities(
    supportsHostedCheckout: false,
    supportsSavedCards: false,
    supportsSetDefaultCard: false,
    supportsDeleteCard: false,
  );
}
