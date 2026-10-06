import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/features/shift/data/remote_shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

import '../../helpers.dart';

const _dayJson = {
  'summary': {
    'date': '2026-10-01',
    'currency': 'KZT',
    'trips_count': 2,
    'revenue': 3900,
    'commission': 585,
    'net': 3315,
    'busy_seconds': 2220,
    'cash': {'count': 1, 'amount': 1500},
    'card': {'count': 1, 'amount': 2400},
  },
  'trips': [
    {
      'id': 't1',
      'start': '2026-10-01T08:10:00+05:00',
      'end': '2026-10-01T08:32:00+05:00',
      'amount': 2400,
      'payment': 'card',
      'commission': 360,
    },
  ],
};

RemoteShiftRepository _repository(MockClientHandler handler) => RemoteShiftRepository(
  baseUri: Uri.parse('http://api.test/'),
  clock: almatyClock,
  client: MockClient(handler),
);

http.Response _json(Object body, int status, {Map<String, String> headers = const {}}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8', ...headers},
    );

void main() {
  test('fetches and parses a day', () async {
    late Uri requested;
    final repository = _repository((request) async {
      requested = request.url;
      return _json(_dayJson, 200);
    });

    final report = await repository.fetchDay(CalendarDay(2026, 10, 1));

    expect(requested.toString(), 'http://api.test/api/v1/days/2026-10-01');
    expect(report.summary.net, 3315);
    expect(report.summary.busy, const Duration(minutes: 37));
    expect(report.summary.cash.amount, 1500);
    expect(report.trips.single.payment, PaymentMethod.card);
    expect(report.trips.single.start, almaty(1, 8, 10));
  });

  test('posts the draft with the driver offset', () async {
    late Map<String, Object?> sent;
    final repository = _repository((request) async {
      sent = jsonDecode(request.body) as Map<String, Object?>;
      return _json(sent, 201);
    });

    final result = await repository.addTrip(draft(start: almaty(1, 9, 5), minutes: 15));

    expect(sent, {
      'id': 'd1',
      'start': '2026-10-01T09:05:00+05:00',
      'end': '2026-10-01T09:20:00+05:00',
      'amount': 2000,
      'payment': 'card',
      'commission': 300,
    });
    expect(result.created, isTrue);
  });

  test('a 200 reply means the trip was already stored', () async {
    final repository = _repository(
      (request) async => _json(jsonDecode(request.body) as Object, 200),
    );

    expect((await repository.addTrip(draft())).created, isFalse);
  });

  test('retry after a lost response reuses the same id', () async {
    final ids = <String>[];
    var calls = 0;
    final repository = _repository((request) async {
      ids.add((jsonDecode(request.body) as Map<String, Object?>)['id']! as String);
      if (calls++ == 0) throw http.ClientException('connection reset');
      return _json(jsonDecode(request.body) as Object, 200);
    });
    final pending = draft(id: 'stable-id');

    await expectLater(repository.addTrip(pending), throwsA(isA<NetworkFailure>()));
    final retried = await repository.addTrip(pending);

    expect(ids, ['stable-id', 'stable-id']);
    expect(retried.created, isFalse);
  });

  test('maps conflicts by error code', () async {
    Future<ShiftFailure> failureFor(String code) async {
      final repository = _repository(
        (_) async => _json({
          'error': {'code': code, 'message': 'x', 'fields': <Object>[]},
        }, 409),
      );
      try {
        await repository.addTrip(draft());
      } on ShiftFailure catch (failure) {
        return failure;
      }
      fail('expected a failure');
    }

    expect(
      await failureFor('trip_overlap'),
      isA<TripConflictFailure>().having((f) => f.kind, 'kind', TripConflictKind.overlap),
    );
    expect(
      await failureFor('trip_id_conflict'),
      isA<TripConflictFailure>().having((f) => f.kind, 'kind', TripConflictKind.idReused),
    );
  });

  test('maps validation errors to fields', () async {
    final repository = _repository(
      (_) async => _json({
        'error': {
          'code': 'invalid_trip',
          'message': 'Amount must be greater than zero',
          'fields': [
            {'field': 'amount', 'message': 'Amount must be greater than zero'},
          ],
        },
      }, 422),
    );

    await expectLater(
      repository.addTrip(draft()),
      throwsA(isA<InvalidTripFailure>().having((f) => f.fields.keys, 'fields', [TripField.amount])),
    );
  });

  test('server errors and garbage are reported, not thrown raw', () async {
    final down = _repository((_) async => http.Response('oops', 503));
    final garbage = _repository((_) async => http.Response('<html>', 200));

    await expectLater(down.fetchShiftDays(), throwsA(isA<UnexpectedFailure>()));
    await expectLater(garbage.fetchShiftDays(), throwsA(isA<UnexpectedFailure>()));
  });
}
