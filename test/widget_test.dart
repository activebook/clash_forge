// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clash_forge/main.dart';
import 'package:clash_forge/models/app_info.dart';

void main() {
  testWidgets('App loads and shows Forge view', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(appInfo: AppInfo(appName: 'Clash Forge', appVersion: '1.0.0')),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that the Add button is present (Forge view is loaded)
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify that we do NOT have bottom navigation tabs
    expect(find.text('Forge'), findsNothing);
    expect(find.text('Switch'), findsNothing);
  });
}
