import 'package:flutter/foundation.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';

@immutable
class PaymentTotals {
  const PaymentTotals({required this.count, required this.amount});

  static const zero = PaymentTotals(count: 0, amount: 0);

  final int count;
  final int amount;
}

@immutable
class DaySummary {
  const DaySummary({
    required this.day,
    required this.tripsCount,
    required this.revenue,
    required this.commission,
    required this.net,
    required this.busy,
    required this.cash,
    required this.card,
  });

  final CalendarDay day;
  final int tripsCount;
  final int revenue;
  final int commission;

  /// Revenue minus commission: what the driver keeps.
  final int net;

  /// Total time spent on trips.
  final Duration busy;
  final PaymentTotals cash;
  final PaymentTotals card;

  bool get isEmpty => tripsCount == 0;

  /// Share of revenue paid in cash, 0..1.
  double get cashShare => revenue == 0 ? 0 : cash.amount / revenue;

  /// Commission as a share of revenue, 0..1.
  double get commissionRate => revenue == 0 ? 0 : commission / revenue;
}

@immutable
class DayReport {
  const DayReport({required this.summary, required this.trips});

  final DaySummary summary;
  final List<Trip> trips;
}

/// A day that has at least one trip.
@immutable
class ShiftDay {
  const ShiftDay({required this.day, required this.tripsCount, required this.net});

  final CalendarDay day;
  final int tripsCount;
  final int net;
}
