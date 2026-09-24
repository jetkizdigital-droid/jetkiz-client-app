import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/time/apiDateTime.dart';

void main() {
  group('parseApiDateTime', () {
    test('converts UTC API timestamp to device local time', () {
      final utc = DateTime.parse('2026-09-24T17:30:00.000Z');

      final result = parseApiDateTime('2026-09-24T17:30:00.000Z');

      expect(result, isNotNull);
      expect(result!.isUtc, isFalse);
      expect(result.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
      expect(result, utc.toLocal());
    });

    test('preserves the instant for timestamps with an explicit offset', () {
      final source = DateTime.parse('2026-09-24T22:30:00.000+05:00');

      final result = parseApiDateTime('2026-09-24T22:30:00.000+05:00');

      expect(result, isNotNull);
      expect(result!.isUtc, isFalse);
      expect(result.millisecondsSinceEpoch, source.millisecondsSinceEpoch);
      expect(result, source.toLocal());
    });

    test('normalizes DateTime input and rejects invalid values', () {
      final utc = DateTime.utc(2026, 9, 24, 17, 30);

      expect(parseApiDateTime(utc), utc.toLocal());
      expect(parseApiDateTime(null), isNull);
      expect(parseApiDateTime('not-a-date'), isNull);
    });
  });
}
