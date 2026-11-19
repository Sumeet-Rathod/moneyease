import 'package:flutter/material.dart';
import '../../config.dart';

class ComplianceDisclaimerBanner extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry? margin;

  const ComplianceDisclaimerBanner({
    super.key,
    this.compact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.0 : 14.0,
        vertical: compact ? 8.0 : 12.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Warm Amber Light
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE65100),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  const Text(
                    "Regulatory Disclaimer",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                const Text(
                  AppConfig.complianceDisclaimer,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: Color(0xFF5D4037),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "MoneyEase Wealth Advisors • AMFI Reg. MFD: ARN-189452",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef DisclaimerBanner = ComplianceDisclaimerBanner;
