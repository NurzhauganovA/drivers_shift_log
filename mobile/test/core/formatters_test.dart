import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('money uses non-breaking spaces and the tenge sign', () {
    expect(formatMoney(24950), '24 950 ₸');
    expect(formatMoney(0), '0 ₸');
  });

  test('durations', () {
    expect(formatDuration(const Duration(minutes: 22)), '22 мин');
    expect(formatDuration(const Duration(hours: 1)), '1 ч');
    expect(formatDuration(const Duration(hours: 4, minutes: 34)), '4 ч 34 мин');
  });

  test('trip count is pluralized in Russian', () {
    expect(formatTripCount(1), '1 поездка');
    expect(formatTripCount(3), '3 поездки');
    expect(formatTripCount(11), '11 поездок');
    expect(formatTripCount(21), '21 поездка');
  });

  test('relative day names', () {
    final today = CalendarDay(2026, 10, 6);
    expect(formatRelativeDay(today, today), 'Сегодня');
    expect(formatRelativeDay(today.addDays(-1), today), 'Вчера');
    expect(formatRelativeDay(CalendarDay(2026, 10, 1), today), '1 октября');
  });

  test('month title is capitalized', () {
    expect(formatMonthYear(CalendarDay(2026, 10, 1)), 'Октябрь 2026');
  });
}
