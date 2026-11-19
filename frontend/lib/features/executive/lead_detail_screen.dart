import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../../config.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/utils/currency_formatter.dart';
import 'executive_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final int leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(executiveProvider.notifier).fetchLeadDetail(widget.leadId);
    });
  }

  Future<void> _downloadPdf(int userId) async {
    final url = "${AppConfig.baseUrl}/api/v1/reports/profile/$userId.pdf";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executiveProvider);
    final detail = state.selectedLeadDetail;

    if (state.isLoading && detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lead Details")),
        body: const Center(child: Text("Lead information not found.")),
      );
    }

    final leadInfo = detail['lead'] as Map<String, dynamic>;
    final customer = detail['customer'] as Map<String, dynamic>;
    final profile = detail['profile'] as Map<String, dynamic>?;
    final risk = detail['risk'] as Map<String, dynamic>?;
    final goals = (detail['goals'] as List? ?? []);
    final doubts = (detail['doubts'] as List? ?? []);
    final notes = (detail['notes'] as List? ?? []);
    final meetings = (detail['meetings'] as List? ?? []);
    final consent = detail['consent'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(customer['name'] ?? "Lead Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryTeal),
            tooltip: "Download PDF",
            onPressed: () => _downloadPdf(customer['id']),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(executiveProvider.notifier).fetchLeadDetail(widget.leadId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary
            _buildCustomerHeader(customer, leadInfo, profile),
            const SizedBox(height: 16),

            // Action Buttons Panel
            _buildActionButtonsPanel(leadInfo),
            const SizedBox(height: 20),

            // Personal & KYC Readiness Card
            if (profile != null) ...[
              _buildKycCard(profile),
              const SizedBox(height: 20),
            ],

            // Risk Assessment Card
            if (risk != null) ...[
              _buildRiskCard(risk),
              const SizedBox(height: 20),
            ],

            // Goals Breakdown
            _buildGoalsCard(goals),
            const SizedBox(height: 20),

            // Doubts Asked by Customer
            _buildDoubtsCard(doubts),
            const SizedBox(height: 20),

            // Internal Notes & Meeting History
            _buildNotesAndMeetingsCard(notes, meetings),
            const SizedBox(height: 20),

            // DPDP Consent Card
            if (consent != null) ...[
              _buildConsentCard(consent),
              const SizedBox(height: 20),
            ],

            const DisclaimerBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(Map<String, dynamic> customer, Map<String, dynamic> lead, Map<String, dynamic>? profile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                  child: Text(
                    (customer['name'] ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.primaryTeal),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        "${customer['email']} • +91 ${customer['mobile']}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        "City: ${profile?['city'] ?? 'N/A'} • Age: ${profile?['age'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (lead['status'] ?? 'Submitted').toString().toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ),
              ],
            ),
            if (lead['decision'] != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Text("Final Decision: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("${lead['decision']} (${lead['decision_rationale'] ?? ''})", style: const TextStyle(fontSize: 13, color: AppTheme.primaryTeal)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsPanel(Map<String, dynamic> lead) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: _showChangeStatusDialog,
          icon: const Icon(Icons.sync, size: 16),
          label: const Text("Update Status"),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: _showAddNoteDialog,
          icon: const Icon(Icons.note_add, size: 16),
          label: const Text("Add Note"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: _showScheduleMeetingDialog,
          icon: const Icon(Icons.calendar_month, size: 16),
          label: const Text("Schedule Meeting"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: _showSendMessageDialog,
          icon: const Icon(Icons.message, size: 16),
          label: const Text("Message Customer"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: _showDecisionDialog,
          icon: const Icon(Icons.gavel, size: 16),
          label: const Text("Record Final Decision"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildKycCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Personal & KYC Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _buildField("Occupation", (profile['occupation'] ?? 'N/A').toString().toUpperCase()),
            _buildField("Monthly Income", profile['income_range'] ?? 'N/A'),
            _buildField("Monthly Expenses", "₹${profile['monthly_expenses'] ?? 0}"),
            _buildField("Current Savings", "₹${profile['savings'] ?? 0}"),
            _buildField("Existing Loans / EMI", "₹${profile['loans_emi'] ?? 0}"),
            _buildField("Dependents", "${profile['dependents'] ?? 0}"),
            _buildField("PAN Number (Encrypted At Rest)", profile['has_pan'] == true ? (profile['pan_masked'] ?? 'Verified') : 'Not Provided'),
            _buildField("Bank Account Ready", profile['has_bank'] == true ? 'Yes' : 'No'),
            _buildField("Aadhaar-Linked Mobile", profile['has_aadhaar_linked_mobile'] == true ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(Map<String, dynamic> risk) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Risk Profiler Assessment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  (risk['category'] ?? '').toString().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                ),
              ],
            ),
            const Divider(height: 20),
            Text("Score: ${risk['total_score']} / 32", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(risk['explanation'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            Text(
              "Recommended: Equity ${risk['recommended_equity_pct']}% | Debt ${risk['recommended_debt_pct']}% | Gold ${risk['recommended_gold_pct']}%",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(List<dynamic> goals) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer Financial Goals (${goals.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            if (goals.isEmpty)
              const Text("No goals added yet.", style: TextStyle(color: Color(0xFF94A3B8)))
            else
              ...goals.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("${g['type']} • ${g['years']} years", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyFormatter.formatInr((g['future_cost'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("${CurrencyFormatter.formatInr((g['required_sip'] as num).toDouble())}/mo", style: const TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubtsCard(List<dynamic> doubts) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Doubts & Questions Asked (${doubts.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            if (doubts.isEmpty)
              const Text("No doubts asked yet.", style: TextStyle(color: Color(0xFF94A3B8)))
            else
              ...doubts.map((d) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Q: ${d['question']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text("Topic: ${d['topic'] ?? 'General'}", style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesAndMeetingsCard(List<dynamic> notes, List<dynamic> meetings) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Executive Internal Notes & Meetings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            const Text("Internal Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (notes.isEmpty)
              const Text("No internal notes recorded.", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
            else
              ...notes.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text("• ${n['note']} (${n['executive_name'] ?? 'Advisor'})", style: const TextStyle(fontSize: 12)),
              )),
            const SizedBox(height: 14),
            const Text("Scheduled Meetings:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (meetings.isEmpty)
              const Text("No meetings scheduled yet.", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
            else
              ...meetings.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text("• ${m['title']} at ${m['scheduled_at']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCard(Map<String, dynamic> consent) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DPDP Act 2023 Compliance & Consent", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            Text("Consent Timestamp: ${consent['consented_at']}", style: const TextStyle(fontSize: 12)),
            Text("Consent Version: ${consent['consent_version']}", style: const TextStyle(fontSize: 12)),
            Text("IP Address Recorded: ${consent['ip_address'] ?? 'Dev-Localhost'}", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // Dialogs
  void _showChangeStatusDialog() {
    String selected = 'Contacted';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Change Lead Status"),
          content: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: ['Submitted', 'Assigned', 'Contacted', 'Meeting Scheduled', 'Converted', 'Closed']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) setDialogState(() => selected = v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(executiveProvider.notifier).updateLeadStatus(widget.leadId, selected);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Internal Note"),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(hintText: "Enter observation or call notes..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref.read(executiveProvider.notifier).addLeadNote(widget.leadId, noteController.text.trim());
              }
            },
            child: const Text("Save Note"),
          ),
        ],
      ),
    );
  }

  void _showScheduleMeetingDialog() {
    final titleController = TextEditingController(text: "1-on-1 Portfolio Consultation");
    final linkController = TextEditingController(text: "https://meet.google.com/abc-defg-hij");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Schedule Meeting"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Meeting Title")),
            TextField(controller: linkController, decoration: const InputDecoration(labelText: "Meeting Link / Place")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(executiveProvider.notifier).scheduleMeeting(
                widget.leadId,
                title: titleController.text.trim(),
                scheduledAt: DateTime.now().add(const Duration(days: 1)),
                meetingLink: linkController.text.trim(),
              );
            },
            child: const Text("Schedule"),
          ),
        ],
      ),
    );
  }

  void _showSendMessageDialog() {
    final titleController = TextEditingController(text: "Message from your Wealth Advisor");
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Send Customer Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Notification Title")),
            TextField(controller: msgController, decoration: const InputDecoration(labelText: "Message"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(executiveProvider.notifier).sendLeadMessage(
                widget.leadId,
                title: titleController.text.trim(),
                message: msgController.text.trim(),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void _showDecisionDialog() {
    String decision = 'Approved';
    final rationaleController = TextEditingController(text: "Customer profile and asset allocation reviewed.");
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Record Final Decision"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: decision,
                isExpanded: true,
                items: ['Approved', 'Rejected', 'On-Hold']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => decision = v);
                },
              ),
              TextField(controller: rationaleController, decoration: const InputDecoration(labelText: "Rationale"), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(executiveProvider.notifier).recordDecision(
                  widget.leadId,
                  decision: decision,
                  rationale: rationaleController.text.trim(),
                );
              },
              child: const Text("Save Decision"),
            ),
          ],
        ),
      ),
    );
  }
}
