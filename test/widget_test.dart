import 'package:flutter_test/flutter_test.dart';
import 'package:sweets_ledger/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialLocale: 'ar'));
    await tester.pumpAndSettle();
  });
}