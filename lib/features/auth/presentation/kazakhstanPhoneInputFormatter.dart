import 'package:flutter/services.dart';

String kazakhstanLocalPhoneDigits(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');

  // The UI owns the +7 prefix. Accept a pasted full Kazakhstan number,
  // including legacy 8XXXXXXXXXX notation, but never allow 8 to become the
  // first digit after the fixed +7 prefix.
  if (digits.length == 11 &&
      (digits.startsWith('7') || digits.startsWith('8'))) {
    digits = digits.substring(1);
  } else if (digits.startsWith('8')) {
    digits = digits.substring(1);
  }

  if (digits.length > 10) {
    digits = digits.substring(0, 10);
  }

  return digits;
}

String formatKazakhstanLocalPhone(String digits) {
  final safe = kazakhstanLocalPhoneDigits(digits);
  if (safe.isEmpty) return '';

  final buffer = StringBuffer();
  for (var i = 0; i < safe.length; i++) {
    if (i == 0) buffer.write('(');
    if (i == 3) buffer.write(') ');
    if (i == 6 || i == 8) buffer.write('-');
    buffer.write(safe[i]);
  }
  return buffer.toString();
}

class KazakhstanPhoneInputFormatter extends TextInputFormatter {
  const KazakhstanPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final localDigits = kazakhstanLocalPhoneDigits(newValue.text);
    final formatted = formatKazakhstanLocalPhone(localDigits);

    final rawCursor = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final rawBeforeCursor = newValue.text.substring(0, rawCursor);
    final cursorDigits = kazakhstanLocalPhoneDigits(rawBeforeCursor);
    final digitsBeforeCursor = cursorDigits.length.clamp(
      0,
      localDigits.length,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _cursorOffsetForDigitCount(formatted, digitsBeforeCursor),
      ),
    );
  }

  int _cursorOffsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;

    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final code = formatted.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        seen += 1;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }
}
