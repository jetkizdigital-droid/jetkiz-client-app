abstract final class PaymentSecurityRules {
  static const bool storeFullPan = false;
  static const bool storeCvv = false;
  static const bool trustClientReturnAsPaid = false;
  static const bool exposeProviderSecretInClient = false;
}
