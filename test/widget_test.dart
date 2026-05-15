import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader/main.dart';

void main() {
  testWidgets('App starts and shows DocReader title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app title is displayed.
    expect(find.text('DocReader'), findsOneWidget);
  });
}
