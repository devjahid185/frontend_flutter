import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('App bootstrap renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DistrictSuperAppBootstrap());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DistrictSuperAppBootstrap), findsOneWidget);
  });
}
