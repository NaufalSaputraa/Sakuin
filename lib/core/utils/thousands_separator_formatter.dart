import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Input formatter that formats numbers with Indonesian thousand separator ('.').
/// Only allows digits 0-9; non-digit characters are stripped and the number
/// is re-formatted with '.' as the thousand separator on every change.
/// Example: "1000000" → "1.000.000", "100000" → "100.000", "1000" → "1.000"
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits 0-9
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format with '.' as thousand separator (id_ID locale)
    final formatted = _formatWithDotSeparator(digits);

    // Move cursor to the end
    final selection = TextSelection.collapsed(offset: formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: selection,
    );
  }

  /// Formats a string of digits with '.' as thousand separator.
  /// e.g., "1000000" → "1.000.000", "100000" → "100.000", "1000" → "1.000", "0" → "0"
  String _formatWithDotSeparator(String digits) {
    if (digits.isEmpty) return '';

    // Remove leading zeros but keep at least one digit
    final normalized = digits.replaceAll(RegExp(r'^0+'), '');
    final numStr = normalized.isEmpty ? '0' : normalized;

    // Parse as int to handle grouping
    final intValue = int.tryParse(numStr);
    if (intValue == null) return numStr;

    // Format using NumberFormat.id_ID for grouping
    final formatted = NumberFormat('#.###', 'id_ID').format(intValue);
    // NumberFormat.id_ID may use '.' as separator already, but ensure consistency
    return formatted;
  }
}

