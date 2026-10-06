import 'package:flutter/material.dart';

/// Semantic colors of the app. Values follow Apple's system palette so the UI
/// feels at home next to native apps in both light and dark appearance.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.accent,
    required this.onAccent,
    required this.cash,
    required this.card,
    required this.positive,
    required this.negative,
    required this.heroGradient,
  });

  static const light = Palette(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEDEDF0),
    textPrimary: Color(0xFF1D1D1F),
    textSecondary: Color(0xFF6E6E73),
    textTertiary: Color(0xFFA1A1A6),
    separator: Color(0x1F3C3C43),
    accent: Color(0xFF0071E3),
    onAccent: Color(0xFFFFFFFF),
    cash: Color(0xFF34C759),
    card: Color(0xFF5E5CE6),
    positive: Color(0xFF248A3D),
    negative: Color(0xFFD70015),
    heroGradient: [Color(0xFF1D1D1F), Color(0xFF3A3A3C)],
  );

  static const dark = Palette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceSecondary: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF98989D),
    textTertiary: Color(0xFF636366),
    separator: Color(0x29EBEBF5),
    accent: Color(0xFF0A84FF),
    onAccent: Color(0xFFFFFFFF),
    cash: Color(0xFF30D158),
    card: Color(0xFF7D7AFF),
    positive: Color(0xFF30D158),
    negative: Color(0xFFFF453A),
    heroGradient: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
  );

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;
  final Color accent;
  final Color onAccent;
  final Color cash;
  final Color card;
  final Color positive;
  final Color negative;
  final List<Color> heroGradient;

  @override
  Palette copyWith({Color? accent}) => Palette(
    background: background,
    surface: surface,
    surfaceSecondary: surfaceSecondary,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    separator: separator,
    accent: accent ?? this.accent,
    onAccent: onAccent,
    cash: cash,
    card: card,
    positive: positive,
    negative: negative,
    heroGradient: heroGradient,
  );

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceSecondary: mix(surfaceSecondary, other.surfaceSecondary),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      separator: mix(separator, other.separator),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      cash: mix(cash, other.cash),
      card: mix(card, other.card),
      positive: mix(positive, other.positive),
      negative: mix(negative, other.negative),
      heroGradient: [
        for (var i = 0; i < heroGradient.length; i++) mix(heroGradient[i], other.heroGradient[i]),
      ],
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
