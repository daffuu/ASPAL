import 'package:flutter_test/flutter_test.dart';

import 'package:aspal/main.dart';

void main() {
  testWidgets('app starts and shows login screen', (tester) async {
    await tester.pumpWidget(const AspalApp());

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
