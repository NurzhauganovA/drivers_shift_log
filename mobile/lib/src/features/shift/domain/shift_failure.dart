import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

/// Errors the UI knows how to explain. Messages are user-facing.
sealed class ShiftFailure implements Exception {
  const ShiftFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The request may or may not have reached the server. Safe to retry with the same draft.
final class NetworkFailure extends ShiftFailure {
  const NetworkFailure() : super('Нет связи с сервером. Проверьте интернет и повторите.');
}

final class InvalidTripFailure extends ShiftFailure {
  const InvalidTripFailure(this.fields, [super.message = 'Проверьте данные поездки']);

  final Map<TripField, String> fields;
}

enum TripConflictKind { idReused, overlap }

final class TripConflictFailure extends ShiftFailure {
  const TripConflictFailure(this.kind, super.message);

  final TripConflictKind kind;
}

final class UnexpectedFailure extends ShiftFailure {
  const UnexpectedFailure([super.message = 'Что-то пошло не так. Попробуйте ещё раз.']);
}
