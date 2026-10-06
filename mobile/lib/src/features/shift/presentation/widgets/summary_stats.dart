import 'package:flutter/material.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/widgets/animated_money.dart';
import 'package:shift_log/src/core/widgets/surface_card.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';

class SummaryStats extends StatelessWidget {
  const SummaryStats({required this.summary, super.key});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final rate = (summary.commissionRate * 100).round();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(label: 'Выручка', amount: summary.revenue, caption: 'до комиссии'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Комиссия',
              amount: summary.commission,
              caption: summary.isEmpty ? 'сервиса' : '$rate% от выручки',
              negative: summary.commission > 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.amount,
    required this.caption,
    this.negative = false,
  });

  final String label;
  final int amount;
  final String caption;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(amount, prefix: negative ? '−' : '', style: text.headlineSmall),
          ),
          const SizedBox(height: 2),
          Text(caption, style: text.bodySmall?.copyWith(color: palette.textTertiary)),
        ],
      ),
    );
  }
}
