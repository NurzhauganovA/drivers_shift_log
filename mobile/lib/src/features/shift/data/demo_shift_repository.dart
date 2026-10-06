import 'dart:convert';
import 'dart:math';

import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/data/json_mappers.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';
import 'package:shift_log/src/features/shift/domain/shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

/// In-memory stand-in for the API, used for the static web demo where no
/// server is available. It follows the same rules as the backend: daily
/// grouping in the driver's zone, validation, idempotency by id and overlap
/// protection. The source of truth for these rules is the server.
class DemoShiftRepository implements ShiftRepository {
  DemoShiftRepository({
    required this._loadSeed,
    required this._clock,
    this.latency = const Duration(milliseconds: 450),
  });

  final Future<String> Function() _loadSeed;
  final DriverClock _clock;
  final Duration latency;
  final _random = Random();
  Future<Map<String, Trip>>? _trips;

  Future<Map<String, Trip>> get _store => _trips ??= _loadSeed().then((raw) {
    final list = jsonDecode(raw) as List<Object?>;
    return {for (final json in list) (json! as Json)['id']! as String: tripFromJson(json as Json)};
  });

  @override
  Future<DayReport> fetchDay(CalendarDay day) async {
    final trips = await _store;
    await _simulateNetwork();
    final dayTrips = trips.values.where((t) => _clock.dayOf(t.start) == day).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return DayReport(summary: summarize(day, dayTrips), trips: dayTrips);
  }

  @override
  Future<List<ShiftDay>> fetchShiftDays() async {
    final trips = await _store;
    await _simulateNetwork();
    final byDay = <CalendarDay, List<Trip>>{};
    for (final trip in trips.values) {
      byDay.putIfAbsent(_clock.dayOf(trip.start), () => []).add(trip);
    }
    final days =
        byDay.entries
            .map(
              (e) => ShiftDay(
                day: e.key,
                tripsCount: e.value.length,
                net: e.value.fold(0, (sum, t) => sum + t.net),
              ),
            )
            .toList()
          ..sort((a, b) => b.day.compareTo(a.day));
    return days;
  }

  @override
  Future<AddTripResult> addTrip(TripDraft draft) async {
    final trips = await _store;
    await _simulateNetwork();
    final errors = draft.validate();
    if (errors.isNotEmpty) throw InvalidTripFailure(errors);

    final trip = draft.toTrip();
    final existing = trips[trip.id];
    if (existing != null) {
      if (existing == trip) return AddTripResult(trip: existing, created: false);
      throw const TripConflictFailure(
        TripConflictKind.idReused,
        'Эта поездка уже сохранена с другими данными',
      );
    }
    final overlapping = trips.values.any(
      (t) => t.start.isBefore(trip.end) && trip.start.isBefore(t.end),
    );
    if (overlapping) {
      throw const TripConflictFailure(
        TripConflictKind.overlap,
        'В это время уже есть другая поездка',
      );
    }
    trips[trip.id] = trip;
    return AddTripResult(trip: trip, created: true);
  }

  @override
  void dispose() {}

  Future<void> _simulateNetwork() => Future.delayed(latency * (0.6 + _random.nextDouble() * 0.8));

  static DaySummary summarize(CalendarDay day, List<Trip> trips) {
    int sum(Iterable<Trip> items, int Function(Trip) value) =>
        items.fold(0, (total, trip) => total + value(trip));
    PaymentTotals totals(PaymentMethod method) {
      final matching = trips.where((t) => t.payment == method);
      return PaymentTotals(count: matching.length, amount: sum(matching, (t) => t.amount));
    }

    final revenue = sum(trips, (t) => t.amount);
    final commission = sum(trips, (t) => t.commission);
    return DaySummary(
      day: day,
      tripsCount: trips.length,
      revenue: revenue,
      commission: commission,
      net: revenue - commission,
      busy: Duration(seconds: sum(trips, (t) => t.duration.inSeconds)),
      cash: totals(PaymentMethod.cash),
      card: totals(PaymentMethod.card),
    );
  }
}
