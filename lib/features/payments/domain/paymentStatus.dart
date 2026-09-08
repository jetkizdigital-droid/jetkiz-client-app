enum ClientPaymentStatus {
  created,
  pending,
  processing,
  authorized,
  capturePending,
  paid,
  voidPending,
  voided,
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
    case 'AUTHORIZED':
      return ClientPaymentStatus.authorized;
    case 'CAPTURE_PENDING':
      return ClientPaymentStatus.capturePending;
    case 'PAID':
      return ClientPaymentStatus.paid;
    case 'VOID_PENDING':
      return ClientPaymentStatus.voidPending;
    case 'VOIDED':
      return ClientPaymentStatus.voided;
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

bool isFundsSecuredPaymentStatus(ClientPaymentStatus status) {
  return status == ClientPaymentStatus.authorized ||
      status == ClientPaymentStatus.capturePending ||
      status == ClientPaymentStatus.paid;
}
