import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mobile OTP controllers
  final _mobileController = TextEditingController();

  // Email / Password controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sign up controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regMobileController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _consentAccepted = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regMobileController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleOtpRequest() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length < 10) {
      setState(() => _errorMessage = "Please enter a valid 10-digit mobile number");
      return;
    }
    if (!_consentAccepted) {
      setState(() => _errorMessage = "Consent under DPDP Act 2023 is required to continue.");
      return;
    }

    setState(() => _errorMessage = null);
    final devOtp = await ref.read(authProvider.notifier).requestOtp(mobile);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.errorMessage != null) {
      setState(() => _errorMessage = authState.errorMessage);
    } else {
      context.push('/otp', extra: {'mobile': mobile, 'dev_otp': devOtp});
    }
  }

  Future<void> _handlePasswordLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter your email/mobile and password");
      return;
    }

    setState(() => _errorMessage = null);
    final success = await ref.read(authProvider.notifier).login(identifier, password);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (success) {
      if (authState.role == 'executive' || authState.role == 'admin') {
        context.go('/executive');
      } else {
        context.go('/goals');
      }
    } else {
      setState(() => _errorMessage = authState.errorMessage ?? "Invalid credentials.");
    }
  }

  Future<void> _handleRegistration() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final mobile = _regMobileController.text.trim();
    final password = _regPasswordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = "Full Name is required.");
      return;
    }
    if (email.isEmpty && mobile.isEmpty) {
      setState(() => _errorMessage = "Please provide an email or mobile number.");
      return;
    }
    if (!_consentAccepted) {
      setState(() => _errorMessage = "DPDP Act consent is mandatory.");
      return;
    }

    setState(() => _errorMessage = null);
    final success = await ref.read(authProvider.notifier).register(
      name: name,
      email: email.isNotEmpty ? email : null,
      mobile: mobile.isNotEmpty ? mobile : null,
      password: password.isNotEmpty ? password : null,
      consentAccepted: _consentAccepted,
    );
    if (!mounted) return;

    if (success) {
      context.go('/onboarding');
    } else {
      final authState = ref.read(authProvider);
      setState(() => _errorMessage = authState.errorMessage ?? "Registration failed.");
    }
  }

  void _fillSampleCredentials(String email, String pwd) {
    _tabController.animateTo(1);
    _emailController.text = email;
    _passwordController.text = pwd;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Welcome to MoneyEase"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          indicatorColor: AppTheme.primaryTeal,
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: "Mobile OTP"),
            Tab(text: "Email Login"),
            Tab(text: "Sign Up"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Mobile OTP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Enter your mobile number to get started with a secure OTP.",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: "Mobile Number",
                          hint: "e.g. 9876543210",
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Text("+91 ", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        _buildConsentCheckbox(),
                        const Spacer(),
                        CustomButton(
                          text: "Get OTP",
                          isLoading: authState.isLoading,
                          onPressed: _handleOtpRequest,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                    // Tab 2: Email & Password Login
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Log in with your email or mobile and password.",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: "Email or Mobile",
                          hint: "e.g. rahul.sharma@example.com",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                        ),
                        CustomTextField(
                          label: "Password",
                          hint: "••••••••",
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                        const Spacer(),
                        CustomButton(
                          text: "Log In",
                          isLoading: authState.isLoading,
                          onPressed: _handlePasswordLogin,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                    // Tab 3: Sign Up
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: "Full Name",
                          hint: "e.g. Rahul Sharma",
                          controller: _regNameController,
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: "Email",
                                hint: "rahul@example.com",
                                controller: _regEmailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: "Mobile",
                                hint: "9876543210",
                                controller: _regMobileController,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        CustomTextField(
                          label: "Create Password",
                          hint: "At least 6 characters",
                          controller: _regPasswordController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                        _buildConsentCheckbox(),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: "Create Free Account",
                          isLoading: authState.isLoading,
                          onPressed: _handleRegistration,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 36),

              // Demo Quick-Fill Hints
              const Text(
                "⚡ Quick Fill Test Credentials:",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text("Admin"),
                    onPressed: () => _fillSampleCredentials("admin@moneyease.local", "Admin@123"),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.badge, size: 16),
                    label: const Text("Exec: Amit"),
                    onPressed: () => _fillSampleCredentials("amit.verma@moneyease.local", "Exec@123"),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: const Text("Cust: Rahul"),
                    onPressed: () => _fillSampleCredentials("rahul.sharma@example.com", "Customer@123"),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: const Text("Cust: Ananya"),
                    onPressed: () => _fillSampleCredentials("ananya.patel@example.com", "Customer@123"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _consentAccepted,
            activeColor: AppTheme.primaryTeal,
            onChanged: (val) {
              setState(() => _consentAccepted = val ?? false);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            "I consent to MoneyEase collecting & processing my financial information to generate goal projections and provide AMFI-compliant advisory support under India's Digital Personal Data Protection (DPDP) Act, 2023.",
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
          ),
        ),
      ],
    );
  }
}
