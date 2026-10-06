import 'package:flutter/foundation.dart';

enum PaymentMethod {
  cash('cash'),
  card('card');

  const PaymentMethod(this.wireName);

  final String wireName;

  static PaymentMethod fromWire(String value) => values.firstWhere(
    (method) => method.wireName == value,
    orElse: () => throw FormatException('Unknown payment method', value),
  );
}

/// A paid ride. [start] and [end] are absolute instants; money is whole tenge.
@immutable
class Trip {
  const Trip({
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

  Duration get duration => end.difference(start);

  int get net => amount - commission;

  @override
  bool operator ==(Object other) =>
      other is Trip &&
      other.id == id &&
      other.start.isAtSameMomentAs(start) &&
      other.end.isAtSameMomentAs(end) &&
      other.amount == amount &&
      other.payment == payment &&
      other.commission == commission;

  @override
  int get hashCode => Object.hash(
    id,
    start.microsecondsSinceEpoch,
    end.microsecondsSinceEpoch,
    amount,
    payment,
    commission,
  );
}
