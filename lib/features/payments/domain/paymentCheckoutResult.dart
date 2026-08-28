class PaymentCheckoutResult {
  const PaymentCheckoutResult({
    required this.orderId,
    required this.paymentId,
    required this.checkoutUrl,
  });

  final String orderId;
  final String paymentId;
  final String checkoutUrl;
}
