import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate({String pattern = 'd MMM yyyy'}) {
    return DateFormat(pattern).format(this);
  }

  String toFormattedTime({String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension ColorExtensions on String {
  Color toColor() {
    final hexCode = replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    } else if (hexCode.length == 8) {
      return Color(int.parse(hexCode, radix: 16));
    }
    return const Color(0xFF6B5CE7);
  }
}
