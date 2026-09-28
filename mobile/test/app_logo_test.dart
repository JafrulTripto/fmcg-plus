import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo widget renders with default size and CustomPainter', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(size: 48),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('AppLogoPainter paints vector logo cleanly without exception', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            painter: AppLogoPainter(),
            size: Size(100, 100),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
  });
}
