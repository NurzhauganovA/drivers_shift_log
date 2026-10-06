import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

typedef Json = Map<String, Object?>;

Trip tripFromJson(Json json) => Trip(
  id: json['id']! as String,
  start: DateTime.parse(json['start']! as String),
  end: DateTime.parse(json['end']! as String),
  amount: json['amount']! as int,
  payment: PaymentMethod.fromWire(json['payment']! as String),
  commission: json['commission']! as int,
);

Json tripDraftToJson(TripDraft draft, DriverClock clock) => {
  'id': draft.id,
  'start': clock.toIsoString(draft.start),
  'end': clock.toIsoString(draft.end),
  'amount': draft.amount,
  'payment': draft.payment.wireName,
  'commission': draft.commission,
};

PaymentTotals _totalsFromJson(Json json) =>
    PaymentTotals(count: json['count']! as int, amount: json['amount']! as int);

DaySummary summaryFromJson(Json json) => DaySummary(
  day: CalendarDay.parse(json['date']! as String),
  tripsCount: json['trips_count']! as int,
  revenue: json['revenue']! as int,
  commission: json['commission']! as int,
  net: json['net']! as int,
  busy: Duration(seconds: json['busy_seconds']! as int),
  cash: _totalsFromJson(json['cash']! as Json),
  card: _totalsFromJson(json['card']! as Json),
);

DayReport dayReportFromJson(Json json) => DayReport(
  summary: summaryFromJson(json['summary']! as Json),
  trips: [for (final trip in json['trips']! as List<Object?>) tripFromJson(trip! as Json)],
);

ShiftDay shiftDayFromJson(Json json) => ShiftDay(
  day: CalendarDay.parse(json['date']! as String),
  tripsCount: json['trips_count']! as int,
  net: json['net']! as int,
);
