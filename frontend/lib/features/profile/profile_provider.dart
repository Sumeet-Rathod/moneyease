import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../risk_profile/risk_provider.dart';

class CustomerProfileData {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String mobile;
  final String? dob;
  final int? age;
  final String? gender;
  final String? city;
  final String? occupation;
  final String? incomeRange;
  final double? monthlyExpenses;
  final double? savings;
  final double? loansEmi;
  final int? dependents;
  final Map<String, dynamic>? existingInvestments;
  final bool hasPan;
  final String? panMasked;
  final bool hasBank;
  final bool hasAadhaarLinkedMobile;
  final int onboardingStep;
  final bool completed;

  CustomerProfileData({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    this.dob,
    this.age,
    this.gender,
    this.city,
    this.occupation,
    this.incomeRange,
    this.monthlyExpenses,
    this.savings,
    this.loansEmi,
    this.dependents,
    this.existingInvestments,
    required this.hasPan,
    this.panMasked,
    required this.hasBank,
    required this.hasAadhaarLinkedMobile,
    required this.onboardingStep,
    required this.completed,
  });

  factory CustomerProfileData.fromJson(Map<String, dynamic> json) {
    return CustomerProfileData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      dob: json['dob'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      occupation: json['occupation'] as String?,
      incomeRange: json['income_range'] as String?,
      monthlyExpenses: (json['monthly_expenses'] as num?)?.toDouble(),
      savings: (json['savings'] as num?)?.toDouble(),
      loansEmi: (json['loans_emi'] as num?)?.toDouble(),
      dependents: json['dependents'] as int?,
      existingInvestments: json['existing_investments'] as Map<String, dynamic>?,
      hasPan: json['has_pan'] ?? false,
      panMasked: json['pan_masked'] as String?,
      hasBank: json['has_bank'] ?? false,
      hasAadhaarLinkedMobile: json['has_aadhaar_linked_mobile'] ?? false,
      onboardingStep: json['onboarding_step'] ?? 1,
      completed: json['completed'] ?? false,
    );
  }
}

class TrackerStep {
  final String stage;
  final String description;
  final bool isCompleted;
  final bool isCurrent;
  final String? date;

  TrackerStep({
    required this.stage,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    this.date,
  });

  factory TrackerStep.fromJson(Map<String, dynamic> json) {
    return TrackerStep(
      stage: json['stage'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      isCurrent: json['is_current'] ?? false,
      date: json['date'] as String?,
    );
  }
}

class LeadStatusData {
  final int leadId;
  final String status;
  final String? assignedExecutiveName;
  final String? assignedExecutiveEmail;
  final String? submittedAt;
  final String? updatedAt;
  final List<TrackerStep> tracker;

  LeadStatusData({
    required this.leadId,
    required this.status,
    this.assignedExecutiveName,
    this.assignedExecutiveEmail,
    this.submittedAt,
    this.updatedAt,
    required this.tracker,
  });

  factory LeadStatusData.fromJson(Map<String, dynamic> json) {
    return LeadStatusData(
      leadId: json['lead_id'] ?? 0,
      status: json['status'] ?? 'Submitted',
      assignedExecutiveName: json['assigned_executive_name'] as String?,
      assignedExecutiveEmail: json['assigned_executive_email'] as String?,
      submittedAt: json['submitted_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      tracker: (json['tracker'] as List? ?? [])
          .map((s) => TrackerStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProfileScreenState {
  final bool isLoading;
  final String? error;
  final CustomerProfileData? profile;
  final RiskProfileData? risk;
  final LeadStatusData? leadStatus;

  const ProfileScreenState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.risk,
    this.leadStatus,
  });

  ProfileScreenState copyWith({
    bool? isLoading,
    String? error,
    CustomerProfileData? profile,
    RiskProfileData? risk,
    LeadStatusData? leadStatus,
  }) {
    return ProfileScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      risk: risk ?? this.risk,
      leadStatus: leadStatus ?? this.leadStatus,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileScreenState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(const ProfileScreenState());

  Future<void> fetchProfileData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Fetch Customer Profile
      CustomerProfileData? profile;
      try {
        final pRes = await _apiClient.get('/onboarding/my-profile');
        if (pRes.data != null) {
          profile = CustomerProfileData.fromJson(pRes.data as Map<String, dynamic>);
        }
      } catch (_) {}

      // 2. Fetch Risk Profile
      RiskProfileData? risk;
      try {
        final rRes = await _apiClient.get('/risk/my-profile');
        if (rRes.data != null) {
          risk = RiskProfileData.fromJson(rRes.data as Map<String, dynamic>);
        }
      } catch (_) {}

      // 3. Fetch Lead Status & Lifecycle Tracker
      LeadStatusData? leadStatus;
      try {
        final lRes = await _apiClient.get('/leads/my-status');
        if (lRes.data != null) {
          leadStatus = LeadStatusData.fromJson(lRes.data as Map<String, dynamic>);
        }
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        profile: profile,
        risk: risk,
        leadStatus: leadStatus,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to load profile: $e");
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileScreenState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileNotifier(apiClient);
});
