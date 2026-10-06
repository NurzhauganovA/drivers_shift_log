import 'package:flutter_test/flutter_test.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';

import '../../helpers.dart';

void main() {
  test('valid draft has no errors', () {
    expect(draft().validate(), isEmpty);
  });

  test('amount must be positive', () {
    expect(draft(amount: 0).validate().keys, [TripField.amount]);
  });

  test('end must be after start', () {
    expect(draft(minutes: 0).validate().keys, [TripField.end]);
    expect(draft(minutes: -10).validate().keys, [TripField.end]);
  });

  test('commission must stay within the amount', () {
    expect(draft(commission: -1).validate().keys, [TripField.commission]);
    expect(draft(amount: 1000, commission: 1200).validate().keys, [TripField.commission]);
    expect(draft(amount: 1000, commission: 1000).validate(), isEmpty);
  });
}
