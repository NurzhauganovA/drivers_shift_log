import 'package:flutter/material.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';

/// Counts smoothly from the previous amount to the new one.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(this.amount, {this.style, this.prefix = '', super.key});

  final int amount;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '$prefix${formatMoney(value.round())}',
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          fontFeatures: AppTheme.tabular,
        ),
        maxLines: 1,
        semanticsLabel: '$prefix${formatMoney(amount)}',
      ),
    );
  }
}
