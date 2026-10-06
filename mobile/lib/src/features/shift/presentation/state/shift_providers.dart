import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_log/src/core/config/app_config.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/data/demo_shift_repository.dart';
import 'package:shift_log/src/features/shift/data/remote_shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

final driverClockProvider = Provider<DriverClock>(
  (ref) => DriverClock(utcOffset: const Duration(minutes: AppConfig.driverUtcOffsetMinutes)),
);

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final clock = ref.watch(driverClockProvider);
  final ShiftRepository repository = AppConfig.isDemo
      ? DemoShiftRepository(
          loadSeed: () => rootBundle.loadString('assets/data/seed_trips.json'),
          clock: clock,
        )
      : RemoteShiftRepository(baseUri: _withTrailingSlash(AppConfig.apiBaseUrl), clock: clock);
  ref.onDispose(repository.dispose);
  return repository;
});

Uri _withTrailingSlash(String url) => Uri.parse(url.endsWith('/') ? url : '$url/');

final shiftDaysProvider = FutureProvider<List<ShiftDay>>(
  (ref) => ref.watch(shiftRepositoryProvider).fetchShiftDays(),
);

final dayReportProvider = FutureProvider.family<DayReport, CalendarDay>(
  (ref, day) => ref.watch(shiftRepositoryProvider).fetchDay(day),
);

@immutable
class DaySelection {
  const DaySelection(this.day, {this.direction = 0});

  final CalendarDay day;

  /// -1 when moving back in time, 1 when moving forward. Drives transitions.
  final int direction;
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DaySelection>(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier<DaySelection> {
  bool _userNavigated = false;

  CalendarDay get _today => ref.read(driverClockProvider).today();

  @override
  DaySelection build() => DaySelection(_today);

  bool get canGoForward => state.day.isBefore(_today);

  void select(CalendarDay day) {
    _userNavigated = true;
    final target = day.isAfter(_today) ? _today : day;
    if (target == state.day) return;
    state = DaySelection(target, direction: target.compareTo(state.day).sign);
  }

  void shift(int days) => select(state.day.addDays(days));

  void goToToday() => select(_today);

  /// Stops [openLatestShift] from moving away from the day the driver is
  /// working with, e.g. while the add-trip form for that day is open.
  void keepCurrentDay() => _userNavigated = true;

  /// On launch, opens the most recent shift if today has no trips yet.
  /// Does nothing once the driver has picked a day.
  void openLatestShift(List<ShiftDay> days) {
    if (_userNavigated) return;
    _userNavigated = true;
    final today = _today;
    final latest = days.map((d) => d.day).where((d) => !d.isAfter(today)).firstOrNull;
    if (latest != null && latest != state.day && !days.any((d) => d.day == today)) {
      state = DaySelection(latest, direction: -1);
    }
  }
}

final tripSubmitterProvider = Provider<TripSubmitter>(TripSubmitter.new);

class TripSubmitter {
  TripSubmitter(this._ref);

  final Ref _ref;

  /// Safe to call again with the same draft after a network error.
  Future<AddTripResult> submit(TripDraft draft) async {
    final result = await _ref.read(shiftRepositoryProvider).addTrip(draft);
    final day = _ref.read(driverClockProvider).dayOf(result.trip.start);
    _ref
      ..invalidate(dayReportProvider(day))
      ..invalidate(shiftDaysProvider);
    return result;
  }
}
