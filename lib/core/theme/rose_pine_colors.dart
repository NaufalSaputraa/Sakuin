import 'package:flutter/material.dart';

/// Rose Pine accent palettes inspired by Pennywise's Theme.kt.
///
/// Each entry defines a full accent set (primary, container, onContainer)
/// for both light and dark mode so every picker swatch stays readable.
class RosePineAccents {
  RosePineAccents._();

  // ── Accent Definitions ──────────────────────────────────────────────

  static const rose = RosePineAccent(
    name: 'Rose',
    light: Color(0xFFD4687A),
    lightContainer: Color(0xFFFBDCE1),
    dark: Color(0xFFF2A0B0),
    darkContainer: Color(0xFF5A2832),
  );

  static const love = RosePineAccent(
    name: 'Love',
    light: Color(0xFFC9493D),
    lightContainer: Color(0xFFFDDDDA),
    dark: Color(0xFFEB756A),
    darkContainer: Color(0xFF5C2320),
  );

  static const gold = RosePineAccent(
    name: 'Gold',
    light: Color(0xFFD4A72C),
    lightContainer: Color(0xFFFDF3D7),
    dark: Color(0xFFF2D06B),
    darkContainer: Color(0xFF4F4420),
  );

  static const iris = RosePineAccent(
    name: 'Iris',
    light: Color(0xFF7B6EBF),
    lightContainer: Color(0xFFE8E3F8),
    dark: Color(0xFFB8ACE6),
    darkContainer: Color(0xFF332D5A),
  );

  static const pine = RosePineAccent(
    name: 'Pine',
    light: Color(0xFF286983),
    lightContainer: Color(0xFFD0E7F0),
    dark: Color(0xFF5CB8D4),
    darkContainer: Color(0xFF1E3E4C),
  );

  static const foam = RosePineAccent(
    name: 'Foam',
    light: Color(0xFF3ABFA0),
    lightContainer: Color(0xFFD5F5EC),
    dark: Color(0xFF6DDCC5),
    darkContainer: Color(0xFF1E4F44),
  );

  static const moss = RosePineAccent(
    name: 'Moss',
    light: Color(0xFF56943B),
    lightContainer: Color(0xFFDFF0D3),
    dark: Color(0xFF8ACD6B),
    darkContainer: Color(0xFF2A4420),
  );

  static const hawaiian = RosePineAccent(
    name: 'Coral',
    light: Color(0xFFE07A5F),
    lightContainer: Color(0xFFFDE2D6),
    dark: Color(0xFFF0A48C),
    darkContainer: Color(0xFF5C3024),
  );

  static const blush = RosePineAccent(
    name: 'Blush',
    light: Color(0xFFBE50A0),
    lightContainer: Color(0xFFF7DCF0),
    dark: Color(0xFFE88FCC),
    darkContainer: Color(0xFF4E2440),
  );

  static const teal = RosePineAccent(
    name: 'Teal',
    light: Color(0xFF00796B),
    lightContainer: Color(0xFFCCE8E3),
    dark: Color(0xFF4DB6AC),
    darkContainer: Color(0xFF1A3C38),
  );

  static const lavender = RosePineAccent(
    name: 'Lavender',
    light: Color(0xFF9575CD),
    lightContainer: Color(0xFFEDE7F6),
    dark: Color(0xFFC9A8F0),
    darkContainer: Color(0xFF3A2D52),
  );

  static const peach = RosePineAccent(
    name: 'Peach',
    light: Color(0xFFEF6C00),
    lightContainer: Color(0xFFFFE0B2),
    dark: Color(0xFFFFAB40),
    darkContainer: Color(0xFF4D3010),
  );

  // ── Registry ────────────────────────────────────────────────────────

  static const List<RosePineAccent> all = [
    rose,
    love,
    gold,
    iris,
    pine,
    foam,
    moss,
    hawaiian,
    blush,
    teal,
    lavender,
    peach,
  ];

  /// Lookup by [name] (case-insensitive). Falls back to [rose].
  static RosePineAccent byName(String name) {
    for (final accent in all) {
      if (accent.name.toLowerCase() == name.toLowerCase()) return accent;
    }
    return rose;
  }
}

/// Single Rose Pine accent descriptor.
class RosePineAccent {
  final String name;
  final Color light;
  final Color lightContainer;
  final Color dark;
  final Color darkContainer;

  const RosePineAccent({
    required this.name,
    required this.light,
    required this.lightContainer,
    required this.dark,
    required this.darkContainer,
  });
}
