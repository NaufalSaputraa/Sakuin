import 'package:intl/intl.dart';

class IndonesianAmountParser {
  static final RegExp _amountRegex = RegExp(
    r'(?:rp\.?\s*)?([0-9.,]+)\s*(k|rb|ribu|jt|juta|m|miliar|b|billion)?',
    caseSensitive: false,
  );

  /// Parses text like "25rb", "1.5jt", "1,5jt", "500k", "Rp 50.000", "25000" into a double value.
  static double? parse(String input) {
    final clean = input.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final match = _amountRegex.firstMatch(clean);
    if (match == null) return null;

    var numberStr = match.group(1);
    if (numberStr == null || numberStr.isEmpty) return null;

    final unit = match.group(2)?.toLowerCase();

    // Check if dot/comma is decimal vs thousand separator
    if (numberStr.contains('.') && numberStr.contains(',')) {
      // e.g. 1.500,50 -> 1500.50 or 1,500.50 -> 1500.50
      if (numberStr.indexOf('.') < numberStr.indexOf(',')) {
        numberStr = numberStr.replaceAll('.', '').replaceAll(',', '.');
      } else {
        numberStr = numberStr.replaceAll(',', '');
      }
    } else if (numberStr.contains('.')) {
      final parts = numberStr.split('.');
      if (parts.length == 2 && parts[1].length != 3) {
        // e.g. 1.5 with unit -> decimal
      } else if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3 && unit == null)) {
        // e.g. 50.000 -> 50000
        numberStr = numberStr.replaceAll('.', '');
      }
    } else if (numberStr.contains(',')) {
      final parts = numberStr.split(',');
      if (parts.length == 2 && parts[1].length != 3) {
        numberStr = numberStr.replaceAll(',', '.');
      } else if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3 && unit == null)) {
        numberStr = numberStr.replaceAll(',', '');
      } else {
        numberStr = numberStr.replaceAll(',', '.');
      }
    }

    final baseNumber = double.tryParse(numberStr);
    if (baseNumber == null) return null;

    if (unit == null) return baseNumber;

    switch (unit) {
      case 'k':
      case 'rb':
      case 'ribu':
        return baseNumber * 1000;
      case 'jt':
      case 'juta':
        return baseNumber * 1000000;
      case 'm':
      case 'miliar':
      case 'b':
      case 'billion':
        return baseNumber * 1000000000;
      default:
        return baseNumber;
    }
  }
}

class RupiahFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterNoSymbol = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  /// Formats amount into "Rp 50.000" or "50.000" (no decimals).
  static String format(double amount, {bool showSymbol = true}) {
    if (showSymbol) {
      return _formatter.format(amount).trim();
    } else {
      return _formatterNoSymbol.format(amount).trim();
    }
  }

  /// Compact representation: "50 rb", "1,5 jt" (Indonesian locale comma decimal)
  static String compact(double amount) {
    if (amount >= 1000000000) {
      final val = (amount / 1000000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return '$val M';
    } else if (amount >= 1000000) {
      final val = (amount / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return '$val jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return format(amount);
  }
}
