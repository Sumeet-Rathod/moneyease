import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../config.dart';

class DoubtMessage {
  final String text;
  final bool isUser;
  final String? source;
  final String? topic;
  final String? disclaimer;
  final DateTime timestamp;

  DoubtMessage({
    required this.text,
    required this.isUser,
    this.source,
    this.topic,
    this.disclaimer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DoubtsState {
  final bool isLoading;
  final String? error;
  final List<DoubtMessage> messages;
  final List<String> suggestedChips;

  const DoubtsState({
    this.isLoading = false,
    this.error,
    this.messages = const [],
    this.suggestedChips = const [],
  });

  DoubtsState copyWith({
    bool? isLoading,
    String? error,
    List<DoubtMessage>? messages,
    List<String>? suggestedChips,
  }) {
    return DoubtsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messages: messages ?? this.messages,
      suggestedChips: suggestedChips ?? this.suggestedChips,
    );
  }
}

class DoubtsNotifier extends StateNotifier<DoubtsState> {
  final ApiClient _apiClient;

  DoubtsNotifier(this._apiClient) : super(const DoubtsState());

  Future<void> init() async {
    await fetchSuggestedChips();
    await fetchHistory();
  }

  Future<void> fetchSuggestedChips() async {
    try {
      final res = await _apiClient.get('/doubts/suggested');
      final chips = (res.data as List).map((c) => c.toString()).toList();
      state = state.copyWith(suggestedChips: chips);
    } catch (_) {
      // Fallback chips
      state = state.copyWith(suggestedChips: [
        "What is SIP?",
        "Is mutual fund safe?",
        "What is ELSS?",
        "SIP vs FD?",
        "What is NAV?",
        "How much should I invest?",
        "What is KYC?",
        "What is term insurance?",
      ]);
    }
  }

  Future<void> fetchHistory() async {
    try {
      final res = await _apiClient.get('/doubts/history');
      final history = res.data as List;
      final List<DoubtMessage> loaded = [];

      for (final item in history.reversed) {
        loaded.add(DoubtMessage(
          text: item['question'] ?? '',
          isUser: true,
          timestamp: item['created_at'] != null ? DateTime.tryParse(item['created_at']) : null,
        ));
        loaded.add(DoubtMessage(
          text: item['answer'] ?? '',
          isUser: false,
          source: item['source'],
          topic: item['topic'],
          disclaimer: AppConfig.complianceDisclaimer,
          timestamp: item['created_at'] != null ? DateTime.tryParse(item['created_at']) : null,
        ));
      }

      if (loaded.isEmpty) {
        // Welcome message
        loaded.add(DoubtMessage(
          text: "Hello! I am your MoneyEase Financial Assistant. Ask me anything about mutual funds, SIPs, ELSS, tax saving, KYC, or debt vs equity.",
          isUser: false,
          source: "system",
          disclaimer: AppConfig.complianceDisclaimer,
        ));
      }

      state = state.copyWith(messages: loaded);
    } catch (_) {
      if (state.messages.isEmpty) {
        state = state.copyWith(messages: [
          DoubtMessage(
            text: "Hello! I am your MoneyEase Financial Assistant. Ask me anything about mutual funds, SIPs, ELSS, or financial planning.",
            isUser: false,
            source: "system",
            disclaimer: AppConfig.complianceDisclaimer,
          )
        ]);
      }
    }
  }

  Future<void> askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    final userMsg = DoubtMessage(text: question.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final res = await _apiClient.post('/doubts/ask', data: {'question': question.trim()});
      final data = res.data as Map<String, dynamic>;

      final assistantMsg = DoubtMessage(
        text: data['answer'] ?? '',
        isUser: false,
        source: data['source'],
        topic: data['topic'],
        disclaimer: data['compliance_disclaimer'] ?? AppConfig.complianceDisclaimer,
      );

      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, assistantMsg],
      );
    } catch (e) {
      final errorMsg = DoubtMessage(
        text: "I could not fetch an answer right now. Please check your connection or tap 'Talk to an Expert' below for a personal callback.",
        isUser: false,
        source: "error",
        disclaimer: AppConfig.complianceDisclaimer,
      );
      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, errorMsg],
      );
    }
  }

  Future<bool> requestCallback(String note) async {
    try {
      await _apiClient.post('/leads/request-callback', data: {'note': note});
      return true;
    } catch (_) {
      return false;
    }
  }
}

final doubtsProvider = StateNotifierProvider<DoubtsNotifier, DoubtsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoubtsNotifier(apiClient);
});
