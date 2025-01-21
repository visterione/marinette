import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinette/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Будуємо наш додаток та тригеримо фрейм
    await tester.pumpWidget(
      const BeautyRecommendationsApp(),
    );

    // Тут можна додати різні тести, наприклад:
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
