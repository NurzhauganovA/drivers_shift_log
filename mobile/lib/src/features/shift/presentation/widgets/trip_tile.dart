import 'package:flutter/material.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';

class TripTile extends StatelessWidget {
  const TripTile({required this.trip, required this.clock, super.key});

  final Trip trip;
  final DriverClock clock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final start = clock.toWallClock(trip.start);
    final end = clock.toWallClock(trip.end);
    final endsNextDay = clock.dayOf(trip.end) != clock.dayOf(trip.start);
    final isCash = trip.payment == PaymentMethod.cash;
    final accent = isCash ? palette.cash : palette.card;
    const tabular = TextStyle(fontFeatures: AppTheme.tabular);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatTime(start), style: text.titleSmall?.merge(tabular)),
                const SizedBox(height: 2),
                Text(
                  endsNextDay ? '${formatTime(end)}⁺¹' : formatTime(end),
                  style: text.bodySmall?.merge(tabular),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 34,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCash ? Icons.payments_outlined : Icons.credit_card_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(isCash ? 'Наличные' : 'Карта', style: text.bodyMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text(formatDuration(trip.duration), style: text.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatMoney(trip.amount), style: text.titleSmall?.merge(tabular)),
              const SizedBox(height: 2),
              Text(
                '−${formatMoney(trip.commission)}',
                style: text.bodySmall?.copyWith(color: palette.textTertiary).merge(tabular),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
