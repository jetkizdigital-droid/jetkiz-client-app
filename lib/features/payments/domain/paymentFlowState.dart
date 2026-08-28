enum PaymentFlowStage {
  idle,
  creatingOrder,
  creatingPayment,
  waitingForPayment,
  verifyingPayment,
  paid,
  failed,
  canceled,
  unknown,
}

class PendingPaymentReference {
  const PendingPaymentReference({
    required this.orderId,
    this.paymentId,
    this.checkoutUrl,
  });

  final String orderId;
  final String? paymentId;
  final String? checkoutUrl;
}
