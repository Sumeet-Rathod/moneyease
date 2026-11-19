import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num? amount, {bool includeDecimals = false}) {
    if (amount == null) return "₹0";
    if (includeDecimals) {
      return _inrFormatWithDecimals.format(amount);
    }
    return _inrFormat.format(amount);
  }

  static String formatInr(num? amount, {bool includeDecimals = false}) {
    return format(amount, includeDecimals: includeDecimals);
  }

  static String formatWords(num? amount) {
    if (amount == null || amount == 0) return "₹0";
    final absAmount = amount.abs().toDouble();

    if (absAmount >= 10000000) {
      final cr = absAmount / 10000000.0;
      return "${_trimTrailingZero(cr)} Crore";
    } else if (absAmount >= 100000) {
      final lakh = absAmount / 100000.0;
      return "${_trimTrailingZero(lakh)} Lakh";
    } else if (absAmount >= 1000) {
      final k = absAmount / 1000.0;
      return "${_trimTrailingZero(k)} Thousand";
    } else {
      return format(amount);
    }
  }

  static String _trimTrailingZero(double val) {
    String s = val.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }
}
