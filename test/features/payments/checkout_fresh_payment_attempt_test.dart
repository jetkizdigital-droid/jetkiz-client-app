import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/checkout/presentation/checkoutPage.dart',
    ).readAsStringSync();
  });

  test('checkout does not persist or resume an unfinished payment attempt', () {
    expect(source, isNot(contains('_recoverPendingPayment')));
    expect(source, isNot(contains('_resumePendingPayment')));
    expect(source, isNot(contains('_paymentPendingStore.save')));
    expect(source, contains('unawaited(PaymentPendingStore().clear())'));
    expect(source, contains("final orderAttemptKey = 'client-order-"));
  });

  test('new-card UX skips the other-card tile when no saved cards exist', () {
    expect(
      source,
      contains('if (_savedCards.isNotEmpty)\n                        _AddNewCardTile('),
    );
    expect(
      source,
      contains('showSaveCardOption: !_isCardsLoading && _useNewCard'),
    );
    expect(
      source,
      contains('saveCardLabel: paymentStrings.saveCardForFuture'),
    );
  });
}
