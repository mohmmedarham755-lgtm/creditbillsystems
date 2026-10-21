import 'package:creditbillsytems/core/utils/credit_calculator.dart';
import 'package:creditbillsytems/features/dashboard/presentation/utilization_gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UtilizationGaugeWidget', () {
    Widget buildWidget({
      double percentage = 20.0,
      CreditHealthTier? tier,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: UtilizationGaugeWidget(
            utilizationPercentage: percentage,
            healthTier: tier,
          ),
        ),
      );
    }

    testWidgets('renders healthy tier with correct label', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 20.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('20.0%'), findsOneWidget);
      expect(find.text('Healthy Usage (<30%)'), findsOneWidget);
    });

    testWidgets('renders moderate tier with correct label', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 40.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('40.0%'), findsOneWidget);
      expect(find.text('Moderate Usage (30-50%)'), findsOneWidget);
    });

    testWidgets('renders high-risk tier with correct label', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 66.7));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('66.7%'), findsOneWidget);
      expect(find.text('High Risk Usage (>50%)'), findsOneWidget);
    });

    testWidgets('formats percentage to one decimal place', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 33.333));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('33.3%'), findsOneWidget);
    });

    testWidgets('renders zero utilization', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 0.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('Healthy Usage (<30%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders full utilization without overflow', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 100.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('High Risk Usage (>50%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps arc at 100% for above-100 utilization', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: 125.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('125.0%'), findsOneWidget);
      expect(find.text('High Risk Usage (>50%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps arc at 0% for negative utilization', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: -10.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('Healthy Usage (<30%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('honors explicit health tier override', (tester) async {
      await tester.pumpWidget(
        buildWidget(percentage: 20.0, tier: CreditHealthTier.moderate),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('20.0%'), findsOneWidget);
      expect(find.text('Moderate Usage (30-50%)'), findsOneWidget);
    });

    testWidgets('opens and dismisses informational dialog on tap', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(percentage: 50.0));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(UtilizationGaugeWidget));
      await tester.pump();
      expect(find.text('Credit Utilization'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pump();
      expect(find.text('Credit Utilization'), findsNothing);
    });

    testWidgets('announces percentage and tier in semantics', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(percentage: 20.0));
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.bySemanticsLabel('Credit utilization is 20.0%, categorized as Healthy.'),
        findsOneWidget,
      );
    });

    testWidgets('renders with enlarged text without layout breakage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: buildWidget(percentage: 50.0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Text wraps and renders; softWrap ensures no layout breakage.
      expect(find.text('50.0%'), findsOneWidget);
    });

    testWidgets('progresses deterministically through animation', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(percentage: 50.0));

      // Initial state after pump widget
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('50.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Intermediate state after 300ms
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('50.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Completed state after another 300ms (600ms total)
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('50.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles non-finite input safely', (tester) async {
      await tester.pumpWidget(buildWidget(percentage: double.nan));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('Healthy Usage (<30%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes animation controller without ticker errors', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(percentage: 30.0));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
