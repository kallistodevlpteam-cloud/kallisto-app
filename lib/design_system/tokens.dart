import 'package:flutter/material.dart';

/// Ported from app/globals.css. OKLCH values are converted to sRGB for Flutter.
abstract final class KTokens {
  static const ink = Color(0xFF17130E);
  static const muted = Color(0xFF57524B);
  static const soft = Color(0xFF8A8580);
  static const line = Color(0xFFE6E4E1);
  static const page = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const subtle = Color(0xFFF7F7F5);
  static const accent = Color(0xFF1175DE);
  static const accentSoft = Color(0xFFE2F0FF);
  static const chrome = Color(0xFFECEEF1);
  static const success = Color(0xFF16764B);
  static const warning = Color(0xFF946000);
  static const danger = Color(0xFFBA3333);
  static const spacing = <double>[4, 8, 12, 16, 24, 32, 48];
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const sidebar = 240.0;
  static const rail = 56.0;
  static const topbar = 48.0;
  static const odin = 340.0;
  static const workspace = 1120.0;
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
  static const drawer = Duration(milliseconds: 220);
  static const expressive = Duration(milliseconds: 350);
  static const entrance = Cubic(0.16, 1, 0.3, 1);

  static Duration motion(BuildContext context, [Duration value = standard]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;

  static Color border(BuildContext context) => Theme.of(context).dividerColor;
  static Color panel(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color quiet(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E293B)
      : subtle;

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final color = dark ? const Color(0xFFF8FAFC) : ink;
    final surfaceColor = dark ? const Color(0xFF0F172A) : surface;
    final borderColor = dark ? const Color(0xFF334155) : line;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: dark ? const Color(0xFF38BDF8) : accent,
      surface: surfaceColor,
      onSurface: color,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Hanken Grotesk',
      scaffoldBackgroundColor: dark ? const Color(0xFF090D16) : page,
      dividerColor: borderColor,
      splashFactory: InkRipple.splashFactory,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineLarge: TextStyle(
              fontSize: 32,
              height: 1.15,
              letterSpacing: -1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              height: 1.2,
              letterSpacing: -.6,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            bodyMedium: TextStyle(fontSize: 13.5, height: 1.5, color: color),
            bodySmall: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: dark ? const Color(0xFF94A3B8) : muted,
            ),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(fontFamily: 'Hanken Grotesk'),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 44),
          shape: shape,
          side: BorderSide(color: borderColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: BorderSide(color: borderColor),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 350),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
