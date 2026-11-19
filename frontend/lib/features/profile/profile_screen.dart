import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../../config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/storage.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).fetchProfileData();
    });
  }

  Future<void> _downloadPdf(int userId) async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    final url = "${AppConfig.baseUrl}/api/v1/reports/profile/$userId.pdf?token=${token ?? ''}";

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch PDF download link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Financial Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(profileNotifierProvider.notifier).fetchProfileData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Identity Card
                  _buildUserHeaderCard(user, state.profile),
                  const SizedBox(height: 20),

                  // Lead Status Lifecycle Tracker
                  if (state.leadStatus != null) ...[
                    _buildLeadStatusTrackerCard(state.leadStatus!),
                    const SizedBox(height: 20),
                  ],

                  // Risk Profile Summary Card
                  if (state.risk != null) ...[
                    _buildRiskSummaryCard(state.risk!),
                    const SizedBox(height: 20),
                  ],

                  // Download PDF Snapshot Button
                  if (user != null)
                    CustomButton(
                      text: "Download Financial Snapshot (PDF)",
                      icon: Icons.picture_as_pdf,
                      onPressed: () => _downloadPdf(user.id),
                    ),
                  const SizedBox(height: 12),

                  // Edit Profile Button
                  CustomButton(
                    text: "Edit / Update Onboarding Details",
                    icon: Icons.edit_note,
                    isOutlined: true,
                    onPressed: () => context.push('/onboarding'),
                  ),
                  const SizedBox(height: 24),

                  // MFD Distributor Contact Card
                  _buildAdvisorContactCard(),
                  const SizedBox(height: 24),

                  const DisclaimerBanner(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeaderCard(dynamic user, CustomerProfileData? profile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                  child: Text(
                    (user?.name ?? "U").substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? "Customer",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      if (user?.mobile != null)
                        Text(
                          "+91 ${user?.mobile}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (profile != null) ...[
              const Divider(height: 24),
              _buildInfoRow("City", profile.city ?? "Not specified"),
              _buildInfoRow("Age", profile.age != null ? "${profile.age} years" : "N/A"),
              _buildInfoRow("Occupation", profile.occupation?.toUpperCase() ?? "N/A"),
              _buildInfoRow("Monthly Income Range", profile.incomeRange ?? "N/A"),
              _buildInfoRow("Permanent Account Number (PAN)", profile.hasPan ? (profile.panMasked ?? "Verified") : "Not Provided"),
              _buildInfoRow("Bank Account & Aadhaar", profile.hasBank && profile.hasAadhaarLinkedMobile ? "Ready" : "Pending"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadStatusTrackerCard(LeadStatusData lead) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Onboarding Progress Tracker",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lead.status.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ),
              ],
            ),
            if (lead.assignedExecutiveName != null) ...[
              const SizedBox(height: 8),
              Text(
                "Assigned Advisor: ${lead.assignedExecutiveName}",
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
            ],
            const Divider(height: 24),

            // Tracker Milestones
            ...List.generate(lead.tracker.length, (idx) {
              final step = lead.tracker[idx];
              final isLast = idx == lead.tracker.length - 1;

              Color iconColor = const Color(0xFFCBD5E1);
              IconData icon = Icons.radio_button_unchecked;

              if (step.isCompleted) {
                iconColor = AppTheme.primaryTeal;
                icon = Icons.check_circle;
              } else if (step.isCurrent) {
                iconColor = AppTheme.accentGold;
                icon = Icons.pending;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(icon, color: iconColor, size: 22),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: step.isCompleted ? AppTheme.primaryTeal : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.stage,
                            style: TextStyle(
                              fontWeight: step.isCurrent || step.isCompleted ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                              color: step.isCompleted || step.isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSummaryCard(dynamic risk) {
    Color badgeColor = AppTheme.primaryTeal;
    if (risk.category.toString().toLowerCase() == 'aggressive') {
      badgeColor = AppTheme.secondaryCoral;
    } else if (risk.category.toString().toLowerCase() == 'moderate') {
      badgeColor = AppTheme.accentGold;
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Assessed Risk Profile",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    risk.category.toString().toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              risk.explanation ?? "",
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildAssetPill("Equity", "${risk.recommendedEquityPct.toInt()}%", AppTheme.primaryTeal),
                const SizedBox(width: 8),
                _buildAssetPill("Debt", "${risk.recommendedDebtPct.toInt()}%", const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildAssetPill("Gold", "${risk.recommendedGoldPct.toInt()}%", AppTheme.accentGold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registered AMFI Distributor Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
          ),
          SizedBox(height: 8),
          Text("${AppConfig.firmName} | AMFI ARN: ${AppConfig.arnNumber}", style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          SizedBox(height: 4),
          Text("Email: ${AppConfig.supportEmail} | Phone: ${AppConfig.supportPhone}", style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
