import 'package:cropz_web_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home matches the English CropzCard landing content', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CropzWebApp());

    expect(
      find.text('Your professional agri business card, always ready to share.'),
      findsOneWidget,
    );
    expect(find.text('MADE FOR AGRICULTURAL PRODUCT DEALERS'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.byType(Image), findsWidgets);
    expect(
      find.image(const AssetImage('assets/images/cropzcard-hd-logo.png')),
      findsWidgets,
    );
    expect(find.widgetWithText(TextButton, 'Help'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Privacy Policy'), findsOneWidget);
  });

  testWidgets('top bar opens English Help and Privacy pages', (
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
    expect(find.widgetWithText(TextButton, 'Help'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Privacy Policy').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('About'), findsNothing);
  });

  testWidgets('theme toggle remains absent', (WidgetTester tester) async {
    await tester.pumpWidget(const CropzWebApp());

    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);
  });
}
