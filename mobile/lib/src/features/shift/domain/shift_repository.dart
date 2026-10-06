import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

/// Source of shift data. Implementations throw [ShiftFailure] on errors.
abstract interface class ShiftRepository {
  Future<DayReport> fetchDay(CalendarDay day);

  /// Days with trips, newest first.
  Future<List<ShiftDay>> fetchShiftDays();

  /// Idempotent: sending the same draft again returns the stored trip.
  Future<AddTripResult> addTrip(TripDraft draft);

  void dispose();
}
