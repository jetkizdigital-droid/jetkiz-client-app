import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/auth/presentation/smsCodePage.dart';

void main() {
  testWidgets('OTP input remains focusable after app resume', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SmsCodePage(phone: '77001234567'),
      ),
    );
    await tester.pump();
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(textField.focusNode?.hasFocus, isTrue);
  });
}
