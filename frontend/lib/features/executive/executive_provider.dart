import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class LeadListItem {
  final int leadId;
  final int userId;
  final String name;
  final int? age;
  final String? city;
  final String riskCategory;
  final int totalGoalsCount;
  final double totalGoalAmount;
  final double totalRequiredSip;
  final String status;
  final int? assignedExecutiveId;
  final String assignedExecutiveName;
  final String? submittedAt;
  final String? updatedAt;

  LeadListItem({
    required this.leadId,
    required this.userId,
    required this.name,
    this.age,
    this.city,
    required this.riskCategory,
    required this.totalGoalsCount,
    required this.totalGoalAmount,
    required this.totalRequiredSip,
    required this.status,
    this.assignedExecutiveId,
    required this.assignedExecutiveName,
    this.submittedAt,
    this.updatedAt,
  });

  factory LeadListItem.fromJson(Map<String, dynamic> json) {
    return LeadListItem(
      leadId: json['lead_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      age: json['age'] as int?,
      city: json['city'] as String?,
      riskCategory: json['risk_category'] ?? 'Not Assessed',
      totalGoalsCount: json['total_goals_count'] ?? 0,
      totalGoalAmount: (json['total_goal_amount'] as num?)?.toDouble() ?? 0.0,
      totalRequiredSip: (json['total_required_sip'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Submitted',
      assignedExecutiveId: json['assigned_executive_id'] as int?,
      assignedExecutiveName: json['assigned_executive_name'] ?? 'Unassigned',
      submittedAt: json['submitted_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class ExecutiveState {
  final bool isLoading;
  final String? error;
  final List<LeadListItem> leads;
  final String selectedStatusFilter;
  final String selectedRiskFilter;
  final String searchQuery;
  final bool assignedToMeOnly;
  final Map<String, dynamic>? selectedLeadDetail;
  final Map<String, dynamic>? adminStats;
  final List<dynamic> executives;
  final List<dynamic> faqs;
  final Map<String, dynamic> settings;

  const ExecutiveState({
    this.isLoading = false,
    this.error,
    this.leads = const [],
    this.selectedStatusFilter = 'All',
    this.selectedRiskFilter = 'All',
    this.searchQuery = '',
    this.assignedToMeOnly = false,
    this.selectedLeadDetail,
    this.adminStats,
    this.executives = const [],
    this.faqs = const [],
    this.settings = const {},
  });

  ExecutiveState copyWith({
    bool? isLoading,
    String? error,
    List<LeadListItem>? leads,
    String? selectedStatusFilter,
    String? selectedRiskFilter,
    String? searchQuery,
    bool? assignedToMeOnly,
    Map<String, dynamic>? selectedLeadDetail,
    Map<String, dynamic>? adminStats,
    List<dynamic>? executives,
    List<dynamic>? faqs,
    Map<String, dynamic>? settings,
  }) {
    return ExecutiveState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      leads: leads ?? this.leads,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedRiskFilter: selectedRiskFilter ?? this.selectedRiskFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      assignedToMeOnly: assignedToMeOnly ?? this.assignedToMeOnly,
      selectedLeadDetail: selectedLeadDetail ?? this.selectedLeadDetail,
      adminStats: adminStats ?? this.adminStats,
      executives: executives ?? this.executives,
      faqs: faqs ?? this.faqs,
      settings: settings ?? this.settings,
    );
  }
}

class ExecutiveNotifier extends StateNotifier<ExecutiveState> {
  final ApiClient _apiClient;

  ExecutiveNotifier(this._apiClient) : super(const ExecutiveState());

  Future<void> fetchLeads() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, dynamic>{
        'assigned_to_me': state.assignedToMeOnly,
        if (state.selectedStatusFilter != 'All') 'status': state.selectedStatusFilter,
        if (state.selectedRiskFilter != 'All') 'risk': state.selectedRiskFilter,
        if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
      };

      final res = await _apiClient.get('/exec/leads', queryParameters: queryParams);
      final items = (res.data['items'] as List)
          .map((i) => LeadListItem.fromJson(i as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, leads: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to load leads: $e");
    }
  }

  void updateFilters({
    String? status,
    String? risk,
    String? search,
    bool? assignedToMe,
  }) {
    state = state.copyWith(
      selectedStatusFilter: status ?? state.selectedStatusFilter,
      selectedRiskFilter: risk ?? state.selectedRiskFilter,
      searchQuery: search ?? state.searchQuery,
      assignedToMeOnly: assignedToMe ?? state.assignedToMeOnly,
    );
    fetchLeads();
  }

  Future<void> fetchLeadDetail(int leadId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get('/exec/leads/$leadId');
      state = state.copyWith(isLoading: false, selectedLeadDetail: res.data as Map<String, dynamic>);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to load lead details: $e");
    }
  }

  Future<bool> updateLeadStatus(int leadId, String newStatus, {int? assignExecId}) async {
    try {
      await _apiClient.put('/exec/leads/$leadId/status', queryParameters: {
        'status': newStatus,
        if (assignExecId != null) 'assigned_executive_id': assignExecId,
      });
      await fetchLeadDetail(leadId);
      await fetchLeads();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addLeadNote(int leadId, String note) async {
    try {
      await _apiClient.post('/exec/leads/$leadId/notes', data: {'note': note});
      await fetchLeadDetail(leadId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> scheduleMeeting(int leadId, {
    required String title,
    required DateTime scheduledAt,
    String? meetingLink,
    String? notes,
  }) async {
    try {
      await _apiClient.post('/exec/leads/$leadId/meetings', data: {
        'title': title,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'meeting_link': meetingLink,
        'notes': notes,
      });
      await fetchLeadDetail(leadId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendLeadMessage(int leadId, {required String title, required String message}) async {
    try {
      await _apiClient.post('/exec/leads/$leadId/message', data: {
        'title': title,
        'message': message,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordDecision(int leadId, {required String decision, required String rationale}) async {
    try {
      await _apiClient.post('/exec/leads/$leadId/decision', data: {
        'decision': decision,
        'rationale': rationale,
      });
      await fetchLeadDetail(leadId);
      await fetchLeads();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ----------------- Admin Operations -----------------
  Future<void> fetchAdminStats() async {
    try {
      final res = await _apiClient.get('/admin/stats');
      state = state.copyWith(adminStats: res.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> fetchAdminExecutives() async {
    try {
      final res = await _apiClient.get('/admin/executives');
      state = state.copyWith(executives: res.data as List);
    } catch (_) {}
  }

  Future<bool> createExecutive({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      await _apiClient.post('/admin/executives', data: {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
      });
      await fetchAdminExecutives();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleExecutiveActive(int execId, bool isActive) async {
    try {
      await _apiClient.put('/admin/executives/$execId', data: {
        'is_active': isActive,
      });
      await fetchAdminExecutives();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchAdminFaqs() async {
    try {
      final res = await _apiClient.get('/admin/faqs');
      state = state.copyWith(faqs: res.data as List);
    } catch (_) {}
  }

  Future<bool> createFaq({
    required String question,
    required String answer,
    required String topic,
    List<String> tags = const [],
  }) async {
    try {
      await _apiClient.post('/admin/faqs', data: {
        'question': question,
        'answer': answer,
        'topic': topic,
        'tags': tags,
      });
      await fetchAdminFaqs();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFaq(int id) async {
    try {
      await _apiClient.delete('/admin/faqs/$id');
      await fetchAdminFaqs();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchAdminSettings() async {
    try {
      final res = await _apiClient.get('/admin/settings');
      state = state.copyWith(settings: res.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<bool> updateAdminSettings(Map<String, dynamic> newSettings) async {
    try {
      final res = await _apiClient.put('/admin/settings', data: newSettings);
      state = state.copyWith(settings: res.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final executiveProvider = StateNotifierProvider<ExecutiveNotifier, ExecutiveState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExecutiveNotifier(apiClient);
});
