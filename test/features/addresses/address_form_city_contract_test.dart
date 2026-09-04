import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';
import 'package:jetkiz_mobile/features/addresses/presentation/addressFormPage.dart';

void main() {
  Widget app(AddressFormPage page, {AppLanguage language = AppLanguage.ru}) {
    return AppLocalizationScope(
      language: language,
      onLanguageChanged: (_) {},
      child: MaterialApp(home: page),
    );
  }

  testWidgets(
    'delivery city is fixed to Shchuchinsk and is not an editable field',
    (tester) async {
      await tester.pumpWidget(app(const AddressFormPage()));
      await tester.pump();

      expect(find.text('Щучинск'), findsOneWidget);

      final editableValues = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller?.text ?? '')
          .toList();

      expect(editableValues, isNot(contains('Щучинск')));
    },
  );

  testWidgets(
    'editing a stored full address exposes only street and house',
    (tester) async {
      final now = DateTime(2026, 9, 5);
      final address = Address(
        id: 'address-1',
        userId: 'user-1',
        title: 'Дом',
        address: 'Щучинск, ул. Абая, 10',
        floor: null,
        door: null,
        entrance: null,
        intercom: null,
        contactPhone: null,
        comment: null,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(app(AddressFormPage(initialAddress: address)));
      await tester.pump();

      final editableValues = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller?.text ?? '')
          .toList();

      expect(editableValues, contains('ул. Абая, 10'));
      expect(editableValues, isNot(contains('Щучинск, ул. Абая, 10')));
    },
  );

  testWidgets(
    'fixed-city address screen is localized in Kazakh',
    (tester) async {
      await tester.pumpWidget(
        app(const AddressFormPage(), language: AppLanguage.kk),
      );
      await tester.pump();

      expect(find.text('Щучинск'), findsOneWidget);
      expect(find.text('Қала'), findsOneWidget);
      expect(find.text('Көше, үй'), findsOneWidget);
      expect(
        find.text('Жеткізу әзірге тек Щучинск қаласында қолжетімді'),
        findsOneWidget,
      );

      expect(find.text('Город'), findsNothing);
      expect(find.text('Улица, дом'), findsNothing);
      expect(
        find.text('Доставка пока доступна только в Щучинске'),
        findsNothing,
      );
    },
  );
}
