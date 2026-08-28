/// Non-sensitive client contract expected from a future payment provider
/// integration. Exact fields may be adjusted after PayLink documentation is
/// confirmed.
class PaymentProviderContract {
  const PaymentProviderContract({
    required this.checkoutMode,
    required this.savedCardsMode,
    required this.returnUrlMode,
  });

  final PaymentCheckoutMode checkoutMode;
  final SavedCardsMode savedCardsMode;
  final PaymentReturnUrlMode returnUrlMode;
}

enum PaymentCheckoutMode {
  unknown,
  hostedPage,
  nativeSdk,
}

enum SavedCardsMode {
  unknown,
  unsupported,
  providerTokenization,
}

enum PaymentReturnUrlMode {
  unknown,
  verifiedAppLink,
  customScheme,
}
