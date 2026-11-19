import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/disclaimer_banner.dart';
import 'risk_provider.dart';

class RiskProfilerScreen extends ConsumerStatefulWidget {
  const RiskProfilerScreen({super.key});

  @override
  ConsumerState<RiskProfilerScreen> createState() => _RiskProfilerScreenState();
}

class _RiskProfilerScreenState extends ConsumerState<RiskProfilerScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riskProvider.notifier).loadQuestionsAndProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final riskState = ref.watch(riskProvider);
    final notifier = ref.read(riskProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Risk Profiler"),
        actions: [
          if (riskState.currentProfile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Retake Assessment",
              onPressed: () {
                setState(() => _currentStep = 0);
              },
            ),
        ],
      ),
      body: riskState.isLoading && riskState.questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (riskState.currentProfile != null && _currentStep == 0 && riskState.selectedAnswers.isEmpty)
                    _buildExistingResultCard(riskState.currentProfile!)
                  else
                    _buildQuestionnaireFlow(riskState, notifier),
                  const SizedBox(height: 24),
                  const DisclaimerBanner(),
                ],
              ),
            ),
    );
  }

  Widget _buildExistingResultCard(RiskProfileData profile) {
    Color meterColor;
    if (profile.category.toLowerCase() == 'aggressive') {
      meterColor = AppTheme.secondaryCoral;
    } else if (profile.category.toLowerCase() == 'moderate') {
      meterColor = AppTheme.accentGold;
    } else {
      meterColor = AppTheme.primaryTeal;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: meterColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.category.toUpperCase(),
                style: TextStyle(
                  color: meterColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Total Score: ${profile.totalScore} / 32",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            // Visual Gauge Meter
            _buildGaugeMeter(profile.category),
            const SizedBox(height: 20),
            Text(
              profile.explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Recommended Asset Allocation",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildAssetBar("Equity", profile.recommendedEquityPct, AppTheme.primaryTeal),
                const SizedBox(width: 8),
                _buildAssetBar("Debt", profile.recommendedDebtPct, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildAssetBar("Gold", profile.recommendedGoldPct, AppTheme.accentGold),
              ],
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: "Retake Risk Assessment",
              icon: Icons.refresh,
              isOutlined: true,
              onPressed: () {
                setState(() => _currentStep = 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeMeter(String category) {
    double position = 0.5;
    if (category.toLowerCase() == 'conservative') position = 0.16;
    if (category.toLowerCase() == 'aggressive') position = 0.84;

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00796B), // Conservative Teal
                    Color(0xFFF59E0B), // Moderate Gold
                    Color(0xFFEF4444), // Aggressive Coral/Red
                  ],
                ),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final double left = (constraints.maxWidth - 20) * position;
              return Container(
                margin: EdgeInsets.only(left: left),
                width: 20,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Conservative", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00796B))),
            Text("Moderate", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
            Text("Aggressive", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
          ],
        )
      ],
    );
  }

  Widget _buildAssetBar(String name, double pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              "${pct.toInt()}%",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireFlow(RiskState state, RiskNotifier notifier) {
    if (state.questions.isEmpty) {
      return const Center(child: Text("No questions available."));
    }

    final question = state.questions[_currentStep];
    final selectedOption = state.selectedAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${_currentStep + 1} of ${state.questions.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            Text(
              question.category,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentStep + 1) / state.questions.length,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryTeal),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 24),

        // Question Title
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.4),
                ),
                const SizedBox(height: 20),
                ...List.generate(question.options.length, (index) {
                  final opt = question.options[index];
                  final isSelected = selectedOption == index;
                  return InkWell(
                    onTap: () {
                      notifier.selectAnswer(question.id, index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppTheme.primaryTeal : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? AppTheme.primaryTeal : const Color(0xFF334155),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CustomButton(
                  text: "Previous",
                  isOutlined: true,
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: _currentStep == state.questions.length - 1 ? "Submit Profile" : "Next Question",
                isLoading: state.isLoading,
                onPressed: selectedOption == null
                    ? null
                    : () async {
                        if (_currentStep < state.questions.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          final result = await notifier.submitAnswers();
                          if (result != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Risk Profile computed: ${result.category}!")),
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
