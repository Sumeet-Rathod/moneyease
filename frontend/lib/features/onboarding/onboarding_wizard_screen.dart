import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/disclaimer_banner.dart';
import 'onboarding_provider.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  DateTime? _selectedDob;
  String _selectedGender = "Male";
  final _cityController = TextEditingController();
  String _selectedOccupation = "salaried";

  // Step 2 Controllers
  String _selectedIncomeRange = "₹50,000 - ₹1,00,000";
  final _expensesController = TextEditingController(text: "30000");
  final _savingsController = TextEditingController(text: "100000");
  final _loansController = TextEditingController(text: "0");
  int _dependentsCount = 0;

  // Step 3: Investments Checkboxes
  final Map<String, bool> _investmentsSelected = {
    "FD": true,
    "MF": true,
    "Stocks": false,
    "PPF": false,
    "EPF": true,
    "Insurance": false,
    "Gold": false,
  };
  final Map<String, TextEditingController> _investmentAmountControllers = {
    "FD": TextEditingController(text: "50000"),
    "MF": TextEditingController(text: "50000"),
    "Stocks": TextEditingController(text: "0"),
    "PPF": TextEditingController(text: "0"),
    "EPF": TextEditingController(text: "50000"),
    "Insurance": TextEditingController(text: "0"),
    "Gold": TextEditingController(text: "0"),
  };

  // Step 4: KYC Readiness
  bool _hasPan = true;
  final _panController = TextEditingController(text: "ABCDE1234F");
  bool _hasAadhaarLinked = true;
  bool _hasBank = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing profile if available
    Future.microtask(() {
      final prof = ref.read(onboardingProvider).profile;
      if (prof != null) {
        if (prof.name.isNotEmpty) _nameController.text = prof.name;
        if (prof.city != null) _cityController.text = prof.city!;
        if (prof.dob != null) _selectedDob = DateTime.tryParse(prof.dob!);
        if (prof.gender != null) _selectedGender = prof.gender!;
        if (prof.occupation != null) _selectedOccupation = prof.occupation!;
        if (prof.incomeRange != null) _selectedIncomeRange = prof.incomeRange!;
        if (prof.monthlyExpenses > 0) _expensesController.text = prof.monthlyExpenses.toStringAsFixed(0);
        if (prof.savings > 0) _savingsController.text = prof.savings.toStringAsFixed(0);
        if (prof.loansEmi > 0) _loansController.text = prof.loansEmi.toStringAsFixed(0);
        _dependentsCount = prof.dependents;
        _hasPan = prof.hasPan;
        _hasAadhaarLinked = prof.hasAadhaarLinkedMobile;
        _hasBank = prof.hasBank;
        _currentStep = prof.onboardingStep.clamp(1, 7);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _expensesController.dispose();
    _savingsController.dispose();
    _loansController.dispose();
    _panController.dispose();
    for (var c in _investmentAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndNext() async {
    final notifier = ref.read(onboardingProvider.notifier);

    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        _showSnack("Please enter your full name.");
        return;
      }
      final dobStr = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null;
      await notifier.updateStep(1, {
        "name": _nameController.text.trim(),
        "dob": dobStr,
        "gender": _selectedGender,
        "city": _cityController.text.trim(),
        "occupation": _selectedOccupation,
      });
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      await notifier.updateStep(2, {
        "income_range": _selectedIncomeRange,
        "monthly_expenses": double.tryParse(_expensesController.text) ?? 0.0,
        "savings": double.tryParse(_savingsController.text) ?? 0.0,
        "loans_emi": double.tryParse(_loansController.text) ?? 0.0,
        "dependents": _dependentsCount,
      });
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      final List<Map<String, dynamic>> invs = [];
      _investmentsSelected.forEach((key, isChecked) {
        if (isChecked) {
          final amt = double.tryParse(_investmentAmountControllers[key]?.text ?? "0") ?? 0.0;
          invs.add({"type": key, "amount": amt});
        }
      });
      await notifier.updateStep(3, {"existing_investments": invs});
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      final panText = _panController.text.trim().toUpperCase();
      if (_hasPan && panText.isNotEmpty && panText.length != 10) {
        _showSnack("PAN must be exactly 10 alphanumeric characters (e.g. ABCDE1234F).");
        return;
      }
      final success = await notifier.updateStep(4, {
        "has_pan": _hasPan,
        "pan_number": _hasPan && panText.isNotEmpty ? panText : null,
        "has_aadhaar_linked_mobile": _hasAadhaarLinked,
        "has_bank": _hasBank,
      });
      if (success) {
        setState(() => _currentStep = 5);
      }
    } else if (_currentStep == 5) {
      // Risk Profiler redirect / next
      setState(() => _currentStep = 6);
    } else if (_currentStep == 6) {
      setState(() => _currentStep = 7);
    } else if (_currentStep == 7) {
      // Final Submit to Advisor
      context.go('/goals');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Profile Setup"),
        actions: [
          TextButton(
            onPressed: () => context.go('/goals'),
            child: const Text("Skip to App", style: TextStyle(color: Color(0xFF64748B))),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step $_currentStep of 7: ${_getStepTitle(_currentStep)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                      ),
                      Text(
                        "${((_currentStep / 7) * 100).toInt()}%",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep / 7.0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),

            if (onboardingState.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  onboardingState.errorMessage!,
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
                ),
              ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 1) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Back"),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentStep == 7 ? "Submit to Expert" : "Save & Continue",
                      isLoading: onboardingState.isLoading,
                      onPressed: _saveAndNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1: return "Personal Details";
      case 2: return "Income & Expenses";
      case 3: return "Existing Investments";
      case 4: return "KYC Readiness";
      case 5: return "Risk Profiling";
      case 6: return "Financial Goals";
      case 7: return "Review & Submit";
      default: return "";
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      case 5: return _buildStep5();
      case 6: return _buildStep6();
      case 7: return _buildStep7();
      default: return const SizedBox.shrink();
    }
  }

  // ----------------- Step 1: Personal Details -----------------
  Widget _buildStep1() {
    int? age;
    if (_selectedDob != null) {
      final now = DateTime.now();
      age = now.year - _selectedDob!.year - ((now.month < _selectedDob!.month || (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) ? 1 : 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Let's get acquainted", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("This helps our advisors curate age-appropriate schemes.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        CustomTextField(
          label: "Full Name",
          hint: "e.g. Rahul Sharma",
          controller: _nameController,
        ),

        const Text("Date of Birth", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (picked != null) {
              setState(() => _selectedDob = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob != null
                      ? "${DateFormat('dd MMM yyyy').format(_selectedDob!)} (Age: $age yrs)"
                      : "Select your Date of Birth",
                  style: TextStyle(
                    color: _selectedDob != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text("Gender", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        Row(
          children: ["Male", "Female", "Other"].map((g) {
            final selected = _selectedGender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ChoiceChip(
                label: Text(g),
                selected: selected,
                selectedColor: AppTheme.primaryTeal.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.primaryTeal : const Color(0xFF64748B),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedGender = g);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: "City / Location",
          hint: "e.g. Bengaluru, Mumbai, Pune",
          controller: _cityController,
        ),

        const Text("Occupation", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedOccupation,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
          items: const [
            DropdownMenuItem(value: "student", child: Text("Student / Fresher")),
            DropdownMenuItem(value: "salaried", child: Text("Salaried Professional")),
            DropdownMenuItem(value: "self-employed", child: Text("Self-Employed / Freelancer")),
            DropdownMenuItem(value: "business", child: Text("Business Owner")),
            DropdownMenuItem(value: "other", child: Text("Other")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedOccupation = val);
          },
        ),
      ],
    );
  }

  // ----------------- Step 2: Income & Expenses -----------------
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Income & Financial Commitments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Understand your surplus to determine sustainable SIP amounts.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        const Text("Monthly Take-Home Income Range", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedIncomeRange,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
          items: const [
            DropdownMenuItem(value: "Under ₹30,000", child: Text("Under ₹30,000")),
            DropdownMenuItem(value: "₹30,000 - ₹50,000", child: Text("₹30,000 – ₹50,000")),
            DropdownMenuItem(value: "₹50,000 - ₹1,00,000", child: Text("₹50,000 – ₹1,00,000")),
            DropdownMenuItem(value: "₹1,00,000 - ₹1,50,000", child: Text("₹1,00,000 – ₹1,50,000")),
            DropdownMenuItem(value: "₹1,50,000+", child: Text("₹1,50,000+")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedIncomeRange = val);
          },
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: "Estimated Monthly Living Expenses (₹)",
          hint: "e.g. 30000",
          controller: _expensesController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
        ),

        CustomTextField(
          label: "Current Total Savings / Bank Balance (₹)",
          hint: "e.g. 100000",
          controller: _savingsController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
        ),

        CustomTextField(
          label: "Existing Monthly Loans / EMIs (₹)",
          hint: "e.g. 5000 (Enter 0 if none)",
          controller: _loansController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
        ),

        const Text("Number of Financial Dependents", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Row(
          children: [0, 1, 2, 3, 4].map((cnt) {
            final selected = _dependentsCount == cnt;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(cnt >= 4 ? "4+" : cnt.toString()),
                selected: selected,
                selectedColor: AppTheme.primaryTeal.withOpacity(0.15),
                onSelected: (val) {
                  if (val) setState(() => _dependentsCount = cnt);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ----------------- Step 3: Existing Investments -----------------
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Existing Investments Portfolio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Select assets you already hold and approximate amounts.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        ..._investmentsSelected.keys.map((key) {
          final isChecked = _investmentsSelected[key]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _getInvestmentName(key),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    value: isChecked,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      setState(() => _investmentsSelected[key] = val ?? false);
                    },
                  ),
                  if (isChecked) ...[
                    const Divider(),
                    CustomTextField(
                      label: "Approximate Amount in $key (₹)",
                      hint: "e.g. 50000",
                      controller: _investmentAmountControllers[key],
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getInvestmentName(String code) {
    switch (code) {
      case "FD": return "Bank Fixed Deposit (FD)";
      case "MF": return "Mutual Funds";
      case "Stocks": return "Direct Equities / Stocks";
      case "PPF": return "Public Provident Fund (PPF)";
      case "EPF": return "Employee Provident Fund (EPF)";
      case "Insurance": return "Life Insurance (ULIP/Endowment)";
      case "Gold": return "Gold (Physical/SGB/Digital)";
      default: return code;
    }
  }

  // ----------------- Step 4: KYC Readiness -----------------
  Widget _buildStep4() {
    final panVal = _panController.text.trim().toUpperCase();
    String? maskedPreview;
    if (panVal.length >= 10) {
      maskedPreview = "XXXXX${panVal.substring(5, 9)}X";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("KYC & Regulatory Readiness", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Mutual fund distributors are mandated by SEBI/PMLA to verify investor KYC.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Do you possess a PAN Card?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Mandatory for regular mutual fund folios", style: TextStyle(fontSize: 12)),
                  value: _hasPan,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) => setState(() => _hasPan = val),
                ),
                if (_hasPan) ...[
                  const Divider(),
                  CustomTextField(
                    label: "Permanent Account Number (PAN)",
                    hint: "e.g. ABCDE1234F",
                    controller: _panController,
                    onChanged: (v) => setState(() {}),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Encrypted at rest with Fernet 256-bit. Displayed masked as: ${maskedPreview ?? 'XXXXX1234X'}",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text("Aadhaar linked with active mobile number", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text("Required for paperless instant Aadhaar e-KYC (No Aadhaar number stored)", style: TextStyle(fontSize: 12)),
                value: _hasAadhaarLinked,
                activeColor: AppTheme.primaryTeal,
                onChanged: (val) => setState(() => _hasAadhaarLinked = val ?? false),
              ),
              const Divider(height: 1),
              CheckboxListTile(
                title: const Text("Active Indian Bank Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text("For automated SIP auto-debits and redemption payouts", style: TextStyle(fontSize: 12)),
                value: _hasBank,
                activeColor: AppTheme.primaryTeal,
                onChanged: (val) => setState(() => _hasBank = val ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------- Step 5: Risk Profiling -----------------
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Risk Profiling Assessment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Understand your behavioral reaction to market dips.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                const Icon(Icons.speed_rounded, size: 48, color: AppTheme.primaryTeal),
                const SizedBox(height: 12),
                const Text(
                  "Interactive Risk Meter Questionnaire",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Take 2 minutes to answer 8 questions calibrating your optimal equity vs debt allocation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: "Open Risk Assessment",
                  icon: Icons.checklist_rtl_rounded,
                  onPressed: () => context.push('/risk'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ----------------- Step 6: Goals Setup -----------------
  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Map Your Life Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Tie your investments to tangible life milestones.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                const Icon(Icons.rocket_launch_rounded, size: 48, color: AppTheme.sageGreen),
                const SizedBox(height: 12),
                const Text(
                  "Goal Planner & Future Visualizer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Calculate your required monthly SIP for an Emergency Fund, buying a vehicle, home down payment, or wealth creation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: "Manage & Add Goals",
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.push('/goals'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ----------------- Step 7: Review & Submit -----------------
  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Review Your Financial Snapshot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Ready to submit your profile to an AMFI-registered advisor.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 16),

        const ComplianceDisclaimerBanner(),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow("Name", _nameController.text.isNotEmpty ? _nameController.text : "User"),
                _buildSummaryRow("City", _cityController.text.isNotEmpty ? _cityController.text : "N/A"),
                _buildSummaryRow("Occupation", _selectedOccupation.toUpperCase()),
                _buildSummaryRow("Monthly Income", _selectedIncomeRange),
                _buildSummaryRow("Monthly Expenses", "₹${_expensesController.text}"),
                _buildSummaryRow("Existing Savings", "₹${_savingsController.text}"),
                _buildSummaryRow("PAN Status", _hasPan ? "Provided (Masked)" : "Not Provided"),
                _buildSummaryRow("Bank & Aadhaar", _hasBank && _hasAadhaarLinked ? "Ready" : "Pending"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppTheme.primaryTeal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Upon submission, a certified wealth advisor will review your asset allocation and schedule a 1-on-1 discovery call.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF004D40), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
