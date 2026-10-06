import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

final almatyClock = DriverClock(
  utcOffset: const Duration(hours: 5),
  now: () => DateTime.utc(2026, 10, 1, 12), // 17:00 in Almaty.
);

/// Instant for a wall-clock time in Almaty (UTC+5).
DateTime almaty(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 10, day, hour, minute).subtract(const Duration(hours: 5));

TripDraft draft({
  String id = 'd1',
  DateTime? start,
  int minutes = 20,
  int amount = 2000,
  PaymentMethod payment = PaymentMethod.card,
  int commission = 300,
}) {
  final from = start ?? almaty(1, 8);
  return TripDraft(
    id: id,
    start: from,
    end: from.add(Duration(minutes: minutes)),
    amount: amount,
    payment: payment,
    commission: commission,
  );
}
