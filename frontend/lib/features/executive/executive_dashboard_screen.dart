import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import 'executive_provider.dart';

class ExecutiveDashboardScreen extends ConsumerStatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  ConsumerState<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends ConsumerState<ExecutiveDashboardScreen> {
  final _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'All',
    'Submitted',
    'Assigned',
    'Contacted',
    'Meeting Scheduled',
    'Converted',
    'Closed'
  ];

  final List<String> _riskOptions = [
    'All',
    'Conservative',
    'Moderate',
    'Aggressive'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(executiveProvider.notifier).fetchLeads();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executiveProvider);
    final notifier = ref.read(executiveProvider.notifier);
    final authUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text("Executive Lead Pipeline"),
          ],
        ),
        actions: [
          if (authUser?.role == 'admin')
            TextButton.icon(
              onPressed: () => context.push('/admin'),
              icon: const Icon(Icons.admin_panel_settings, size: 18),
              label: const Text("Admin Portal"),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.fetchLeads(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search & Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search customer by name, email, or mobile...",
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (val) => notifier.updateFilters(search: val.trim()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => notifier.updateFilters(search: _searchController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Search"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Status Filter
                        const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        DropdownButton<String>(
                          value: state.selectedStatusFilter,
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.updateFilters(status: val);
                          },
                        ),
                        const SizedBox(width: 20),

                        // Risk Filter
                        const Text("Risk: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        DropdownButton<String>(
                          value: state.selectedRiskFilter,
                          items: _riskOptions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.updateFilters(risk: val);
                          },
                        ),
                        const Spacer(),

                        // Assigned to me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: state.assignedToMeOnly,
                              activeColor: AppTheme.primaryTeal,
                              onChanged: (val) {
                                if (val != null) notifier.updateFilters(assignedToMe: val);
                              },
                            ),
                            const Text("Assigned to me", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Leads Count Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Customer Leads (${state.leads.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Text(
                  "Live database sync",
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Leads Data List / Table
            if (state.isLoading && state.leads.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (state.leads.isEmpty)
              _buildEmptyLeads()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.leads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lead = state.leads[index];
                  return _buildLeadItemCard(lead);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeads() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text("No leads match current filter criteria.", style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildLeadItemCard(LeadListItem lead) {
    Color riskColor = AppTheme.primaryTeal;
    if (lead.riskCategory.toLowerCase() == 'aggressive') {
      riskColor = AppTheme.secondaryCoral;
    } else if (lead.riskCategory.toLowerCase() == 'moderate') {
      riskColor = AppTheme.accentGold;
    }

    Color statusColor = const Color(0xFF0284C7);
    if (lead.status == 'Converted') statusColor = const Color(0xFF16A34A);
    if (lead.status == 'Closed') statusColor = const Color(0xFF64748B);

    return InkWell(
      onTap: () => context.push('/exec/leads/${lead.leadId}'),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          "${lead.city ?? 'India'} • ${lead.age != null ? '${lead.age} yrs' : 'Age N/A'}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Risk Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.riskCategory.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Target Cost (${lead.totalGoalsCount} Goals)", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        CurrencyFormatter.formatInr(lead.totalGoalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Monthly Required SIP", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        "${CurrencyFormatter.formatInr(lead.totalRequiredSip)}/mo",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Advisor", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        lead.assignedExecutiveName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
