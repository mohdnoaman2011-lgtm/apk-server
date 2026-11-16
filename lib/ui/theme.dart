import 'package:flutter/material.dart';

const kGreen = Color(0xFF3DDC84);
const kBg = Color(0xFF0F1419);
const kSurface = Color(0xFF171E27);
const kMuted = Color(0xFF9AA7B5);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: kGreen,
      scaffoldBackgroundColor: kBg,
      cardTheme: CardThemeData(
        color: kSurface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF232C37)),
        ),
      ),
    );
