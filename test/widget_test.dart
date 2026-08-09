import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweets_ledger/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialLocale: 'ar'));
    await tester.pumpAndSettle();

    // التحقق من وجود عنصر في الواجهة
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}