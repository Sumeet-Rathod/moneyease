import 'package:flutter/foundation.dart';

class AppConfig {
  // AMFI Registered Mutual Fund Distributor Configuration
  static const String firmName = "MoneyEase Wealth Advisors";
  static const String arnNumber = "ARN-189452";
  static const String supportPhone = "+91 98765 43210";
  static const String supportEmail = "support@moneyease.in";
  static const String appVersion = "1.0.0";

  // Mandatory SEBI / AMFI Regulatory Compliance Disclaimer
  static const String complianceDisclaimer =
      "Mutual fund investments are subject to market risks, read all scheme related "
      "documents carefully. Projections are illustrative and based on assumed returns; "
      "they are not guaranteed.";

  // API Base URL
  // Uses localhost for Web & Desktop, and 10.0.2.2 for Android Emulator
  static String get apiBaseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api/v1";
    }
    // Default for Android Emulator / Mobile
    return "http://10.0.2.2:8000/api/v1";
  }

  // Base domain for raw endpoints (e.g. PDF downloads)
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    return "http://10.0.2.2:8000";
  }
}
