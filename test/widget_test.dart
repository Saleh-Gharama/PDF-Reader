import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present
    expect(find.text('DocReader'), findsOneWidget);

    // Verify that the filter chips are present
    expect(find.text('All'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
  });
}
