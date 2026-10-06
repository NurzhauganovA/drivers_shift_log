import 'package:flutter/foundation.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';

enum TripField {
  start,
  end,
  amount,
  payment,
  commission;

  static TripField? fromWire(String value) =>
      values.where((field) => field.name == value).firstOrNull;
}

/// A trip the driver is about to submit.
///
/// [id] is generated once when the form opens and reused for every retry, so
/// the server can recognize a repeated submission instead of storing it twice.
@immutable
class TripDraft {
  const TripDraft({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
    required this.commission,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final int amount;
  final PaymentMethod payment;
  final int commission;

  /// Mirrors the server rules so most mistakes are caught before a request.
  Map<TripField, String> validate() => {
    if (!end.isAfter(start)) TripField.end: 'Окончание должно быть позже начала',
    if (amount <= 0) TripField.amount: 'Сумма должна быть больше нуля',
    if (commission < 0) TripField.commission: 'Комиссия не может быть отрицательной',
    if (commission > amount && amount > 0)
      TripField.commission: 'Комиссия не может быть больше суммы',
  };

  Trip toTrip() => Trip(
    id: id,
    start: start,
    end: end,
    amount: amount,
    payment: payment,
    commission: commission,
  );
}

@immutable
class AddTripResult {
  const AddTripResult({required this.trip, required this.created});

  final Trip trip;

  /// False when the server already had this trip, i.e. the request was a retry.
  final bool created;
}
