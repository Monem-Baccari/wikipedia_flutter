import 'package:flutter_test/flutter_test.dart';

import 'package:wikipedia_flutter/main.dart';

void main() {
  testWidgets('Main app shows Wikipedia screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Wikipedia Flutter'), findsOneWidget);
  });
}
