import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lavadero_motos/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LavoBarApp());

    // Verify that the app loads
    expect(find.text('Labo Bar'), findsOneWidget);
  });
}
