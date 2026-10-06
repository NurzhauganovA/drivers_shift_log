import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/features/shift/data/demo_shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';

import '../../helpers.dart';

const _seed = [
  {
    'id': 't1',
    'start': '2026-10-01T08:10:00+05:00',
    'end': '2026-10-01T08:32:00+05:00',
    'amount': 2400,
    'payment': 'card',
    'commission': 360,
  },
  {
    'id': 't2',
    'start': '2026-10-01T09:05:00+05:00',
    'end': '2026-10-01T09:20:00+05:00',
    'amount': 1500,
    'payment': 'cash',
    'commission': 225,
  },
];

DemoShiftRepository _repository() => DemoShiftRepository(
  loadSeed: () async => jsonEncode(_seed),
  clock: almatyClock,
  latency: Duration.zero,
);

void main() {
  test('summary of the sample day matches the server', () async {
    final report = await _repository().fetchDay(CalendarDay(2026, 10, 1));

    expect(report.trips.map((t) => t.id), ['t1', 't2']);
    expect(report.summary.tripsCount, 2);
    expect(report.summary.revenue, 3900);
    expect(report.summary.commission, 585);
    expect(report.summary.net, 3315);
    expect(report.summary.cash.amount, 1500);
    expect(report.summary.card.amount, 2400);
  });

  test('resending the same draft does not create a duplicate', () async {
    final repository = _repository();
    final pending = draft(start: almaty(1, 10));

    final first = await repository.addTrip(pending);
    final second = await repository.addTrip(pending);
    final report = await repository.fetchDay(CalendarDay(2026, 10, 1));

    expect(first.created, isTrue);
    expect(second.created, isFalse);
    expect(report.trips, hasLength(3));
  });

  test('same id with other data and overlapping trips are rejected', () async {
    final repository = _repository();
    await repository.addTrip(draft(id: 'x', start: almaty(1, 10)));

    await expectLater(
      repository.addTrip(draft(id: 'x', start: almaty(1, 10), amount: 999)),
      throwsA(isA<TripConflictFailure>()),
    );
    await expectLater(
      repository.addTrip(draft(id: 'y', start: almaty(1, 10, 5))),
      throwsA(isA<TripConflictFailure>()),
    );
  });

  test('lists shift days newest first', () async {
    final repository = _repository();
    await repository.addTrip(draft(start: almaty(3, 10)));

    final days = await repository.fetchShiftDays();

    expect(days.map((d) => d.day), [CalendarDay(2026, 10, 3), CalendarDay(2026, 10, 1)]);
    expect(days.last.net, 3315);
  });
}
