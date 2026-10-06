import 'package:flutter/foundation.dart';

/// A date without time or zone, in the driver's calendar.
@immutable
class CalendarDay implements Comparable<CalendarDay> {
  const CalendarDay._(this.year, this.month, this.day);

  /// Out-of-range values roll over like [DateTime], e.g. Oct 32 is Nov 1.
  factory CalendarDay(int year, int month, int day) =>
      CalendarDay.of(DateTime.utc(year, month, day));

  /// Takes the calendar fields of [dateTime] as they are, ignoring its zone.
  factory CalendarDay.of(DateTime dateTime) =>
      CalendarDay._(dateTime.year, dateTime.month, dateTime.day);

  /// Parses `YYYY-MM-DD`.
  factory CalendarDay.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Expected YYYY-MM-DD', value);
    final day = CalendarDay(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    if (day.toIso() != value) throw FormatException('Invalid date', value);
    return day;
  }

  final int year;
  final int month;
  final int day;

  /// 1 = Monday ... 7 = Sunday.
  int get weekday => toDateTime().weekday;

  CalendarDay addDays(int days) => CalendarDay(year, month, day + days);

  CalendarDay get startOfWeek => addDays(1 - weekday);

  int differenceInDays(CalendarDay other) => toDateTime().difference(other.toDateTime()).inDays;

  bool isBefore(CalendarDay other) => compareTo(other) < 0;
  bool isAfter(CalendarDay other) => compareTo(other) > 0;

  /// Midnight of this day as a UTC-flagged wall-clock value.
  DateTime toDateTime() => DateTime.utc(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDay other) => toDateTime().compareTo(other.toDateTime());

  @override
  bool operator ==(Object other) =>
      other is CalendarDay && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
