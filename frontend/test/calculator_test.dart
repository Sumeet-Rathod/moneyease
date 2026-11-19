import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/calculator.dart';
import 'package:frontend/core/utils/currency_formatter.dart';

void main() {
  group('FinancialCalculator Unit Tests (Mirroring Backend)', () {
    test('calculateGoal with known values', () {
      final res = FinancialCalculator.calculateGoal(
        currentCost: 1000000.0,
        years: 10.0,
        savedAmount: 100000.0,
        annualReturn: 12.0,
        inflationRate: 6.0,
        stepUpPct: 0.0,
      );

      // 1. Inflation adjusted cost = 1000000 * 1.06^10 ~ 1,790,847.70
      expect((res.futureCost - 1790847.70).abs(), lessThan(5.0));

      // 2. FV of saved amount = 100000 * 1.12^10 ~ 310,584.82
      expect((res.fvSaved - 310584.82).abs(), lessThan(5.0));

      // 3. Gap = 1,790,847.70 - 310,584.82 ~ 1,480,262.88
      expect((res.gap - 1480262.88).abs(), lessThan(5.0));

      // 4. Required monthly SIP ~ 6,371.13
      expect((res.requiredSip - 6371.13).abs(), lessThan(2.0));

      // 5. Required Lumpsum today ~ 476,605.02
      expect((res.requiredLumpsum - 476605.02).abs(), lessThan(2.0));

      // 6. Trajectory points count
      expect(res.trajectory.length, equals(10));
      expect(res.trajectory.last.year, equals(10));
      expect(res.trajectory.last.invested, greaterThan(100000.0));
    });

    test('simulateSip what-if scenario', () {
      final sim = FinancialCalculator.simulateSip(
        monthlyInvestment: 5000.0,
        years: 10.0,
        annualReturn: 12.0,
      );

      expect(sim.invested, equals(600000.0));
      expect((sim.futureValue - 1161695.38).abs(), lessThan(5.0));
      expect((sim.wealthGain - 561695.38).abs(), lessThan(5.0));
    });

    test('simulateStepUp scenario', () {
      final flat = FinancialCalculator.simulateSip(monthlyInvestment: 5000.0, years: 10.0, annualReturn: 12.0);
      final step = FinancialCalculator.simulateStepUp(
        startingSip: 5000.0,
        years: 10.0,
        annualReturn: 12.0,
        stepUpPct: 10.0,
      );

      expect(step['invested']!, greaterThan(flat.invested));
      expect(step['future_value']!, greaterThan(flat.futureValue));
    });

    test('CurrencyFormatter formatWords', () {
      expect(CurrencyFormatter.formatWords(0), equals('₹0'));
      expect(CurrencyFormatter.formatWords(50000), equals('50 Thousand'));
      expect(CurrencyFormatter.formatWords(100000), equals('1 Lakh'));
      expect(CurrencyFormatter.formatWords(2500000), equals('25 Lakh'));
      expect(CurrencyFormatter.formatWords(12500000), equals('1.25 Crore'));
      expect(CurrencyFormatter.formatWords(50000000), equals('5 Crore'));
    });
  });
}
