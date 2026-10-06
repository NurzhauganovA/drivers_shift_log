import 'package:flutter/material.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/widgets/surface_card.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';

/// Cash versus card, as an animated two-tone bar with a legend.
class PaymentSplitCard extends StatelessWidget {
  const PaymentSplitCard({required this.summary, super.key});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Способ оплаты', style: text.labelMedium),
          const SizedBox(height: 14),
          _SplitBar(
            cashShare: summary.cashShare,
            isEmpty: summary.isEmpty,
            cash: palette.cash,
            card: palette.card,
            track: palette.surfaceSecondary,
          ),
          const SizedBox(height: 16),
          _LegendRow(
            color: palette.cash,
            icon: Icons.payments_outlined,
            label: 'Наличные',
            totals: summary.cash,
          ),
          const SizedBox(height: 10),
          _LegendRow(
            color: palette.card,
            icon: Icons.credit_card_rounded,
            label: 'Карта',
            totals: summary.card,
          ),
        ],
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.cashShare,
    required this.isEmpty,
    required this.cash,
    required this.card,
    required this.track,
  });

  final double cashShare;
  final bool isEmpty;
  final Color cash;
  final Color card;
  final Color track;

  @override
  Widget build(BuildContext context) {
    const height = 10.0;
    const gap = 3.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: isEmpty
            ? ColoredBox(color: track)
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: cashShare),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, share, _) => LayoutBuilder(
                  builder: (context, constraints) {
                    final hasBoth = share > 0 && share < 1;
                    final usable = constraints.maxWidth - (hasBoth ? gap : 0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: usable * share, color: cash),
                        if (hasBoth) const SizedBox(width: gap),
                        Expanded(child: ColoredBox(color: card)),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.totals,
  });

  final Color color;
  final IconData icon;
  final String label;
  final PaymentTotals totals;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: text.bodyMedium)),
        Text(
          formatTripCount(totals.count),
          style: text.bodySmall?.copyWith(color: palette.textTertiary),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(totals.amount),
          style: text.titleSmall?.copyWith(fontFeatures: AppTheme.tabular),
        ),
      ],
    );
  }
}
