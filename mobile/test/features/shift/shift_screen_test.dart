import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_log/src/app.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/features/shift/data/demo_shift_repository.dart';
import 'package:shift_log/src/features/shift/presentation/state/shift_providers.dart';

import '../../helpers.dart';

final _seed = [
  for (final (id, day, hour, amount, payment) in [
    ('t1', 1, 8, 2400, 'card'),
    ('t2', 1, 9, 1500, 'cash'),
    ('t3', 2, 10, 3000, 'card'),
  ])
    {
      'id': id,
      'start': '2026-10-0${day}T${hour.toString().padLeft(2, '0')}:00:00+05:00',
      'end': '2026-10-0${day}T${hour.toString().padLeft(2, '0')}:20:00+05:00',
      'amount': amount,
      'payment': payment,
      'commission': amount * 15 ~/ 100,
    },
];

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        driverClockProvider.overrideWithValue(almatyClock),
        shiftRepositoryProvider.overrideWithValue(
          DemoShiftRepository(
            loadSeed: () async => jsonEncode(_seed),
            clock: almatyClock,
            latency: Duration.zero,
          ),
        ),
      ],
      child: const ShiftLogApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  testWidgets('shows the summary and trips of today', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text(formatMoney(3315)), findsOneWidget, reason: 'net amount');
    expect(find.text(formatMoney(3900)), findsOneWidget, reason: 'revenue');
    expect(find.text('Поездки'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('switching to an empty day shows the empty state', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('30 сентября 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Вчера'), findsOneWidget);
    expect(find.text('Поездок нет'), findsWidgets);
    expect(find.text('К последней смене'), findsOneWidget);
  });

  testWidgets('adding a trip updates the day', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Новая поездка'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Поездка добавлена'), findsOneWidget);
    expect(find.text(formatMoney(3315 + 2000 - 300)), findsOneWidget);
  });
}
