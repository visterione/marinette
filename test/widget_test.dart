import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinette/main.dart';

void main() {
  testWidgets('App should start and show home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BeautyRecommendationsApp());

    expect(find.text('Beauty Recommendations'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
  });
}
