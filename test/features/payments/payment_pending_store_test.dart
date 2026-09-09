import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentPendingStore.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('recovery belongs to current user', () async {
    const storage = FlutterSecureStorage();
    final store = PaymentPendingStore(storage: storage);

    await storage.write(key: 'accessToken', value: _jwtFor('user-a'));
    await store.save(
      const PendingPaymentReference(
        orderId: 'order-a',
        paymentId: 'payment-a',
      ),
    );

    final sameUser = await store.read();
    expect(sameUser?.orderId, 'order-a');
    expect(sameUser?.paymentId, 'payment-a');

    await storage.write(key: 'accessToken', value: _jwtFor('user-b'));

    final otherUser = await store.read();
    expect(otherUser, isNull);
    expect(await storage.read(key: 'payment_pending_order_id'), isNull);
    expect(await storage.read(key: 'payment_pending_payment_id'), isNull);
    expect(await storage.read(key: 'payment_pending_user_id'), isNull);
  });

  test('legacy recovery is discarded', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'accessToken': _jwtFor('user-b'),
      'payment_pending_order_id': 'legacy-order',
      'payment_pending_payment_id': 'legacy-payment',
    });

    const storage = FlutterSecureStorage();
    final store = PaymentPendingStore(storage: storage);

    expect(await store.read(), isNull);
    expect(await storage.read(key: 'payment_pending_order_id'), isNull);
    expect(await storage.read(key: 'payment_pending_payment_id'), isNull);
  });

  test('logout clears payment recovery', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'accessToken': _jwtFor('user-a'),
      'refreshToken': 'refresh-a',
      'payment_pending_order_id': 'order-a',
      'payment_pending_payment_id': 'payment-a',
      'payment_pending_user_id': 'user-a',
      'payment_pending_checkout_url': 'https://legacy.invalid',
    });

    const storage = FlutterSecureStorage();
    await AuthStorage().clear();

    expect(await storage.read(key: 'accessToken'), isNull);
    expect(await storage.read(key: 'refreshToken'), isNull);
    expect(await storage.read(key: 'payment_pending_order_id'), isNull);
    expect(await storage.read(key: 'payment_pending_payment_id'), isNull);
    expect(await storage.read(key: 'payment_pending_user_id'), isNull);
    expect(await storage.read(key: 'payment_pending_checkout_url'), isNull);
  });
}

String _jwtFor(String userId) {
  final headerJson = jsonEncode({'alg': 'none', 'typ': 'JWT'});
  final payloadJson = jsonEncode({'sub': userId});
  final headerBytes = utf8.encode(headerJson);
  final payloadBytes = utf8.encode(payloadJson);
  final header = base64Url.encode(headerBytes).replaceAll('=', '');
  final payload = base64Url.encode(payloadBytes).replaceAll('=', '');
  return '$header.$payload.signature';
}
