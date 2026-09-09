import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnBridge.dart';

void main() {
  group('PaymentReturnBridge', () {
    test('accepts only the canonical JETKIZ payment return URI', () {
      expect(
        PaymentReturnBridge.isPaymentReturnUri(
          Uri.parse('jetkiz://payment/return?result=success'),
        ),
        isTrue,
      );
      expect(
        PaymentReturnBridge.isPaymentReturnUri(
          Uri.parse('jetkiz://payment/return?result=failure'),
        ),
        isTrue,
      );
    });

    test('rejects unrelated or malformed deep links', () {
      expect(
        PaymentReturnBridge.isPaymentReturnUri(
          Uri.parse('https://jetkiz.asia/payment/success'),
        ),
        isFalse,
      );
      expect(
        PaymentReturnBridge.isPaymentReturnUri(
          Uri.parse('jetkiz://orders/return'),
        ),
        isFalse,
      );
      expect(
        PaymentReturnBridge.isPaymentReturnUri(
          Uri.parse('jetkiz://payment/other'),
        ),
        isFalse,
      );
    });
  });
}
