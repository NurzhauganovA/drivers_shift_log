import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/presentation/state/shift_providers.dart';

import '../../helpers.dart';

final _today = CalendarDay(2026, 10, 1);
final _shifts = [
  ShiftDay(day: _today.addDays(-2), tripsCount: 3, net: 5000),
  ShiftDay(day: _today.addDays(-5), tripsCount: 1, net: 900),
];

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [driverClockProvider.overrideWithValue(almatyClock)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts on today', () {
    expect(_container().read(selectedDayProvider).day, _today);
  });

  test('opens the latest shift when today is empty', () {
    final container = _container();
    container.read(selectedDayProvider.notifier).openLatestShift(_shifts);

    expect(container.read(selectedDayProvider).day, _today.addDays(-2));
  });

  test('stays on today when today already has trips', () {
    final container = _container();
    container.read(selectedDayProvider.notifier).openLatestShift([
      ShiftDay(day: _today, tripsCount: 1, net: 100),
      ..._shifts,
    ]);

    expect(container.read(selectedDayProvider).day, _today);
  });

  test('a late shift list does not move a day the driver is working with', () {
    final container = _container();
    final notifier = container.read(selectedDayProvider.notifier)..keepCurrentDay();
    notifier.openLatestShift(_shifts);

    expect(container.read(selectedDayProvider).day, _today);
  });

  test('cannot navigate into the future', () {
    final container = _container();
    final notifier = container.read(selectedDayProvider.notifier)..shift(1);

    expect(container.read(selectedDayProvider).day, _today);
    notifier.shift(-1);
    expect(container.read(selectedDayProvider).direction, -1);
  });
}
