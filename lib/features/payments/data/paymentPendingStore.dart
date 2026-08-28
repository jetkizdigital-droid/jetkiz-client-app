import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';

class PaymentPendingStore {
  PaymentPendingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _orderIdKey = 'payment_pending_order_id';
  static const _paymentIdKey = 'payment_pending_payment_id';
  static const _checkoutUrlKey = 'payment_pending_checkout_url';

  final FlutterSecureStorage _storage;

  Future<void> save(PendingPaymentReference reference) async {
    await _storage.write(key: _orderIdKey, value: reference.orderId);
    await _writeNullable(_paymentIdKey, reference.paymentId);
    await _writeNullable(_checkoutUrlKey, reference.checkoutUrl);
  }

  Future<PendingPaymentReference?> read() async {
    final orderId = (await _storage.read(key: _orderIdKey))?.trim() ?? '';
    if (orderId.isEmpty) return null;

    return PendingPaymentReference(
      orderId: orderId,
      paymentId: await _storage.read(key: _paymentIdKey),
      checkoutUrl: await _storage.read(key: _checkoutUrlKey),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _orderIdKey),
      _storage.delete(key: _paymentIdKey),
      _storage.delete(key: _checkoutUrlKey),
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
