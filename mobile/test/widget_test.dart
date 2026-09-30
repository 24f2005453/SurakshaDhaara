import 'package:flutter_test/flutter_test.dart';

import 'package:urbangard/main.dart';

void main() {
  testWidgets('UrbanGuard home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbanGuardApp());

    expect(find.text('UrbanGuard'), findsOneWidget);
    expect(find.text('Current risk'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
  });
}