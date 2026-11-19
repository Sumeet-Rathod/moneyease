import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class CustomerProfileModel {
  final int id;
  final int userId;
  final String name;
  final String? email;
  final String? mobile;
  final String? dob;
  final int? age;
  final String? gender;
  final String? city;
  final String? occupation;
  final String? incomeRange;
  final double monthlyExpenses;
  final double savings;
  final double loansEmi;
  final int dependents;
  final List<dynamic> existingInvestments;
  final bool hasPan;
  final String? panMasked;
  final bool hasBank;
  final bool hasAadhaarLinkedMobile;
  final int onboardingStep;
  final bool completed;

  CustomerProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    this.dob,
    this.age,
    this.gender,
    this.city,
    this.occupation,
    this.incomeRange,
    this.monthlyExpenses = 0.0,
    this.savings = 0.0,
    this.loansEmi = 0.0,
    this.dependents = 0,
    this.existingInvestments = const [],
    this.hasPan = false,
    this.panMasked,
    this.hasBank = false,
    this.hasAadhaarLinkedMobile = false,
    this.onboardingStep = 1,
    this.completed = false,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      dob: json['dob'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      occupation: json['occupation'] as String?,
      incomeRange: json['income_range'] as String?,
      monthlyExpenses: (json['monthly_expenses'] as num?)?.toDouble() ?? 0.0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      loansEmi: (json['loans_emi'] as num?)?.toDouble() ?? 0.0,
      dependents: json['dependents'] as int? ?? 0,
      existingInvestments: json['existing_investments'] as List<dynamic>? ?? [],
      hasPan: json['has_pan'] as bool? ?? false,
      panMasked: json['pan_masked'] as String?,
      hasBank: json['has_bank'] as bool? ?? false,
      hasAadhaarLinkedMobile: json['has_aadhaar_linked_mobile'] as bool? ?? false,
      onboardingStep: json['onboarding_step'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class OnboardingState {
  final CustomerProfileModel? profile;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    CustomerProfileModel? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.get('/profile');
      final model = CustomerProfileModel.fromJson(res.data);
      state = state.copyWith(profile: model, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> updateStep(int step, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.put('/profile/step/$step', data: data);
      final model = CustomerProfileModel.fromJson(res.data);
      state = state.copyWith(profile: model, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
      return false;
    }
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
