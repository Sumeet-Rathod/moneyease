import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class RiskQuestionOption {
  final String text;
  final int score;

  RiskQuestionOption({required this.text, required this.score});

  factory RiskQuestionOption.fromJson(Map<String, dynamic> json) {
    return RiskQuestionOption(
      text: json['text'] as String,
      score: json['score'] as int,
    );
  }
}

class RiskQuestion {
  final String id;
  final String category;
  final String question;
  final List<RiskQuestionOption> options;

  RiskQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
  });

  factory RiskQuestion.fromJson(Map<String, dynamic> json) {
    return RiskQuestion(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((o) => RiskQuestionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RiskProfileData {
  final int id;
  final int userId;
  final int totalScore;
  final String category;
  final Map<String, int> answers;
  final String explanation;
  final double recommendedEquityPct;
  final double recommendedDebtPct;
  final double recommendedGoldPct;
  final String? createdAt;

  RiskProfileData({
    required this.id,
    required this.userId,
    required this.totalScore,
    required this.category,
    required this.answers,
    required this.explanation,
    required this.recommendedEquityPct,
    required this.recommendedDebtPct,
    required this.recommendedGoldPct,
    this.createdAt,
  });

  factory RiskProfileData.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final answers = rawAnswers.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0));

    return RiskProfileData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      category: json['category'] ?? 'Moderate',
      answers: answers,
      explanation: json['explanation'] ?? '',
      recommendedEquityPct: (json['recommended_equity_pct'] as num?)?.toDouble() ?? 50.0,
      recommendedDebtPct: (json['recommended_debt_pct'] as num?)?.toDouble() ?? 40.0,
      recommendedGoldPct: (json['recommended_gold_pct'] as num?)?.toDouble() ?? 10.0,
      createdAt: json['created_at'] as String?,
    );
  }
}

class RiskState {
  final bool isLoading;
  final String? error;
  final List<RiskQuestion> questions;
  final Map<String, int> selectedAnswers; // questionId -> option index (0..3)
  final RiskProfileData? currentProfile;

  const RiskState({
    this.isLoading = false,
    this.error,
    this.questions = const [],
    this.selectedAnswers = const {},
    this.currentProfile,
  });

  RiskState copyWith({
    bool? isLoading,
    String? error,
    List<RiskQuestion>? questions,
    Map<String, int>? selectedAnswers,
    RiskProfileData? currentProfile,
  }) {
    return RiskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentProfile: currentProfile ?? this.currentProfile,
    );
  }
}

class RiskNotifier extends StateNotifier<RiskState> {
  final ApiClient _apiClient;

  RiskNotifier(this._apiClient) : super(const RiskState());

  Future<void> loadQuestionsAndProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Fetch questions
      final qRes = await _apiClient.get('/risk/questions');
      final questions = (qRes.data as List)
          .map((q) => RiskQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      // 2. Fetch existing profile if any
      RiskProfileData? profile;
      try {
        final pRes = await _apiClient.get('/risk/my-profile');
        if (pRes.data != null) {
          profile = RiskProfileData.fromJson(pRes.data as Map<String, dynamic>);
        }
      } catch (_) {
        // May not have taken risk test yet
      }

      state = state.copyWith(
        isLoading: false,
        questions: questions,
        currentProfile: profile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load risk questions: $e",
      );
    }
  }

  void selectAnswer(String questionId, int optionIndex) {
    final updated = Map<String, int>.from(state.selectedAnswers);
    updated[questionId] = optionIndex;
    state = state.copyWith(selectedAnswers: updated);
  }

  Future<RiskProfileData?> submitAnswers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.post('/risk/submit', data: {
        'answers': state.selectedAnswers,
      });
      final profile = RiskProfileData.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, currentProfile: profile);
      return profile;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to submit risk profile answers: $e",
      );
      return null;
    }
  }
}

final riskProvider = StateNotifierProvider<RiskNotifier, RiskState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RiskNotifier(apiClient);
});
