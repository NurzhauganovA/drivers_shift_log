import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/features/shift/data/json_mappers.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';
import 'package:shift_log/src/features/shift/domain/shift_repository.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

/// Talks to the FastAPI backend (`/api/v1`).
class RemoteShiftRepository implements ShiftRepository {
  RemoteShiftRepository({
    required this._baseUri,
    required this._clock,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Uri _baseUri;
  final DriverClock _clock;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<DayReport> fetchDay(CalendarDay day) async {
    final body = await _send(() => _client.get(_uri('days/${day.toIso()}')));
    return _decode(body.body, (json) => dayReportFromJson(json! as Json));
  }

  @override
  Future<List<ShiftDay>> fetchShiftDays() async {
    final body = await _send(() => _client.get(_uri('days')));
    return _decode(
      body.body,
      (json) => [for (final day in json! as List<Object?>) shiftDayFromJson(day! as Json)],
    );
  }

  @override
  Future<AddTripResult> addTrip(TripDraft draft) async {
    final response = await _send(
      () => _client.post(
        _uri('trips'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(tripDraftToJson(draft, _clock)),
      ),
    );
    return AddTripResult(
      trip: _decode(response.body, (json) => tripFromJson(json! as Json)),
      // 201 means stored now; 200 means the server already had this exact trip.
      created: response.statusCode == 201,
    );
  }

  @override
  void dispose() => _client.close();

  Uri _uri(String path) => _baseUri.resolve('api/v1/$path');

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    throw _failureFrom(response);
  }

  ShiftFailure _failureFrom(http.Response response) {
    final error = _tryDecodeError(response.body);
    final code = error?['code'] as String?;
    return switch ((response.statusCode, code)) {
      (409, 'trip_overlap') => const TripConflictFailure(
        TripConflictKind.overlap,
        'В это время уже есть другая поездка',
      ),
      (409, _) => const TripConflictFailure(
        TripConflictKind.idReused,
        'Эта поездка уже сохранена с другими данными',
      ),
      (422, _) => InvalidTripFailure(_fieldErrors(error)),
      (>= 500, _) => const UnexpectedFailure('Сервер временно недоступен. Повторите позже.'),
      _ => const UnexpectedFailure(),
    };
  }

  static Json? _tryDecodeError(String body) {
    try {
      return (jsonDecode(body) as Json)['error'] as Json?;
    } on Object {
      return null;
    }
  }

  /// Server messages are English; the client shows its own text per field.
  static Map<TripField, String> _fieldErrors(Json? error) {
    final fields = <TripField, String>{};
    for (final item in (error?['fields'] as List<Object?>? ?? const [])) {
      final field = TripField.fromWire((item! as Json)['field']! as String);
      if (field != null) fields[field] = _fieldMessages[field]!;
    }
    return fields;
  }

  static const _fieldMessages = {
    TripField.start: 'Неверное время начала',
    TripField.end: 'Окончание должно быть позже начала',
    TripField.amount: 'Сумма должна быть больше нуля',
    TripField.payment: 'Выберите способ оплаты',
    TripField.commission: 'Комиссия должна быть от 0 до суммы поездки',
  };

  static T _decode<T>(String body, T Function(Object? json) map) {
    try {
      return map(jsonDecode(body));
    } on Object {
      throw const UnexpectedFailure('Сервер вернул неожиданный ответ');
    }
  }
}
