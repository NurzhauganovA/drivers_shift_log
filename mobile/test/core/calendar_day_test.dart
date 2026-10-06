import 'package:flutter_test/flutter_test.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';

void main() {
  test('parses and prints ISO dates', () {
    expect(CalendarDay.parse('2026-10-01'), CalendarDay(2026, 10, 1));
    expect(CalendarDay(2026, 1, 5).toIso(), '2026-01-05');
  });

  test('rejects malformed and impossible dates', () {
    expect(() => CalendarDay.parse('01.10.2026'), throwsFormatException);
    expect(() => CalendarDay.parse('2026-02-30'), throwsFormatException);
  });

  test('day arithmetic crosses month and year boundaries', () {
    expect(CalendarDay(2026, 10, 31).addDays(1), CalendarDay(2026, 11, 1));
    expect(CalendarDay(2026, 1, 1).addDays(-1), CalendarDay(2025, 12, 31));
    expect(CalendarDay(2026, 10, 5).differenceInDays(CalendarDay(2026, 9, 28)), 7);
  });

  test('weeks start on Monday', () {
    final sunday = CalendarDay(2026, 10, 4);
    expect(sunday.weekday, DateTime.sunday);
    expect(sunday.startOfWeek, CalendarDay(2026, 9, 28));
    expect(CalendarDay(2026, 9, 28).startOfWeek, CalendarDay(2026, 9, 28));
  });
}
