import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String? devOtp;

  const OtpScreen({
    super.key,
    required this.mobile,
    this.devOtp,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String? _errorMessage;
  String? _currentDevOtp;

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.devOtp;
    if (_currentDevOtp != null && _currentDevOtp!.isNotEmpty) {
      _otpController.text = _currentDevOtp!;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMessage = "Please enter the full 6-digit code.");
      return;
    }

    setState(() => _errorMessage = null);
    final success = await ref.read(authProvider.notifier).verifyOtp(widget.mobile, otp);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (success) {
      if (authState.role == 'executive' || authState.role == 'admin') {
        context.go('/executive');
      } else {
        context.go('/onboarding');
      }
    } else {
      setState(() => _errorMessage = authState.errorMessage ?? "Invalid OTP entered.");
    }
  }

  Future<void> _resendOtp() async {
    final newOtp = await ref.read(authProvider.notifier).requestOtp(widget.mobile);
    if (!mounted) return;
    if (newOtp != null) {
      setState(() {
        _currentDevOtp = newOtp;
        _otpController.text = newOtp;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A new OTP has been sent!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Enter Verification Code"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We sent a 6-digit verification code to +91 ${widget.mobile}",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 16),

              if (_currentDevOtp != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Dev Simulation OTP: $_currentDevOtp",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
                  ),
                ),

              CustomTextField(
                label: "6-Digit OTP",
                hint: "123456",
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.lock_clock_outlined),
              ),

              const SizedBox(height: 10),
              CustomButton(
                text: "Verify & Continue",
                isLoading: authState.isLoading,
                onPressed: _verifyOtp,
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    "Didn't receive code? Resend OTP",
                    style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
