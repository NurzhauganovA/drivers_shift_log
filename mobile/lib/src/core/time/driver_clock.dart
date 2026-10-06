import 'package:shift_log/src/core/time/calendar_day.dart';

/// Converts between absolute instants and the driver's wall-clock time.
///
/// Wall-clock values are UTC-flagged [DateTime]s whose fields read as local
/// time in the driver's zone. This keeps rendering independent of the device
/// time zone, so a reviewer in Berlin sees the same 08:10 as a driver in Almaty.
class DriverClock {
  DriverClock({required this.utcOffset, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Duration utcOffset;
  final DateTime Function() _now;

  DateTime toWallClock(DateTime instant) => instant.toUtc().add(utcOffset);

  DateTime fromWallClock(DateTime wallClock) => DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  ).subtract(utcOffset);

  DateTime now() => _now().toUtc();

  CalendarDay today() => dayOf(now());

  CalendarDay dayOf(DateTime instant) => CalendarDay.of(toWallClock(instant));

  /// ISO 8601 with the driver's offset, e.g. `2026-10-01T08:10:00+05:00`.
  String toIsoString(DateTime instant) {
    final wall = toWallClock(instant);
    String two(int v) => v.toString().padLeft(2, '0');
    final sign = utcOffset.isNegative ? '-' : '+';
    final offset = utcOffset.abs();
    return '${CalendarDay.of(wall).toIso()}T${two(wall.hour)}:${two(wall.minute)}:${two(wall.second)}'
        '$sign${two(offset.inHours)}:${two(offset.inMinutes.remainder(60))}';
  }
}
