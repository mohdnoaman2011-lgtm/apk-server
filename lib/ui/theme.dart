import 'package:flutter/material.dart';

const kGreen = Color(0xFF3DDC84);
const kBg = Color(0xFF0F1419);
const kSurface = Color(0xFF171E27);
const kMuted = Color(0xFF9AA7B5);

extension ThemeColors on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}

/// secondary = لون التحذير، tertiary = لون الروابط، error = الأخطاء.
ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: kGreen, brightness: b).copyWith(
    primary: dark ? kGreen : const Color(0xFF0B7A3E),
    onPrimary: dark ? const Color(0xFF06240F) : Colors.white,
    surface: dark ? kBg : const Color(0xFFF6F8FA),
    onSurface: dark ? const Color(0xFFE8EDF2) : const Color(0xFF14202B),
    onSurfaceVariant: dark ? kMuted : const Color(0xFF55606E),
    tertiary: dark ? const Color(0xFF7CC4FF) : const Color(0xFF0B63CE),
    secondary: dark ? const Color(0xFFFFB74D) : const Color(0xFFB26A00),
    error: dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(backgroundColor: cs.surface, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(
      color: dark ? kSurface : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dark ? const Color(0xFF232C37) : const Color(0xFFDDE3EA)),
      ),
    ),
  );
}
