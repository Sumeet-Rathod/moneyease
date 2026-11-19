import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'executive_provider.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(executiveProvider.notifier);
      n.fetchAdminStats();
      n.fetchAdminExecutives();
      n.fetchAdminFaqs();
      n.fetchAdminSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Admin Operations Portal"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryTeal,
          indicatorColor: AppTheme.primaryTeal,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: "Analytics & Stats"),
            Tab(icon: Icon(Icons.people_alt_outlined), text: "Manage Advisors"),
            Tab(icon: Icon(Icons.quiz_outlined), text: "FAQ Knowledge Base"),
            Tab(icon: Icon(Icons.settings_outlined), text: "Return Rates & Rules"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildAdvisorsTab(),
          _buildFaqsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ---------------- TAB 1: Analytics & Stats ----------------
  Widget _buildStatsTab() {
    final state = ref.watch(executiveProvider);
    final stats = state.adminStats;

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSignups = stats['total_signups'] ?? 0;
    final totalCompleted = stats['total_profiles_completed'] ?? 0;
    final conversionRate = stats['conversion_rate'] ?? 0.0;
    final statusCounts = (stats['leads_by_status'] as Map<String, dynamic>? ?? {});
    final execCounts = (stats['leads_per_executive'] as Map<String, dynamic>? ?? {});

    // Pie chart sections for status
    final colors = [
      AppTheme.primaryTeal,
      const Color(0xFF0284C7),
      AppTheme.accentGold,
      const Color(0xFF16A34A),
      const Color(0xFF94A3B8),
    ];
    int cIdx = 0;
    final List<PieChartSectionData> pieSections = [];
    statusCounts.forEach((k, v) {
      final double val = (v as num).toDouble();
      if (val > 0) {
        pieSections.add(
          PieChartSectionData(
            value: val,
            title: "$k\n${val.toInt()}",
            color: colors[cIdx % colors.length],
            radius: 54,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
        cIdx++;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildMetricCard("Total Customers", "$totalSignups", Icons.group),
              const SizedBox(width: 12),
              _buildMetricCard("Completed Onboarding", "$totalCompleted", Icons.verified),
              const SizedBox(width: 12),
              _buildMetricCard("Conversion Rate", "${conversionRate.toStringAsFixed(1)}%", Icons.trending_up),
            ],
          ),
          const SizedBox(height: 24),

          // Status Pie Chart
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Leads Distribution by Pipeline Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  if (pieSections.isEmpty)
                    const Text("No lead data available.")
                  else
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(sections: pieSections, centerSpaceRadius: 40),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Leads Per Executive
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Assigned Leads Per Wealth Advisor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 20),
                  ...execCounts.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text("${e.value} leads", style: const TextStyle(fontSize: 13, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryTeal, size: 22),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB 2: Manage Advisors ----------------
  Widget _buildAdvisorsTab() {
    final state = ref.watch(executiveProvider);
    final execs = state.executives;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Wealth Advisors (${execs.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: _showAddAdvisorDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text("Add Advisor"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...execs.map((e) {
            final bool isActive = e['is_active'] ?? true;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                  child: Text((e['name'] ?? 'A')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                ),
                title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${e['email']} • +91 ${e['mobile']}", style: const TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: isActive,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) {
                    ref.read(executiveProvider.notifier).toggleExecutiveActive(e['id'], val);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddAdvisorDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: "Exec@123");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Wealth Advisor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email Address")),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: "Mobile Number")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Initial Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(executiveProvider.notifier).createExecutive(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                password: passCtrl.text.trim(),
              );
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  // ---------------- TAB 3: FAQ Knowledge Base ----------------
  Widget _buildFaqsTab() {
    final state = ref.watch(executiveProvider);
    final faqs = state.faqs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Verified FAQ Articles (${faqs.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: _showAddFaqDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add FAQ"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...faqs.map((f) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ExpansionTile(
              title: Text(f['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Topic: ${f['topic'] ?? 'General'}", style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  ref.read(executiveProvider.notifier).deleteFaq(f['id']);
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(f['answer'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showAddFaqDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final tCtrl = TextEditingController(text: "Mutual Funds");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add FAQ Knowledge Article"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qCtrl, decoration: const InputDecoration(labelText: "Question")),
            TextField(controller: aCtrl, decoration: const InputDecoration(labelText: "Answer"), maxLines: 3),
            TextField(controller: tCtrl, decoration: const InputDecoration(labelText: "Topic")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(executiveProvider.notifier).createFaq(
                question: qCtrl.text.trim(),
                answer: aCtrl.text.trim(),
                topic: tCtrl.text.trim(),
              );
            },
            child: const Text("Save FAQ"),
          ),
        ],
      ),
    );
  }

  // ---------------- TAB 4: Return Rates & Rules ----------------
  Widget _buildSettingsTab() {
    final state = ref.watch(executiveProvider);
    final settings = state.settings;

    final consCtrl = TextEditingController(text: "${settings['return_conservative'] ?? 8.0}");
    final modCtrl = TextEditingController(text: "${settings['return_moderate'] ?? 10.0}");
    final aggCtrl = TextEditingController(text: "${settings['return_aggressive'] ?? 12.0}");
    final emergCtrl = TextEditingController(text: "${settings['return_emergency'] ?? 6.0}");
    final infCtrl = TextEditingController(text: "${settings['inflation_rate'] ?? 6.0}");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Assumed Return Rates & Inflation Rules", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            "These baseline return rates power the future goal projections across the app.",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CustomTextField(
                    label: "Conservative Assumed Return (%)",
                    controller: consCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: "Moderate Assumed Return (%)",
                    controller: modCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: "Aggressive Assumed Return (%)",
                    controller: aggCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: "Emergency Fund Return (%)",
                    controller: emergCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: "Default Inflation Rate (%)",
                    controller: infCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: "Update Settings",
                    icon: Icons.save,
                    onPressed: () async {
                      final updated = {
                        'return_conservative': double.tryParse(consCtrl.text) ?? 8.0,
                        'return_moderate': double.tryParse(modCtrl.text) ?? 10.0,
                        'return_aggressive': double.tryParse(aggCtrl.text) ?? 12.0,
                        'return_emergency': double.tryParse(emergCtrl.text) ?? 6.0,
                        'inflation_rate': double.tryParse(infCtrl.text) ?? 6.0,
                      };
                      final success = await ref.read(executiveProvider.notifier).updateAdminSettings(updated);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? "Settings updated successfully!" : "Failed to update settings.")),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
