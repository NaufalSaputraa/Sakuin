import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'color_schemes.dart';

// ── Accent Color ─────────────────────────────────────────────────────

/// Stored accent name (one of the 12 Rose Pine names or 'default').
class AccentColorState {
  final String accentName;

  const AccentColorState({this.accentName = 'default'});

  AccentColorState copyWith({String? accentName}) {
    return AccentColorState(accentName: accentName ?? this.accentName);
  }
}

class AccentColorNotifier extends Notifier<AccentColorState> {
  @override
  AccentColorState build() {
    // Load from prefs asynchronously; default applied immediately.
    _loadFromPrefs();
    return const AccentColorState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.accentColorKey) ?? 'default';
    state = AccentColorState(accentName: name);
  }

  Future<void> setAccent(String name) async {
    state = AccentColorState(accentName: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accentColorKey, name);
  }
}

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, AccentColorState>(
  AccentColorNotifier.new,
);

// ── Dynamic Wallpaper ────────────────────────────────────────────────

class DynamicWallpaperState {
  final bool enabled;

  const DynamicWallpaperState({this.enabled = false});

  DynamicWallpaperState copyWith({bool? enabled}) {
    return DynamicWallpaperState(enabled: enabled ?? this.enabled);
  }
}

class DynamicWallpaperNotifier extends Notifier<DynamicWallpaperState> {
  @override
  DynamicWallpaperState build() {
    _loadFromPrefs();
    return const DynamicWallpaperState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(AppConstants.dynamicWallpaperKey) ?? false;
    state = DynamicWallpaperState(enabled: on);
  }

  Future<void> toggle() async {
    final next = !state.enabled;
    state = DynamicWallpaperState(enabled: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.dynamicWallpaperKey, next);
  }
}

final dynamicWallpaperProvider =
    NotifierProvider<DynamicWallpaperNotifier, DynamicWallpaperState>(
  DynamicWallpaperNotifier.new,
);

// ── Resolved ColorScheme ─────────────────────────────────────────────

/// Builds a complete [ColorScheme] that merges:
/// 1. Optional Material You dynamic seed (wallpaper color).
/// 2. Rose Pine accent override from the picker.
///
/// Consumers should watch this provider instead of hard-coding
/// `SakuinColors.lightScheme` / `darkScheme`.
final resolvedColorSchemeProvider =
    Provider.family<ColorScheme, Brightness>((ref, brightness) {
  final accentState = ref.watch(accentColorProvider);
  final dynamicState = ref.watch(dynamicWallpaperProvider);

  // Start from the static Sakuin base palette.
  ColorScheme base;
  if (brightness == Brightness.light) {
    base = SakuinColors.lightScheme;
  } else {
    base = SakuinColors.darkScheme;
  }

  // If dynamic wallpaper is enabled and the platform supports it,
  // derive the seed from the wallpaper.  Falls back to `base` if
  // the platform callback is null (desktop / unsupported).
  if (dynamicState.enabled) {
    base = ColorScheme.fromSeed(
      seedColor: base.primary,
      brightness: brightness,
    );
  }

  // Apply Rose Pine accent override if not 'default'.
  if (accentState.accentName != 'default') {
    final accent = _resolveAccent(accentState.accentName);
    if (accent != null) {
      final isDark = brightness == Brightness.dark;
      final primary = isDark ? accent.dark : accent.light;
      final container = isDark ? accent.darkContainer : accent.lightContainer;
      base = base.copyWith(
        primary: primary,
        primaryContainer: container,
        onPrimaryContainer: primary,
      );
    }
  }

  return base;
});

/// Maps a name to one of the 12 Rose Pine accent descriptors.
_AccentEntry? _resolveAccent(String name) {
  const map = <String, _AccentEntry>{
    'rose': _AccentEntry(Color(0xFFD4687A), Color(0xFFFBDCE1), Color(0xFFF2A0B0), Color(0xFF5A2832)),
    'love': _AccentEntry(Color(0xFFC9493D), Color(0xFFFDDDDA), Color(0xFFEB756A), Color(0xFF5C2320)),
    'gold': _AccentEntry(Color(0xFFD4A72C), Color(0xFFFDF3D7), Color(0xFFF2D06B), Color(0xFF4F4420)),
    'iris': _AccentEntry(Color(0xFF7B6EBF), Color(0xFFE8E3F8), Color(0xFFB8ACE6), Color(0xFF332D5A)),
    'pine': _AccentEntry(Color(0xFF286983), Color(0xFFD0E7F0), Color(0xFF5CB8D4), Color(0xFF1E3E4C)),
    'foam': _AccentEntry(Color(0xFF3ABFA0), Color(0xFFD5F5EC), Color(0xFF6DDCC5), Color(0xFF1E4F44)),
    'moss': _AccentEntry(Color(0xFF56943B), Color(0xFFDFF0D3), Color(0xFF8ACD6B), Color(0xFF2A4420)),
    'coral': _AccentEntry(Color(0xFFE07A5F), Color(0xFFFDE2D6), Color(0xFFF0A48C), Color(0xFF5C3024)),
    'blush': _AccentEntry(Color(0xFFBE50A0), Color(0xFFF7DCF0), Color(0xFFE88FCC), Color(0xFF4E2440)),
    'teal': _AccentEntry(Color(0xFF00796B), Color(0xFFCCE8E3), Color(0xFF4DB6AC), Color(0xFF1A3C38)),
    'lavender': _AccentEntry(Color(0xFF9575CD), Color(0xFFEDE7F6), Color(0xFFC9A8F0), Color(0xFF3A2D52)),
    'peach': _AccentEntry(Color(0xFFEF6C00), Color(0xFFFFE0B2), Color(0xFFFFAB40), Color(0xFF4D3010)),
  };
  return map[name.toLowerCase()];
}

class _AccentEntry {
  final Color light;
  final Color lightContainer;
  final Color dark;
  final Color darkContainer;

  const _AccentEntry(this.light, this.lightContainer, this.dark, this.darkContainer);
}
