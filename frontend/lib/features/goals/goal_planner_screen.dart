import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/utils/currency_formatter.dart';
import 'goals_provider.dart';
import 'goal_editor_screen.dart';

class GoalPlannerScreen extends ConsumerStatefulWidget {
  const GoalPlannerScreen({super.key});

  @override
  ConsumerState<GoalPlannerScreen> createState() => _GoalPlannerScreenState();
}

class _GoalPlannerScreenState extends ConsumerState<GoalPlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Goal Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph),
            tooltip: "Future Visualizer & Charts",
            onPressed: () => context.push('/goals/visualizer'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Goals",
            onPressed: () => ref.read(goalsProvider.notifier).fetchGoals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGoalEditor(null),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Goal"),
      ),
      body: goalsState.isLoading && goalsState.goals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(goalsProvider.notifier).fetchGoals(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Portfolio Aggregate Header
                    _buildAggregateHeader(goalsState),
                    const SizedBox(height: 20),

                    // Visualizer Shortcut Banner
                    InkWell(
                      onTap: () => context.push('/goals/visualizer'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryTeal.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.insights, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Future Visualizer & Timeline",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Interactive charts, timeline milestones & SIP slider",
                                    style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Goals List Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Financial Goals (${goalsState.goals.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        TextButton.icon(
                          onPressed: () => _openGoalEditor(null),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("New Goal"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (goalsState.goals.isEmpty)
                      _buildEmptyGoalsState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: goalsState.goals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final goal = goalsState.goals[index];
                          return _buildGoalCard(goal);
                        },
                      ),

                    const SizedBox(height: 32),
                    const DisclaimerBanner(),
                    const SizedBox(height: 60), // Space for FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAggregateHeader(GoalsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Future Financial Target",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatInr(state.totalTargetFutureCost),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          Text(
            CurrencyFormatter.formatWords(state.totalTargetFutureCost),
            style: const TextStyle(fontSize: 13, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Required SIP", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      "${CurrencyFormatter.formatInr(state.totalRequiredMonthlySip)}/mo",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Already Saved", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatInr(state.totalSavedAmount),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, size: 48, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Goals Added Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create your first financial milestone (e.g. Emergency Fund, Higher Education, Home Down Payment).",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: "Create My First Goal",
            icon: Icons.add,
            onPressed: () => _openGoalEditor(null),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    IconData iconData = Icons.star_border;
    if (goal.type == "Emergency Fund") iconData = Icons.shield_outlined;
    if (goal.type == "Higher Education") iconData = Icons.school_outlined;
    if (goal.type == "Buying a Bike/Car") iconData = Icons.directions_car_outlined;
    if (goal.type == "Home Down Payment") iconData = Icons.home_outlined;
    if (goal.type == "Marriage") iconData = Icons.favorite_border;
    if (goal.type == "Travel") iconData = Icons.flight_takeoff;
    if (goal.type == "Retirement") iconData = Icons.beach_access_outlined;
    if (goal.type == "Wealth Creation") iconData = Icons.trending_up;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: AppTheme.primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              goal.type,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "In ${goal.years.toInt()} years",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == "edit") {
                      _openGoalEditor(goal);
                    } else if (val == "delete") {
                      _confirmDelete(goal);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "edit", child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit")])),
                    const PopupMenuItem(value: "delete", child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Target Future Value", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatInr(goal.futureCost),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      CurrencyFormatter.formatWords(goal.futureCost),
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Required Monthly SIP", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      "${CurrencyFormatter.formatInr(goal.requiredSip)}/mo",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                    ),
                    if (goal.stepUpPct > 0)
                      Text(
                        "${goal.stepUpPct.toInt()}% Step-up SIP",
                        style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openGoalEditor(GoalModel? goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalEditorScreen(initialGoal: goal)),
    );
  }

  void _confirmDelete(GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Goal?"),
        content: Text("Are you sure you want to delete '${goal.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(goalsProvider.notifier).deleteGoal(goal.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
