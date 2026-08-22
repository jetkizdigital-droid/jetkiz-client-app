import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/app/app.dart';

void main() {
  testWidgets('Jetkiz app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const JetkizApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
