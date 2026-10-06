import 'package:flutter_test/flutter_test.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';

import '../helpers.dart';

void main() {
  test('days are resolved in the driver zone, not in UTC', () {
    // 02:00 in Almaty on Oct 2 is 21:00 UTC on Oct 1.
    final instant = DateTime.utc(2026, 10, 1, 21);
    expect(almatyClock.dayOf(instant), CalendarDay(2026, 10, 2));
  });

  test('wall clock round-trips', () {
    final instant = DateTime.utc(2026, 10, 1, 3, 10);
    final wall = almatyClock.toWallClock(instant);
    expect((wall.hour, wall.minute), (8, 10));
    expect(almatyClock.fromWallClock(wall), instant);
  });

  test('serializes with the driver offset', () {
    expect(almatyClock.toIsoString(almaty(1, 8, 10)), '2026-10-01T08:10:00+05:00');
  });

  test('today follows the driver zone', () {
    expect(almatyClock.today(), CalendarDay(2026, 10, 1));
  });
}
