enum ClientPaymentStatus {
  created,
  pending,
  processing,
  paid,
  failed,
  canceled,
  refundPending,
  refunded,
  unknown,
}

ClientPaymentStatus parseClientPaymentStatus(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'CREATED':
      return ClientPaymentStatus.created;
    case 'PENDING':
      return ClientPaymentStatus.pending;
    case 'PROCESSING':
      return ClientPaymentStatus.processing;
    case 'PAID':
      return ClientPaymentStatus.paid;
    case 'FAILED':
      return ClientPaymentStatus.failed;
    case 'CANCELED':
    case 'CANCELLED':
      return ClientPaymentStatus.canceled;
    case 'REFUND_PENDING':
      return ClientPaymentStatus.refundPending;
    case 'REFUNDED':
      return ClientPaymentStatus.refunded;
    default:
      return ClientPaymentStatus.unknown;
  }
}
