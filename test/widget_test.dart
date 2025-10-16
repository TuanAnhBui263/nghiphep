// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nghiphep/main.dart';
import 'package:nghiphep/providers/auth_provider.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: const NghiPhepApp(),
      ),
    );

    // Verify that login screen is displayed
    expect(find.text('Hệ thống nghỉ phép'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
