import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/calculator.dart';
import 'goals_provider.dart';

class FutureVisualizerScreen extends ConsumerStatefulWidget {
  const FutureVisualizerScreen({super.key});

  @override
  ConsumerState<FutureVisualizerScreen> createState() => _FutureVisualizerScreenState();
}

class _FutureVisualizerScreenState extends ConsumerState<FutureVisualizerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Interactive SIP Slider State
  double _sliderMonthlySip = 10000.0;
  double _sliderYears = 15.0;
  double _sliderReturn = 12.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Future Visualizer"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart, size: 20), text: "Growth Trajectory"),
            Tab(icon: Icon(Icons.bar_chart, size: 20), text: "Goals Comparison"),
            Tab(icon: Icon(Icons.timeline, size: 20), text: "Future Timeline"),
            Tab(icon: Icon(Icons.tune, size: 20), text: "SIP Simulator"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrajectoryTab(goalsState),
          _buildGoalsComparisonTab(goalsState),
          _buildFutureTimelineTab(goalsState),
          _buildSipSimulatorTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: Growth Trajectory (Line Chart: Invested vs Projected Value)
  // -------------------------------------------------------------
  Widget _buildTrajectoryTab(GoalsState state) {
    if (state.goals.isEmpty) {
      return _buildNoGoalsNotice();
    }

    // Determine max years among all goals
    double maxYears = 5.0;
    for (final g in state.goals) {
      if (g.years > maxYears) maxYears = g.years;
    }
    final int yearsCount = maxYears.ceil();

    // Compute aggregated year-by-year curve
    final List<FlSpot> investedSpots = [];
    final List<FlSpot> projectedSpots = [];

    final double totalMonthlySip = state.totalRequiredMonthlySip;
    const double assumedRate = 0.12;

    for (int y = 0; y <= yearsCount; y++) {
      if (y == 0) {
        investedSpots.add(FlSpot(0, state.totalSavedAmount));
        projectedSpots.add(FlSpot(0, state.totalSavedAmount));
      } else {
        final double invested = state.totalSavedAmount + (totalMonthlySip * 12 * y);
        // Compound growth
        final res = FinancialCalculator.simulateSip(
          monthlySip: totalMonthlySip,
          years: y.toDouble(),
          annualReturn: assumedRate * 100,
        );
        final double projected = (state.totalSavedAmount * (1 + (assumedRate * y))) + res.futureValue;
        investedSpots.add(FlSpot(y.toDouble(), invested));
        projectedSpots.add(FlSpot(y.toDouble(), projected));
      }
    }

    final double maxY = projectedSpots.isNotEmpty ? projectedSpots.last.y * 1.15 : 1000000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Portfolio Wealth Accumulation",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Compounded projected value vs total principal invested over time",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          // Chart Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: yearsCount.toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final isProjected = spot.barIndex == 1;
                                return LineTooltipItem(
                                  "${isProjected ? 'Projected' : 'Invested'}: ${CurrencyFormatter.formatInr(spot.y)}",
                                  TextStyle(
                                    color: isProjected ? AppTheme.primaryTeal : const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) {
                                if (val % 2 != 0 && yearsCount > 6) return const SizedBox.shrink();
                                return Text("Yr ${val.toInt()}", style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (val, meta) {
                                if (val == 0) return const Text("₹0", style: TextStyle(fontSize: 10));
                                return Text(CurrencyFormatter.formatWords(val), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)));
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 100000,
                          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Line 0: Total Invested (Blue)
                          LineChartBarData(
                            spots: investedSpots,
                            isCurved: true,
                            color: const Color(0xFF3B82F6),
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                          // Line 1: Projected Value (Teal with fill gradient)
                          LineChartBarData(
                            spots: projectedSpots,
                            isCurved: true,
                            color: AppTheme.primaryTeal,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryTeal.withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("Total Invested", const Color(0xFF3B82F6)),
                      const SizedBox(width: 24),
                      _buildLegendItem("Projected Wealth (12% Return)", AppTheme.primaryTeal),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const DisclaimerBanner(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Goals Comparison (Bar Chart: Target vs Saved)
  // -------------------------------------------------------------
  Widget _buildGoalsComparisonTab(GoalsState state) {
    if (state.goals.isEmpty) {
      return _buildNoGoalsNotice();
    }

    final List<BarChartGroupData> barGroups = [];
    double maxCost = 100000;

    for (int i = 0; i < state.goals.length; i++) {
      final g = state.goals[i];
      if (g.futureCost > maxCost) maxCost = g.futureCost;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: g.futureCost,
              color: AppTheme.primaryTeal,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: g.savedAmount,
              color: const Color(0xFF94A3B8),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Side-by-Side Goals Target vs Saved",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Target future cost compared to currently saved capital across each milestone",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: BarChart(
                      BarChartData(
                        maxY: maxCost * 1.15,
                        barGroups: barGroups,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 64,
                              getTitlesWidget: (val, meta) {
                                if (val == 0) return const Text("₹0", style: TextStyle(fontSize: 9));
                                return Text(CurrencyFormatter.formatWords(val), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < state.goals.length) {
                                  final name = state.goals[idx].name;
                                  return Text(
                                    name.length > 8 ? "${name.substring(0, 7)}.." : name,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("Target Future Cost", AppTheme.primaryTeal),
                      const SizedBox(width: 24),
                      _buildLegendItem("Already Saved", const Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const DisclaimerBanner(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Future Timeline (Horizontal & Vertical Milestones with User Age)
  // -------------------------------------------------------------
  Widget _buildFutureTimelineTab(GoalsState state) {
    if (state.goals.isEmpty) {
      return _buildNoGoalsNotice();
    }

    // Sort goals by years
    final sortedGoals = List<GoalModel>.from(state.goals)
      ..sort((a, b) => a.years.compareTo(b.years));

    const int userCurrentAge = 25; // Default reference age if not available

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Your Future Milestone Timeline",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Chronological milestone roadmap showing targets and estimated age",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Horizontal / Vertical Timeline Cards
          ...List.generate(sortedGoals.length, (index) {
            final g = sortedGoals[index];
            final targetYear = DateTime.now().year + g.years.toInt();
            final targetAge = userCurrentAge + g.years.toInt();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline column indicator
                Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    if (index < sortedGoals.length - 1)
                      Container(
                        width: 3,
                        height: 90,
                        color: const Color(0xFFCBD5E1),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Milestone Details Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              g.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Year $targetYear",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Estimated Age: $targetAge years old (${g.years.toInt()} years from now)",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Target Cost", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                Text(
                                  CurrencyFormatter.formatInr(g.futureCost),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Monthly SIP", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                Text(
                                  "${CurrencyFormatter.formatInr(g.requiredSip)}/mo",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 20),
          const DisclaimerBanner(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: Interactive SIP Slider ("What if I invest ₹X/month?")
  // -------------------------------------------------------------
  Widget _buildSipSimulatorTab() {
    final simResult = FinancialCalculator.simulateSip(
      monthlySip: _sliderMonthlySip,
      years: _sliderYears,
      annualReturn: _sliderReturn,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Interactive SIP Simulator",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Slide to visualize how small regular investments compound into massive future wealth",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Output Result Big Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00796B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Expected Corpus at Maturity",
                  style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.formatInr(simResult.futureValue),
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.formatWords(simResult.futureValue),
                  style: const TextStyle(color: AppTheme.accentGold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Total Invested", style: TextStyle(color: Color(0xFF99F6E4), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatInr(simResult.totalInvested),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text("Estimated Wealth Gain", style: TextStyle(color: Color(0xFF99F6E4), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatInr(simResult.wealthGained),
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sliders Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Slider 1: Monthly Investment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Monthly SIP Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        CurrencyFormatter.formatInr(_sliderMonthlySip),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 15),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sliderMonthlySip,
                    min: 1000,
                    max: 100000,
                    divisions: 99,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      setState(() => _sliderMonthlySip = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Slider 2: Investment Horizon (Years)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Investment Horizon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        "${_sliderYears.toInt()} Years",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 15),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sliderYears,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      setState(() => _sliderYears = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Slider 3: Expected Annual Return (%)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Expected Annual Return", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        "${_sliderReturn.toStringAsFixed(1)}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 15),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sliderReturn,
                    min: 6,
                    max: 18,
                    divisions: 24,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      setState(() => _sliderReturn = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const DisclaimerBanner(),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNoGoalsNotice() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              "No Goals Created Yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 8),
            Text(
              "Add goals in the Goal Planner to view projections, timeline milestones, and comparative charts.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
