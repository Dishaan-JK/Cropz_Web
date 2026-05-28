import 'package:cropz_web_frontend/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const CropzWebApp());
    expect(find.text('Cropz Card'), findsOneWidget);
  });
}
