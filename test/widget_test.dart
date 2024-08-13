import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator/main.dart'; // Adjust import path if needed

void main() {
  testWidgets('Calculator basic test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(CalculatorApp());

    // Verify that our initial output is "0".
    expect(find.byKey(Key('output')), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Verify buttons are present
    expect(find.text('1'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget); // Verify division symbol button

    // Tap the '1' button and trigger a frame.
    await tester.tap(find.text('1'));
    await tester.pump();

    // Verify that the output has changed to "1".
    expect(find.byKey(Key('output')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
