import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/auth/presentation/kazakhstanPhoneInputFormatter.dart';

void main() {
  const formatter = KazakhstanPhoneInputFormatter();

  TextEditingValue edit(String text, {int? cursor}) {
    final offset = cursor ?? text.length;
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset),
      ),
    );
  }

  test('rejects 8 as the first digit after fixed +7 prefix', () {
    final value = edit('8');

    expect(value.text, isEmpty);
    expect(value.selection.extentOffset, 0);
  });

  test('formats a valid local Kazakhstan phone', () {
    final value = edit('7001234567');

    expect(value.text, '(700) 123-45-67');
  });

  test('accepts pasted legacy 8-prefixed national number', () {
    final value = edit('87001234567');

    expect(value.text, '(700) 123-45-67');
  });

  test('accepts pasted +7-prefixed Kazakhstan number', () {
    final value = edit('+77001234567');

    expect(value.text, '(700) 123-45-67');
  });

  test('keeps the cursor near the edited digit instead of forcing it to end', () {
    final value = edit('(700) 123-45-67', cursor: 9);

    expect(value.text, '(700) 123-45-67');
    expect(value.selection.extentOffset, lessThan(value.text.length));
  });
}
