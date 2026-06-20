import 'package:cropz_web_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const CropzWebApp());
    expect(find.text('Cropz Card'), findsOneWidget);
  });

  testWidgets('desktop navigation opens help and privacy pages', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CropzWebApp());

    await tester.tap(find.widgetWithText(TextButton, 'Help'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Common issues'), findsNothing);
    expect(find.text('Common problems'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Privacy'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.textContaining('PocketBase'), findsNothing);
    expect(find.textContaining('Netlify'), findsNothing);
    expect(find.textContaining('backend'), findsNothing);
  });

  testWidgets('theme toggle is removed from the web shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CropzWebApp());

    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);
  });
}
