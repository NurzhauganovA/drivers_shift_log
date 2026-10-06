import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shift_log/src/core/theme/palette.dart';

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  /// Numbers line up in columns and do not jitter while animating.
  static const tabular = [FontFeature.tabularFigures()];

  static const radiusLarge = 28.0;
  static const radiusMedium = 20.0;
  static const radiusSmall = 14.0;

  static ThemeData light() => _build(Brightness.light, Palette.light);

  static ThemeData dark() => _build(Brightness.dark, Palette.dark);

  static ThemeData _build(Brightness brightness, Palette palette) {
    final scheme = ColorScheme.fromSeed(seedColor: palette.accent, brightness: brightness).copyWith(
      primary: palette.accent,
      onPrimary: palette.onAccent,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      error: palette.negative,
      outline: palette.separator,
      outlineVariant: palette.separator,
    );

    final text = _textTheme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      dividerTheme: DividerThemeData(color: palette.separator, thickness: 0.5, space: 0.5),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.textTertiary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: palette.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: text.bodyLarge?.copyWith(color: palette.textTertiary),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(palette.accent, width: 1.5),
        errorBorder: _inputBorder(palette.negative),
        focusedErrorBorder: _inputBorder(palette.negative, width: 1.5),
        errorStyle: text.bodySmall?.copyWith(color: palette.negative),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.accent.withValues(alpha: 0.4),
          disabledForegroundColor: palette.onAccent.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(54),
          textStyle: text.titleMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.accent, textStyle: text.labelLarge),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusSmall),
    borderSide: BorderSide(color: color, width: width),
  );

  static TextTheme _textTheme(Palette p) {
    TextStyle style(double size, FontWeight weight, Color color, {double spacing = 0}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: 1.25,
    );

    return TextTheme(
      displayLarge: style(48, FontWeight.w700, p.textPrimary, spacing: -1.6),
      displayMedium: style(40, FontWeight.w700, p.textPrimary, spacing: -1.2),
      headlineLarge: style(32, FontWeight.w700, p.textPrimary, spacing: -0.8),
      headlineMedium: style(26, FontWeight.w700, p.textPrimary, spacing: -0.6),
      headlineSmall: style(22, FontWeight.w600, p.textPrimary, spacing: -0.4),
      titleLarge: style(20, FontWeight.w600, p.textPrimary, spacing: -0.3),
      titleMedium: style(17, FontWeight.w600, p.textPrimary, spacing: -0.2),
      titleSmall: style(15, FontWeight.w600, p.textPrimary, spacing: -0.1),
      bodyLarge: style(17, FontWeight.w400, p.textPrimary, spacing: -0.2),
      bodyMedium: style(15, FontWeight.w400, p.textPrimary, spacing: -0.1),
      bodySmall: style(13, FontWeight.w400, p.textSecondary),
      labelLarge: style(15, FontWeight.w500, p.textPrimary, spacing: -0.1),
      labelMedium: style(13, FontWeight.w500, p.textSecondary),
      labelSmall: style(11, FontWeight.w600, p.textSecondary, spacing: 0.4),
    );
  }
}
