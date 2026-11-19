import 'dart:math' as math;

class TrajectoryPoint {
  final int year;
  final double invested;
  final double projectedValue;

  TrajectoryPoint({
    required this.year,
    required this.invested,
    required this.projectedValue,
  });

  factory TrajectoryPoint.fromJson(Map<String, dynamic> json) {
    return TrajectoryPoint(
      year: json['year'] as int,
      invested: (json['invested'] as num).toDouble(),
      projectedValue: (json['projected_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'year': year,
    'invested': invested,
    'projected_value': projectedValue,
  };
}

class GoalCalculationResult {
  final double currentCost;
  final double years;
  final double savedAmount;
  final double inflationRate;
  final double assumedReturn;
  final double futureCost;
  final double fvSaved;
  final double gap;
  final double requiredSip;
  final double requiredLumpsum;
  final double stepUpPct;
  final double startingStepUpSip;
  final List<TrajectoryPoint> trajectory;

  GoalCalculationResult({
    required this.currentCost,
    required this.years,
    required this.savedAmount,
    required this.inflationRate,
    required this.assumedReturn,
    required this.futureCost,
    required this.fvSaved,
    required this.gap,
    required this.requiredSip,
    required this.requiredLumpsum,
    required this.stepUpPct,
    required this.startingStepUpSip,
    required this.trajectory,
  });
}

class SipSimulationResult {
  final double invested;
  final double futureValue;
  final double wealthGain;

  SipSimulationResult({
    required this.invested,
    required this.futureValue,
    required this.wealthGain,
  });

  double get totalInvested => invested;
  double get wealthGained => wealthGain;

  double operator [](String key) {
    if (key == 'invested') return invested;
    if (key == 'future_value') return futureValue;
    if (key == 'wealth_gain') return wealthGain;
    return 0.0;
  }
}

class FinancialCalculator {
  static GoalCalculationResult calculateGoal({
    required double currentCost,
    required double years,
    double savedAmount = 0.0,
    double annualReturn = 10.0,
    double inflationRate = 6.0,
    double stepUpPct = 0.0,
  }) {
    if (currentCost < 0) currentCost = 0.0;
    if (years <= 0) years = 1.0;
    if (savedAmount < 0) savedAmount = 0.0;

    final i = inflationRate / 100.0;
    final rAnnual = annualReturn / 100.0;
    final rMonthly = rAnnual / 12.0;
    final nMonths = (years * 12).round();

    // 1. Inflation-adjusted future cost
    final futureCost = currentCost * math.pow(1.0 + i, years);

    // 2. Future value of existing savings
    final fvSaved = savedAmount * math.pow(1.0 + rAnnual, years);

    // 3. Gap
    final gap = math.max(futureCost - fvSaved, 0.0);

    // 4. Required monthly SIP (invested at start of month: Annuity due)
    double requiredSip = 0.0;
    if (gap > 0) {
      if (rMonthly > 0) {
        final denom = (math.pow(1.0 + rMonthly, nMonths) - 1.0) * (1.0 + rMonthly);
        requiredSip = denom > 0 ? (gap * rMonthly) / denom : 0.0;
      } else {
        requiredSip = nMonths > 0 ? gap / nMonths : 0.0;
      }
    }

    // 5. Lumpsum needed today
    double requiredLumpsum = 0.0;
    if (gap > 0) {
      if (rAnnual > 0) {
        requiredLumpsum = gap / math.pow(1.0 + rAnnual, years);
      } else {
        requiredLumpsum = gap;
      }
    }

    // 6. Step-up SIP calculation
    double startingStepUpSip = requiredSip;
    if (stepUpPct > 0 && gap > 0) {
      double low = 1.0;
      double high = requiredSip;
      for (int step = 0; step < 50; step++) {
        final mid = (low + high) / 2.0;
        final fvTest = simulateStepUp(
          startingSip: mid,
          stepUpPct: stepUpPct,
          annualReturn: annualReturn,
          years: years,
        )['future_value']!;
        if ((fvTest - gap).abs() < 1.0) {
          startingStepUpSip = mid;
          break;
        } else if (fvTest < gap) {
          low = mid;
        } else {
          high = mid;
        }
      }
      startingStepUpSip = (low + high) / 2.0;
    }

    // 7. Trajectory
    final List<TrajectoryPoint> trajectory = [];
    double accumulated = savedAmount;
    double totalInvested = savedAmount;
    final currentSip = requiredSip;

    for (int y = 1; y <= years.ceil(); y++) {
      for (int m = 0; m < 12; m++) {
        totalInvested += currentSip;
        accumulated = (accumulated + currentSip) * (1.0 + rMonthly);
      }
      trajectory.add(TrajectoryPoint(
        year: y,
        invested: double.parse(totalInvested.toStringAsFixed(2)),
        projectedValue: double.parse(accumulated.toStringAsFixed(2)),
      ));
    }

    return GoalCalculationResult(
      currentCost: double.parse(currentCost.toStringAsFixed(2)),
      years: double.parse(years.toStringAsFixed(1)),
      savedAmount: double.parse(savedAmount.toStringAsFixed(2)),
      inflationRate: double.parse(inflationRate.toStringAsFixed(2)),
      assumedReturn: double.parse(annualReturn.toStringAsFixed(2)),
      futureCost: double.parse(futureCost.toStringAsFixed(2)),
      fvSaved: double.parse(fvSaved.toStringAsFixed(2)),
      gap: double.parse(gap.toStringAsFixed(2)),
      requiredSip: double.parse(requiredSip.toStringAsFixed(2)),
      requiredLumpsum: double.parse(requiredLumpsum.toStringAsFixed(2)),
      stepUpPct: double.parse(stepUpPct.toStringAsFixed(2)),
      startingStepUpSip: double.parse(startingStepUpSip.toStringAsFixed(2)),
      trajectory: trajectory,
    );
  }

  static SipSimulationResult simulateSip({
    double? monthlySip,
    double? monthlyInvestment,
    required double years,
    required double annualReturn,
  }) {
    final effectiveMonthly = monthlySip ?? monthlyInvestment ?? 0.0;
    if (effectiveMonthly <= 0 || years <= 0) {
      return SipSimulationResult(invested: 0.0, futureValue: 0.0, wealthGain: 0.0);
    }

    final rMonthly = (annualReturn / 100.0) / 12.0;
    final nMonths = (years * 12).round();
    final totalInvested = effectiveMonthly * nMonths;

    double fv = totalInvested;
    if (rMonthly > 0) {
      fv = effectiveMonthly *
          ((math.pow(1.0 + rMonthly, nMonths) - 1.0) / rMonthly) *
          (1.0 + rMonthly);
    }

    return SipSimulationResult(
      invested: double.parse(totalInvested.toStringAsFixed(2)),
      futureValue: double.parse(fv.toStringAsFixed(2)),
      wealthGain: double.parse(math.max(fv - totalInvested, 0.0).toStringAsFixed(2)),
    );
  }

  static Map<String, double> simulateStepUp({
    required double startingSip,
    required double stepUpPct,
    required double annualReturn,
    required double years,
  }) {
    final rMonthly = (annualReturn / 100.0) / 12.0;
    final totalMonths = (years * 12).round();
    double currentSip = startingSip;
    double accumulated = 0.0;
    double totalInvested = 0.0;

    for (int m = 0; m < totalMonths; m++) {
      if (m > 0 && m % 12 == 0) {
        currentSip *= (1.0 + stepUpPct / 100.0);
      }
      totalInvested += currentSip;
      accumulated = (accumulated + currentSip) * (1.0 + rMonthly);
    }

    return {
      'invested': double.parse(totalInvested.toStringAsFixed(2)),
      'future_value': double.parse(accumulated.toStringAsFixed(2)),
      'wealth_gain': double.parse(math.max(accumulated - totalInvested, 0.0).toStringAsFixed(2)),
    };
  }
}
