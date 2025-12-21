import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat/screens/splash_screen.dart';

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build just the SplashScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify text
    expect(find.text('잠시만 기다려 주세요...'), findsOneWidget);
  });
}
