// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspal/main.dart';

void main() {
  testWidgets('Email login validates input before continuing', (WidgetTester tester) async {
    await tester.pumpWidget(const AspalApp());

    await tester.tap(find.text('Masuk dengan Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
  });

  testWidgets('Detail receives the updated note from its form route', (WidgetTester tester) async {
    await tester.pumpWidget(const AspalApp());

    final guestButton = find.text('Masuk sebagai Tamu (Guest)');
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lat: -0.9471, Long: 100.3543'));
    await tester.pumpAndSettle();
    final editNoteButton = find.text('Ubah Catatan');
    await tester.ensureVisible(editNoteButton);
    await tester.tap(editNoteButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Catatan hasil test');
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan hasil test'), findsOneWidget);
  });
}
