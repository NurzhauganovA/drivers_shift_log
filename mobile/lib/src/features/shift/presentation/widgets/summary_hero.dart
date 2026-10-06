import 'package:flutter/material.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/widgets/animated_money.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';

/// The headline number of the day: what the driver takes home.
class SummaryHero extends StatelessWidget {
  const SummaryHero({required this.summary, super.key});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    const onHero = Colors.white;

    final details = summary.isEmpty
        ? 'Поездок нет'
        : '${formatTripCount(summary.tripsCount)} · ${formatDuration(summary.busy)} в пути';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.heroGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -80,
              child: _Glow(color: palette.accent.withValues(alpha: 0.55), size: 220),
            ),
            Positioned(
              left: -40,
              bottom: -90,
              child: _Glow(color: palette.card.withValues(alpha: 0.35), size: 200),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'НА РУКИ',
                    style: text.labelSmall?.copyWith(
                      color: onHero.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedMoney(
                      summary.net,
                      style: text.displayLarge?.copyWith(color: onHero),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: text.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
