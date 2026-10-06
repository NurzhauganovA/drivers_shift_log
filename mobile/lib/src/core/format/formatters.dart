import 'package:intl/intl.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';

const _locale = 'ru';
const _nbsp = ' ';

final _amount = NumberFormat.decimalPattern(_locale);
final _time = DateFormat.Hm(_locale);
final _dayMonth = DateFormat('d MMMM', _locale);
final _weekday = DateFormat.EEEE(_locale);
final _weekdayShort = DateFormat.E(_locale);
final _monthYear = DateFormat('LLLL y', _locale);
final _fullDate = DateFormat('d MMMM y', _locale);

/// Formats whole tenge as `24 950 ₸`.
String formatMoney(int amount) => '${_amount.format(amount)}$_nbsp₸';

String formatTime(DateTime wallClock) => _time.format(wallClock);

/// `22 мин`, `1 ч`, `4 ч 34 мин`.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes$_nbspмин';
  if (minutes == 0) return '$hours$_nbspч';
  return '$hours$_nbspч $minutes$_nbspмин';
}

String formatTripCount(int count) =>
    '$count$_nbsp${Intl.plural(count, one: 'поездка', few: 'поездки', other: 'поездок', locale: _locale)}';

/// `Сегодня`, `Вчера`, `Завтра`, otherwise `1 октября`.
String formatRelativeDay(CalendarDay day, CalendarDay today) {
  return switch (day.differenceInDays(today)) {
    0 => 'Сегодня',
    -1 => 'Вчера',
    1 => 'Завтра',
    _ => _dayMonth.format(day.toDateTime()),
  };
}

String formatDayMonth(CalendarDay day) => _dayMonth.format(day.toDateTime());

String formatFullDate(CalendarDay day) => _fullDate.format(day.toDateTime());

String formatWeekday(CalendarDay day) => _weekday.format(day.toDateTime());

/// Two-letter weekday: `пн`, `вт`.
String formatWeekdayShort(CalendarDay day) => _weekdayShort.format(day.toDateTime());

/// `Октябрь 2026`: standalone (nominative) month name, capitalized.
String formatMonthYear(CalendarDay day) => _capitalize(_monthYear.format(day.toDateTime()));

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

final _dateTimeShort = DateFormat('d MMM, HH:mm', _locale);

/// `1 окт., 08:10`.
String formatDateTimeShort(DateTime wallClock) => _dateTimeShort.format(wallClock);
