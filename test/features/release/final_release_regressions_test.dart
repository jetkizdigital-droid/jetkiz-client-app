import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocked account deletion keeps push registration intact', () {
    final source = File(
      'lib/features/settings/presentation/settingsPage.dart',
    ).readAsStringSync();

    final start = source.indexOf(
      'Future<void> _confirmAndDeleteAccount() async',
    );
    final end = source.indexOf(
      'Future<void> _clearLocalSessionAndExit() async',
      start,
    );

    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final deleteFlow = source.substring(start, end);
    expect(deleteFlow, contains('await _profileApi.deleteMyAccount();'));
    expect(deleteFlow, isNot(contains('unregisterCurrentToken')));
  });

  test('post-login sync does not emit a second hardcoded app_open', () {
    final postLogin = File(
      'lib/features/auth/data/authPostLoginService.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(postLogin, isNot(contains("'/client-events'")));
    expect(postLogin, isNot(contains("'locale': 'ru'")));
    expect(mainSource, contains("eventName: 'app_open'"));
    expect(mainSource, contains("source: 'app_start'"));
  });
}
