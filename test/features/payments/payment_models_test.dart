import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentStatus.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';

void main() {
  group('PaymentCheckoutSession', () {
    test('accepts a normal HTTPS hosted checkout URL', () {
      final session = PaymentCheckoutSession.fromJson({
        'paymentId': 'payment-1',
        'orderId': 'order-1',
        'status': 'PENDING',
        'checkoutUrl': 'https://checkout.paylink.kz/session/abc',
      });

      expect(session.secureCheckoutUri, isNotNull);
      expect(session.secureCheckoutUri!.scheme, 'https');
    });

    test('parses explicit tokenization acceptance from checkout response', () {
      final session = PaymentCheckoutSession.fromJson({
        'paymentId': 'payment-1',
        'orderId': 'order-1',
        'status': 'PENDING',
        'checkoutUrl': 'https://checkout.paylink.kz/session/save',
        'tokenizationRequested': true,
        'cardSaveStatus': 'REQUESTED',
      });

      expect(session.tokenizationRequested, isTrue);
      expect(session.cardSaveStatus, 'REQUESTED');
    });

    test('rejects non-HTTPS and credential-bearing checkout URLs', () {
      const base = {
        'paymentId': 'payment-1',
        'orderId': 'order-1',
        'status': 'PENDING',
      };

      final insecure = PaymentCheckoutSession.fromJson({
        ...base,
        'checkoutUrl': 'http://checkout.paylink.kz/session/abc',
      });
      final credentialBearing = PaymentCheckoutSession.fromJson({
        ...base,
        'checkoutUrl': 'https://user:secret@checkout.paylink.kz/session/abc',
      });
      final relative = PaymentCheckoutSession.fromJson({
        ...base,
        'checkoutUrl': '/payment/abc',
      });

      expect(insecure.secureCheckoutUri, isNull);
      expect(credentialBearing.secureCheckoutUri, isNull);
      expect(relative.secureCheckoutUri, isNull);
    });
  });

  group('PaymentOrderState', () {
    test('accepts success only for secured CARD AUTHORIZED or PAID state', () {
      final authorized = PaymentOrderState.fromJson({
        'orderId': 'order-1',
        'paymentMethod': 'CARD',
        'paymentStatus': 'AUTHORIZED',
        'paymentRecordStatus': 'AUTHORIZED',
        'fundsSecured': true,
        'captured': false,
      });
      final paid = PaymentOrderState.fromJson({
        'orderId': 'order-2',
        'paymentMethod': 'CARD',
        'paymentStatus': 'PAID',
        'paymentRecordStatus': 'PAID',
        'fundsSecured': true,
        'captured': true,
      });
      final inconsistentStatus = PaymentOrderState.fromJson({
        'orderId': 'order-3',
        'paymentMethod': 'CARD',
        'paymentStatus': 'PENDING',
        'paymentRecordStatus': 'PENDING',
        'fundsSecured': true,
        'captured': false,
      });
      final nonCard = PaymentOrderState.fromJson({
        'orderId': 'order-4',
        'paymentMethod': 'CASH',
        'paymentStatus': 'PAID',
        'paymentRecordStatus': 'PAID',
        'fundsSecured': true,
        'captured': true,
      });

      expect(authorized.isSecuredCardPayment, isTrue);
      expect(paid.isSecuredCardPayment, isTrue);
      expect(inconsistentStatus.isSecuredCardPayment, isFalse);
      expect(nonCard.isSecuredCardPayment, isFalse);
    });

    test('keeps payment success separate from saved-card persistence', () {
      final pendingSave = PaymentOrderState.fromJson({
        'orderId': 'order-save-pending',
        'paymentMethod': 'CARD',
        'paymentStatus': 'PAID',
        'paymentRecordStatus': 'PAID',
        'fundsSecured': true,
        'captured': true,
        'cardSaveRequested': true,
        'cardSaveStatus': 'REQUESTED',
      });
      final saved = PaymentOrderState.fromJson({
        'orderId': 'order-save-ok',
        'paymentMethod': 'CARD',
        'paymentStatus': 'PAID',
        'paymentRecordStatus': 'PAID',
        'fundsSecured': true,
        'captured': true,
        'cardSaveRequested': true,
        'cardSaveStatus': 'SAVED',
        'savedPaymentMethodId': 'method-1',
        'cardSavedAt': '2026-09-12T10:00:00.000Z',
      });
      final failedSave = PaymentOrderState.fromJson({
        'orderId': 'order-save-failed',
        'paymentMethod': 'CARD',
        'paymentStatus': 'PAID',
        'paymentRecordStatus': 'PAID',
        'fundsSecured': true,
        'captured': true,
        'cardSaveRequested': true,
        'cardSaveStatus': 'FAILED',
        'cardSaveFailureCode': 'PAYMENT_SAVED_CARD_TOKEN_MISSING',
      });

      expect(pendingSave.isSecuredCardPayment, isTrue);
      expect(pendingSave.isCardSavePending, isTrue);
      expect(saved.isCardSaved, isTrue);
      expect(saved.cardSavedAt, DateTime.parse('2026-09-12T10:00:00.000Z'));
      expect(failedSave.isSecuredCardPayment, isTrue);
      expect(failedSave.isCardSaveFailed, isTrue);
      expect(
        failedSave.cardSaveFailureCode,
        'PAYMENT_SAVED_CARD_TOKEN_MISSING',
      );
    });

    test('classifies failed and settlement terminal states', () {
      final failed = PaymentOrderState.fromJson({
        'orderId': 'order-1',
        'paymentMethod': 'CARD',
        'paymentStatus': 'FAILED',
        'paymentRecordStatus': 'FAILED',
        'fundsSecured': false,
        'captured': false,
      });
      final voided = PaymentOrderState.fromJson({
        'orderId': 'order-2',
        'paymentMethod': 'CARD',
        'paymentStatus': 'VOIDED',
        'paymentRecordStatus': 'VOIDED',
        'fundsSecured': false,
        'captured': false,
      });
      final refunded = PaymentOrderState.fromJson({
        'orderId': 'order-3',
        'paymentMethod': 'CARD',
        'paymentStatus': 'REFUNDED',
        'paymentRecordStatus': 'REFUNDED',
        'fundsSecured': false,
        'captured': false,
      });

      expect(failed.isFailed, isTrue);
      expect(voided.isTerminalWithoutSuccess, isTrue);
      expect(refunded.isTerminalWithoutSuccess, isTrue);
    });
  });

  group('SavedPaymentCard', () {
    test('parses only display-safe backend metadata', () {
      final card = SavedPaymentCard.fromJson({
        'id': 'card-1',
        'provider': 'paylink',
        'last4': '4242',
        'brand': 'VISA',
        'issuerBank': 'Test Bank',
        'isDefault': true,
        // Even if a malformed backend accidentally adds a secret-like field,
        // the Flutter model has no field for it and cannot surface it to UI.
        'providerToken': 'must-not-be-modeled',
      });

      expect(card.brand, PaymentCardBrand.visa);
      expect(card.maskedNumber, '•••• 4242');
      expect(card.issuerBank, 'Test Bank');
      expect(card.isDefault, isTrue);
    });

    test('rejects malformed last4 metadata', () {
      expect(
        () => SavedPaymentCard.fromJson({
          'id': 'card-1',
          'provider': 'paylink',
          'last4': '42x2',
          'brand': 'VISA',
        }),
        throwsFormatException,
      );
    });
  });

  test('parses PayLink DMS states', () {
    expect(
      parseClientPaymentStatus('AUTHORIZED'),
      ClientPaymentStatus.authorized,
    );
    expect(
      parseClientPaymentStatus('CAPTURE_PENDING'),
      ClientPaymentStatus.capturePending,
    );
    expect(
      parseClientPaymentStatus('VOID_PENDING'),
      ClientPaymentStatus.voidPending,
    );
    expect(parseClientPaymentStatus('VOIDED'), ClientPaymentStatus.voided);
  });
}
