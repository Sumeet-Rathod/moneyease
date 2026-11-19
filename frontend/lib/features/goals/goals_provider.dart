import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/utils/calculator.dart';

class GoalModel {
  final int id;
  final int userId;
  final String type;
  final String name;
  final double currentCost;
  final double years;
  final double savedAmount;
  final double inflation;
  final double assumedReturn;
  final double futureCost;
  final String? futureCostWords;
  final double requiredSip;
  final double requiredLumpsum;
  final String? requiredLumpsumWords;
  final double stepUpPct;
  final String? createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.currentCost,
    required this.years,
    required this.savedAmount,
    required this.inflation,
    required this.assumedReturn,
    required this.futureCost,
    this.futureCostWords,
    required this.requiredSip,
    required this.requiredLumpsum,
    this.requiredLumpsumWords,
    required this.stepUpPct,
    this.createdAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? 'Custom',
      name: json['name'] ?? '',
      currentCost: (json['current_cost'] as num?)?.toDouble() ?? 0.0,
      years: (json['years'] as num?)?.toDouble() ?? 1.0,
      savedAmount: (json['saved_amount'] as num?)?.toDouble() ?? 0.0,
      inflation: (json['inflation'] as num?)?.toDouble() ?? 6.0,
      assumedReturn: (json['assumed_return'] as num?)?.toDouble() ?? 10.0,
      futureCost: (json['future_cost'] as num?)?.toDouble() ?? 0.0,
      futureCostWords: json['future_cost_words'] as String?,
      requiredSip: (json['required_sip'] as num?)?.toDouble() ?? 0.0,
      requiredLumpsum: (json['required_lumpsum'] as num?)?.toDouble() ?? 0.0,
      requiredLumpsumWords: json['required_lumpsum_words'] as String?,
      stepUpPct: (json['step_up_pct'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String?,
    );
  }
}

class GoalsState {
  final bool isLoading;
  final String? error;
  final List<GoalModel> goals;
  final GoalCalculationResult? currentDraftCalculation;

  const GoalsState({
    this.isLoading = false,
    this.error,
    this.goals = const [],
    this.currentDraftCalculation,
  });

  GoalsState copyWith({
    bool? isLoading,
    String? error,
    List<GoalModel>? goals,
    GoalCalculationResult? currentDraftCalculation,
  }) {
    return GoalsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      goals: goals ?? this.goals,
      currentDraftCalculation: currentDraftCalculation ?? this.currentDraftCalculation,
    );
  }

  double get totalTargetFutureCost => goals.fold(0.0, (acc, g) => acc + g.futureCost);
  double get totalRequiredMonthlySip => goals.fold(0.0, (acc, g) => acc + g.requiredSip);
  double get totalSavedAmount => goals.fold(0.0, (acc, g) => acc + g.savedAmount);
}

class GoalsNotifier extends StateNotifier<GoalsState> {
  final ApiClient _apiClient;

  GoalsNotifier(this._apiClient) : super(const GoalsState());

  Future<void> fetchGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get('/goals');
      final list = (res.data as List)
          .map((g) => GoalModel.fromJson(g as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, goals: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to load goals: $e");
    }
  }

  Future<bool> addGoal({
    required String name,
    required String type,
    required double currentCost,
    required double years,
    required double savedAmount,
    required double inflation,
    double? assumedReturn,
    double stepUpPct = 0.0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.post('/goals', data: {
        'name': name,
        'type': type,
        'current_cost': currentCost,
        'years': years,
        'saved_amount': savedAmount,
        'inflation': inflation,
        'assumed_return': assumedReturn,
        'step_up_pct': stepUpPct,
      });
      final newGoal = GoalModel.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        goals: [...state.goals, newGoal],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to create goal: $e");
      return false;
    }
  }

  Future<bool> updateGoal({
    required int id,
    String? name,
    double? currentCost,
    double? years,
    double? savedAmount,
    double? inflation,
    double? assumedReturn,
    double? stepUpPct,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.put('/goals/$id', data: {
        if (name != null) 'name': name,
        if (currentCost != null) 'current_cost': currentCost,
        if (years != null) 'years': years,
        if (savedAmount != null) 'saved_amount': savedAmount,
        if (inflation != null) 'inflation': inflation,
        if (assumedReturn != null) 'assumed_return': assumedReturn,
        if (stepUpPct != null) 'step_up_pct': stepUpPct,
      });
      final updated = GoalModel.fromJson(res.data as Map<String, dynamic>);
      final updatedList = state.goals.map((g) => g.id == id ? updated : g).toList();
      state = state.copyWith(isLoading: false, goals: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to update goal: $e");
      return false;
    }
  }

  Future<bool> deleteGoal(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.delete('/goals/$id');
      final updatedList = state.goals.where((g) => g.id != id).toList();
      state = state.copyWith(isLoading: false, goals: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to delete goal: $e");
      return false;
    }
  }

  // Calculate live offline or via backend
  GoalCalculationResult calculateLiveDraft({
    required double currentCost,
    required double years,
    required double savedAmount,
    required double assumedReturn,
    required double inflationRate,
    double stepUpPct = 0.0,
  }) {
    final result = FinancialCalculator.calculateGoal(
      currentCost: currentCost,
      years: years,
      savedAmount: savedAmount,
      annualReturn: assumedReturn,
      inflationRate: inflationRate,
      stepUpPct: stepUpPct,
    );
    state = state.copyWith(currentDraftCalculation: result);
    return result;
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoalsNotifier(apiClient);
});
