import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';

/// Persists only the minimum non-sensitive reference needed to recover an
/// interrupted checkout.
///
/// Recovery state is bound to the authenticated JETKIZ user. A pending payment
/// from one account must never block or resume checkout after another account
/// signs in on the same device.
///
/// Hosted checkout URLs may contain provider session context and are deliberately
/// not persisted; they are re-read from backend.
class PaymentPendingStore {
  PaymentPendingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _orderIdKey = 'payment_pending_order_id';
  static const _paymentIdKey = 'payment_pending_payment_id';
  static const _ownerUserIdKey = 'payment_pending_user_id';
  static const _accessTokenKey = 'accessToken';

  // Legacy key from the pre-production foundation. Always delete it.
  static const _legacyCheckoutUrlKey = 'payment_pending_checkout_url';

  final FlutterSecureStorage _storage;

  Future<void> save(PendingPaymentReference reference) async {
    final orderId = reference.orderId.trim();
    if (orderId.isEmpty) {
      throw ArgumentError.value(reference.orderId, 'orderId', 'must not be empty');
    }

    final ownerUserId = await _currentUserId();
    if (ownerUserId == null) {
      // Never create device-global payment recovery state. If authentication is
      // unavailable, checkout recovery is safer disabled than shared across
      // accounts.
      await clear();
      throw StateError('Cannot persist payment recovery without authenticated user');
    }

    await _storage.write(key: _orderIdKey, value: orderId);
    await _writeNullable(_paymentIdKey, reference.paymentId);
    await _storage.write(key: _ownerUserIdKey, value: ownerUserId);
    await _storage.delete(key: _legacyCheckoutUrlKey);
  }

  Future<PendingPaymentReference?> read() async {
    final orderId = (await _storage.read(key: _orderIdKey))?.trim() ?? '';
    if (orderId.isEmpty) {
      await _storage.delete(key: _legacyCheckoutUrlKey);
      await _storage.delete(key: _ownerUserIdKey);
      return null;
    }

    final storedOwner =
        (await _storage.read(key: _ownerUserIdKey))?.trim() ?? '';
    final currentOwner = await _currentUserId();

    // Records created before user-scoped recovery was introduced have no owner.
    // They are intentionally discarded instead of being guessed to belong to
    // whoever happens to be signed in now.
    if (storedOwner.isEmpty || currentOwner == null || storedOwner != currentOwner) {
      await clear();
      return null;
    }

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
      _storage.delete(key: _ownerUserIdKey),
      _storage.delete(key: _legacyCheckoutUrlKey),
    ]);
  }

  Future<String?> _currentUserId() async {
    final token = (await _storage.read(key: _accessTokenKey))?.trim() ?? '';
    if (token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map) return null;

      final sub = payload['sub']?.toString().trim() ?? '';
      return sub.isEmpty ? null : sub;
    } catch (_) {
      return null;
    }
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
