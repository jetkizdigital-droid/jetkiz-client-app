import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';

/// Persists only the minimum non-sensitive reference needed to recover an
/// interrupted checkout. Hosted checkout URLs may contain provider session
/// context and are deliberately not persisted; they are re-read from backend.
class PaymentPendingStore {
  PaymentPendingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _orderIdKey = 'payment_pending_order_id';
  static const _paymentIdKey = 'payment_pending_payment_id';

  // Legacy key from the pre-production foundation. Always delete it.
  static const _legacyCheckoutUrlKey = 'payment_pending_checkout_url';

  final FlutterSecureStorage _storage;

  Future<void> save(PendingPaymentReference reference) async {
    await _storage.write(key: _orderIdKey, value: reference.orderId.trim());
    await _writeNullable(_paymentIdKey, reference.paymentId);
    await _storage.delete(key: _legacyCheckoutUrlKey);
  }

  Future<PendingPaymentReference?> read() async {
    final orderId = (await _storage.read(key: _orderIdKey))?.trim() ?? '';
    if (orderId.isEmpty) return null;

    await _storage.delete(key: _legacyCheckoutUrlKey);

    return PendingPaymentReference(
      orderId: orderId,
      paymentId: await _storage.read(key: _paymentIdKey),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _orderIdKey),
      _storage.delete(key: _paymentIdKey),
      _storage.delete(key: _legacyCheckoutUrlKey),
    ]);
  }

  Future<void> _writeNullable(String key, String? value) async {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: normalized);
  }
}
