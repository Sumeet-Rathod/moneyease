import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/disclaimer_banner.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/calculator.dart';
import 'goals_provider.dart';

class GoalEditorScreen extends ConsumerStatefulWidget {
  final GoalModel? initialGoal;

  const GoalEditorScreen({super.key, this.initialGoal});

  @override
  ConsumerState<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends ConsumerState<GoalEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _yearsController;
  late TextEditingController _savedController;
  late TextEditingController _inflationController;
  late TextEditingController _returnController;
  late TextEditingController _stepUpController;

  String _selectedType = "Wealth Creation";
  bool _enableStepUp = false;
  GoalCalculationResult? _previewResult;

  final List<String> _goalTypes = [
    "Emergency Fund",
    "Higher Education",
    "Buying a Bike/Car",
    "Home Down Payment",
    "Marriage",
    "Travel",
    "Retirement",
    "Wealth Creation",
    "Custom",
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.initialGoal;
    _selectedType = g?.type ?? "Wealth Creation";
    _nameController = TextEditingController(text: g?.name ?? "My Financial Goal");
    _costController = TextEditingController(text: g != null ? g.currentCost.toInt().toString() : "1000000");
    _yearsController = TextEditingController(text: g != null ? g.years.toString() : "10");
    _savedController = TextEditingController(text: g != null ? g.savedAmount.toInt().toString() : "100000");
    _inflationController = TextEditingController(text: g != null ? g.inflation.toString() : "6.0");
    _returnController = TextEditingController(text: g != null ? g.assumedReturn.toString() : (_selectedType == "Emergency Fund" ? "6.0" : "10.0"));
    _enableStepUp = (g != null && g.stepUpPct > 0);
    _stepUpController = TextEditingController(text: g != null ? g.stepUpPct.toString() : "10.0");

    _recomputePreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _yearsController.dispose();
    _savedController.dispose();
    _inflationController.dispose();
    _returnController.dispose();
    _stepUpController.dispose();
    super.dispose();
  }

