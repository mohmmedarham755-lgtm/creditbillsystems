import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/utils/credit_calculator.dart';

void main() {
  group('CreditCalculator Domain Unit Tests', () {
    test('returns 0.0 when totalLimit is 0 or negative', () {
      expect(
        CreditCalculator.calculateUtilization(totalBalance: 500, totalLimit: 0),
        0.0,
      );
      expect(
        CreditCalculator.calculateUtilization(
          totalBalance: 500,
          totalLimit: -100,
        ),
        0.0,
      );
    });

    test('returns 0.0 when totalBalance is 0 or negative', () {
      expect(
        CreditCalculator.calculateUtilization(
          totalBalance: 0,
          totalLimit: 5000,
        ),
        0.0,
      );
      expect(
        CreditCalculator.calculateUtilization(
          totalBalance: -50,
          totalLimit: 5000,
        ),
        0.0,
      );
    });

    test('correctly calculates healthy utilization (<30%)', () {
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 600,
        totalLimit: 3000,
      );
      expect(percentage, 20.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.healthy,
      );
      expect(
        CreditCalculator.getHealthTierLabel(CreditHealthTier.healthy),
        'Healthy Usage (<30%)',
      );
    });

    test('correctly calculates moderate utilization (30% - 50%)', () {
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 1200,
        totalLimit: 3000,
      );
      expect(percentage, 40.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.moderate,
      );
      expect(
        CreditCalculator.getHealthTierLabel(CreditHealthTier.moderate),
        'Moderate Usage (30-50%)',
      );
    });

    test('correctly calculates high risk utilization (>50%)', () {
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 2000,
        totalLimit: 3000,
      );
      expect(percentage, 66.7);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.highRisk,
      );
      expect(
        CreditCalculator.getHealthTierLabel(CreditHealthTier.highRisk),
        'High Risk Usage (>50%)',
      );
    });

    test('classifies exactly 30% as moderate tier boundary', () {
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 900,
        totalLimit: 3000,
      );
      expect(percentage, 30.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.moderate,
      );
      expect(
        CreditCalculator.getHealthTierLabel(CreditHealthTier.moderate),
        'Moderate Usage (30-50%)',
      );
    });

    test('classifies exactly 50% as moderate tier boundary', () {
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 1500,
        totalLimit: 3000,
      );
      expect(percentage, 50.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.moderate,
      );
      expect(
        CreditCalculator.getHealthTierLabel(CreditHealthTier.moderate),
        'Moderate Usage (30-50%)',
      );
    });

    test('classifies a value rounding to exactly 30% as moderate', () {
      // 899 / 3000 * 100 = 29.966... -> rounds to 30.0
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 899,
        totalLimit: 3000,
      );
      expect(percentage, 30.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.moderate,
      );
    });

    test('classifies a value rounding to exactly 50% as moderate', () {
      // 1499 / 3000 * 100 = 49.966... -> rounds to 50.0
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 1499,
        totalLimit: 3000,
      );
      expect(percentage, 50.0);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.moderate,
      );
    });

    test('classifies just below 30% as healthy', () {
      // 898 / 3000 * 100 = 29.933... -> rounds to 29.9
      final percentage = CreditCalculator.calculateUtilization(
        totalBalance: 898,
        totalLimit: 3000,
      );
      expect(percentage, 29.9);
      expect(
        CreditCalculator.getHealthTier(percentage),
        CreditHealthTier.healthy,
      );
    });

    test(
      'classifies a value rounding to exactly 50% as moderate (not high risk)',
      () {
        // 1501 / 3000 * 100 = 50.033... -> rounds to 50.0
        final percentage = CreditCalculator.calculateUtilization(
          totalBalance: 1501,
          totalLimit: 3000,
        );
        expect(percentage, 50.0);
        expect(
          CreditCalculator.getHealthTier(percentage),
          CreditHealthTier.moderate,
        );
      },
    );
  });
}
