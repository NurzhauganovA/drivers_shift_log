import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/widgets/surface_card.dart';

/// Placeholder shaped like the loaded content, so nothing jumps when data arrives.
class DaySkeleton extends StatelessWidget {
  const DaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget block(double height, {double radius = AppTheme.radiusMedium}) => Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Semantics(
      label: 'Загрузка',
      child:
          Column(
                children: [
                  block(158, radius: AppTheme.radiusLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: block(96)),
                      const SizedBox(width: 12),
                      Expanded(child: block(96)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  block(150),
                  const SizedBox(height: 28),
                  block(280),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1400.ms, color: palette.surfaceSecondary.withValues(alpha: 0.9)),
    );
  }
}

class EmptyDayView extends StatelessWidget {
  const EmptyDayView({required this.onAddTrip, this.onOpenLatest, super.key});

  final VoidCallback onAddTrip;
  final VoidCallback? onOpenLatest;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_taxi_outlined, color: palette.accent, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Поездок нет', style: text.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Добавьте первую поездку или выберите другой день',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: onAddTrip, child: const Text('Добавить поездку')),
              if (onOpenLatest != null)
                TextButton(onPressed: onOpenLatest, child: const Text('К последней смене')),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class DayErrorView extends StatelessWidget {
  const DayErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: palette.textTertiary, size: 34),
          const SizedBox(height: 14),
          Text('Не удалось загрузить', style: text.titleMedium),
          const SizedBox(height: 6),
          Text(message, style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