  void _recomputePreview() {
    final cost = double.tryParse(_costController.text.replaceAll(',', '')) ?? 0.0;
    final years = double.tryParse(_yearsController.text) ?? 1.0;
    final saved = double.tryParse(_savedController.text.replaceAll(',', '')) ?? 0.0;
    final inf = double.tryParse(_inflationController.text) ?? 6.0;
    final ret = double.tryParse(_returnController.text) ?? 10.0;
    final stepUp = _enableStepUp ? (double.tryParse(_stepUpController.text) ?? 0.0) : 0.0;

    setState(() {
      _previewResult = FinancialCalculator.calculateGoal(
        currentCost: cost,
        years: years,
        savedAmount: saved,
        annualReturn: ret,
        inflationRate: inf,
        stepUpPct: stepUp,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGoal != null;
    final goalsState = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Goal" : "Create New Goal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Goal Type Selector
              const Text("Goal Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _goalTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          if (val == "Emergency Fund") {
                            _returnController.text = "6.0";
                            _inflationController.text = "6.0";
                          }
                        });
                        _recomputePreview();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Goal Name
              CustomTextField(
                label: "Goal Name",
                controller: _nameController,
                hintText: "e.g. Higher Education, Car Down Payment",
                prefixIcon: const Icon(Icons.flag_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter a goal name" : null,
              ),
              const SizedBox(height: 16),

              // Current Cost
              CustomTextField(
                label: "Today's Cost (₹)",
                controller: _costController,
                hintText: "e.g. 1000000",
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.currency_rupee),
                onChanged: (_) => _recomputePreview(),
                validator: (v) {
                  final val = double.tryParse(v?.replaceAll(',', '') ?? '');
                  if (val == null || val <= 0) return "Enter a valid positive cost";
                  return null;
                },
              ),
              if (_previewResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0, left: 4.0),
                  child: Text(
                    "In words: ${CurrencyFormatter.formatWords(_previewResult!.currentCost)}",
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                  ),
                ),

              // Years to Goal
              CustomTextField(
                label: "Years to Goal",
                controller: _yearsController,
                hintText: "e.g. 5, 10, 15",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                onChanged: (_) => _recomputePreview(),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return "Enter valid years (> 0)";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Saved Amount
              CustomTextField(
                label: "Amount Already Saved for this Goal (₹)",
                controller: _savedController,
                hintText: "e.g. 50000",
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.savings_outlined),
                onChanged: (_) => _recomputePreview(),
              ),
              if (_previewResult != null && _previewResult!.savedAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0, left: 4.0),
                  child: Text(
                    "Saved: ${CurrencyFormatter.formatWords(_previewResult!.savedAmount)}",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 8),

              // Rates Row (Inflation & Assumed Return)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Inflation Rate (%)",
                      controller: _inflationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.trending_up, size: 18),
                      onChanged: (_) => _recomputePreview(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Assumed Return (%)",
                      controller: _returnController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.percent, size: 18),
                      onChanged: (_) => _recomputePreview(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step-up SIP Option
              CheckboxListTile(
                value: _enableStepUp,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryTeal,
                title: const Text("Enable Step-Up SIP (Increase SIP yearly)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onChanged: (val) {
                  setState(() => _enableStepUp = val ?? false);
                  _recomputePreview();
                },
              ),
              if (_enableStepUp) ...[
                CustomTextField(
                  label: "Yearly Step-Up Percentage (%)",
                  controller: _stepUpController,
                  hintText: "e.g. 10.0",
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recomputePreview(),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),
              // Live Projection Preview Card
              if (_previewResult != null) _buildCalculationSummaryCard(_previewResult!),

              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? "Save Changes" : "Create Goal",
                icon: Icons.check_circle_outline,
                isLoading: goalsState.isLoading,
                onPressed: _saveGoal,
              ),

              const SizedBox(height: 24),
              const DisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationSummaryCard(GoalCalculationResult res) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph, color: AppTheme.primaryTeal, size: 20),
                SizedBox(width: 8),
                Text(
                  "Goal Projection Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildResultRow("Future Cost (Inflation Adjusted)", CurrencyFormatter.formatInr(res.futureCost), highlight: false),
            _buildResultRow("In words", CurrencyFormatter.formatWords(res.futureCost), isSubtitle: true),
            const SizedBox(height: 8),
            _buildResultRow("FV of Existing Savings", CurrencyFormatter.formatInr(res.fvSaved)),
            _buildResultRow("Net Funding Gap", CurrencyFormatter.formatInr(res.gap)),
            const Divider(height: 20),
            _buildResultRow(
              "Required Monthly SIP",
              CurrencyFormatter.formatInr(res.requiredSip),
              highlight: true,
              color: AppTheme.primaryTeal,
            ),
            if (res.stepUpPct > 0)
              _buildResultRow(
                "Starting Step-up SIP (${res.stepUpPct.toInt()}% / yr)",
                CurrencyFormatter.formatInr(res.startingStepUpSip),
                highlight: true,
                color: const Color(0xFF0284C7),
              ),
            const SizedBox(height: 8),
            _buildResultRow("Lumpsum Needed Today", CurrencyFormatter.formatInr(res.requiredLumpsum)),
            _buildResultRow("In words", CurrencyFormatter.formatWords(res.requiredLumpsum), isSubtitle: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false, Color? color, bool isSubtitle = false}) {
    if (isSubtitle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.parse(_costController.text.replaceAll(',', ''));
    final years = double.parse(_yearsController.text);
    final saved = double.tryParse(_savedController.text.replaceAll(',', '')) ?? 0.0;
    final inf = double.tryParse(_inflationController.text) ?? 6.0;
    final ret = double.tryParse(_returnController.text) ?? 10.0;
    final stepUp = _enableStepUp ? (double.tryParse(_stepUpController.text) ?? 0.0) : 0.0;

    final notifier = ref.read(goalsProvider.notifier);

    if (widget.initialGoal != null) {
      final success = await notifier.updateGoal(
        id: widget.initialGoal!.id,
        name: _nameController.text.trim(),
        currentCost: cost,
        years: years,
        savedAmount: saved,
        inflation: inf,
        assumedReturn: ret,
        stepUpPct: stepUp,
      );
      if (success && mounted) {
        context.pop();
      }
    } else {
      final success = await notifier.addGoal(
        name: _nameController.text.trim(),
        type: _selectedType,
        currentCost: cost,
        years: years,
        savedAmount: saved,
        inflation: inf,
        assumedReturn: ret,
        stepUpPct: stepUp,
      );
      if (success && mounted) {
        context.pop();
      }
    }
  }
}
