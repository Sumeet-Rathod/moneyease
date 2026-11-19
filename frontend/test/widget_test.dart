import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/config.dart';
import 'package:frontend/core/widgets/disclaimer_banner.dart';

void main() {
  testWidgets('MoneyEaseApp builds and displays splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MoneyEaseApp(),
      ),
    );

    // Initial frame displays splash branding
    expect(find.text(AppConfig.firmName), findsOneWidget);
    expect(find.textContaining('ARN-189452'), findsOneWidget);

    // Advance timer past splash delay
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('DisclaimerBanner displays mandatory AMFI compliance text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DisclaimerBanner(),
        ),
      ),
    );

    expect(find.textContaining('Mutual fund investments are subject to market risks'), findsOneWidget);
    expect(find.textContaining('ARN-189452'), findsOneWidget);
  });
}
