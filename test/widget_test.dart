import 'package:flutter_test/flutter_test.dart';
import 'package:marinette/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
  });
}
