import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ألوان مستخرجة من شعار Apk Server
const kBg = Color(0xFF0A1830);
const kSurface = Color(0xFF11223F);
const kBorder = Color(0xFF1D3358);
const kMuted = Color(0xFF8CA2C2);
const kGreen = Color(0xFF22E5C0); // النعناعي

extension ThemeColors on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// secondary = لون التحذير، tertiary = لون الروابط، error = الأخطاء.
ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: kGreen, brightness: b).copyWith(
    primary: dark ? kGreen : const Color(0xFF0A7C70),
    onPrimary: dark ? const Color(0xFF04201B) : Colors.white,
    surface: dark ? kBg : const Color(0xFFF4F8FB),
    onSurface: dark ? const Color(0xFFE8EEF7) : const Color(0xFF0E1F33),
    onSurfaceVariant: dark ? kMuted : const Color(0xFF54677E),
    outlineVariant: dark ? kBorder : const Color(0xFFD8E3EC),
    tertiary: dark ? const Color(0xFF7CC4FF) : const Color(0xFF0B63CE),
    secondary: dark ? const Color(0xFFFFB74D) : const Color(0xFFB26A00),
    error: dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
  );
  final card = dark ? kSurface : Colors.white;
  // الخط الموحّد للتطبيق كله
  final tt = GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData(brightness: b).textTheme)
      .apply(fontSizeFactor: .92, bodyColor: cs.onSurface, displayColor: cs.onSurface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: tt,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: tt.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF0D1D3A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.primary.withValues(alpha: .16),
      height: 62,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      extendedSizeConstraints: const BoxConstraints.tightFor(height: 46),
      extendedPadding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.outlineVariant),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: cs.primary.withValues(alpha: .18),
        selectedForegroundColor: cs.primary,
        side: BorderSide(color: cs.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
