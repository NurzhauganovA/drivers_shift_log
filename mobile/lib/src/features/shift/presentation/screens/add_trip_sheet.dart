import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/core/widgets/pressable.dart';
import 'package:shift_log/src/core/widgets/surface_card.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/domain/trip_draft.dart';
import 'package:shift_log/src/features/shift/presentation/state/shift_providers.dart';
import 'package:uuid/uuid.dart';

Future<AddTripResult?> showAddTripSheet(BuildContext context, {required DateTime suggestedStart}) {
  return showModalBottomSheet<AddTripResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AddTripSheet(suggestedStart: suggestedStart),
  );
}

class AddTripSheet extends ConsumerStatefulWidget {
  const AddTripSheet({required this.suggestedStart, super.key});

  final DateTime suggestedStart;

  @override
  ConsumerState<AddTripSheet> createState() => _AddTripSheetState();
}

class _AddTripSheetState extends ConsumerState<AddTripSheet> {
  static const _defaultCommissionPercent = 15;
  static const _uuid = Uuid();

  /// Idempotency key. Kept while the data is unchanged, so a retry after a
  /// lost response is recognized by the server; replaced on any edit because
  /// edited data describes a different trip.
  String _id = _uuid.v4();

  late DateTime _start = widget.suggestedStart;
  late DateTime _end = widget.suggestedStart.add(const Duration(minutes: 20));
  PaymentMethod _payment = PaymentMethod.card;
  final _amount = TextEditingController();
  final _commission = TextEditingController();
  bool _commissionTouched = false;

  bool _submitting = false;
  bool _showFieldErrors = false;
  Map<TripField, String> _serverErrors = const {};
  ShiftFailure? _failure;

  DriverClock get _clock => ref.read(driverClockProvider);

  TripDraft get _draft => TripDraft(
    id: _id,
    start: _start,
    end: _end,
    amount: int.tryParse(_amount.text) ?? 0,
    payment: _payment,
    commission: int.tryParse(_commission.text) ?? 0,
  );

  Map<TripField, String> get _errors =>
      _showFieldErrors ? {..._serverErrors, ..._draft.validate()} : _serverErrors;

  @override
  void dispose() {
    _amount.dispose();
    _commission.dispose();
    super.dispose();
  }

  void _edited(VoidCallback change) {
    setState(() {
      change();
      _id = _uuid.v4();
      _failure = null;
      _serverErrors = const {};
    });
  }

  void _onAmountChanged(String value) => _edited(() {
    if (_commissionTouched) return;
    final amount = int.tryParse(value) ?? 0;
    _commission.text = amount == 0 ? '' : '${amount * _defaultCommissionPercent ~/ 100}';
  });

  Future<void> _submit() async {
    final draft = _draft;
    if (draft.validate().isNotEmpty) {
      setState(() => _showFieldErrors = true);
      return;
    }
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final result = await ref.read(tripSubmitterProvider).submit(draft);
      if (mounted) Navigator.of(context).pop(result);
    } on InvalidTripFailure catch (failure) {
      setState(() {
        _serverErrors = failure.fields;
        _failure = failure.fields.isEmpty ? failure : null;
      });
    } on ShiftFailure catch (failure) {
      setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = _clock.toWallClock(isStart ? _start : _end);
    final picked = await _showDateTimePicker(context, current);
    if (picked == null) return;
    final instant = _clock.fromWallClock(picked);
    _edited(() {
      if (isStart) {
        final length = _end.difference(_start);
        _start = instant;
        // Keep the trip length when the start moves, as calendar apps do.
        if (!length.isNegative) _end = instant.add(length);
      } else {
        _end = instant;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final errors = _errors;
    final duration = _end.difference(_start);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Новая поездка', style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _AmountField(
              controller: _amount,
              error: errors[TripField.amount],
              onChanged: _onAmountChanged,
            ),
            const SizedBox(height: 20),
            _PaymentSelector(
              value: _payment,
              onChanged: (method) => _edited(() => _payment = method),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _FormRow(
                    label: 'Начало',
                    onTap: () => _pickTime(isStart: true),
                    trailing: _ValueText(formatDateTimeShort(_clock.toWallClock(_start))),
                    error: errors[TripField.start],
                  ),
                  Divider(indent: 16, color: palette.separator),
                  _FormRow(
                    label: 'Окончание',
                    onTap: () => _pickTime(isStart: false),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (duration > Duration.zero)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(formatDuration(duration), style: text.bodySmall),
                          ),
                        _ValueText(formatDateTimeShort(_clock.toWallClock(_end))),
                      ],
                    ),
                    error: errors[TripField.end],
                  ),
                  Divider(indent: 16, color: palette.separator),
                  _FormRow(
                    label: 'Комиссия',
                    error: errors[TripField.commission],
                    trailing: SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _commission,
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        style: text.bodyLarge?.copyWith(fontFeatures: AppTheme.tabular),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '$_defaultCommissionPercent%',
                          suffixText: ' ₸',
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (_) => _edited(() => _commissionTouched = true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_commissionTouched)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Комиссия считается как $_defaultCommissionPercent% от суммы, её можно изменить',
                  style: text.bodySmall,
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _failure == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _FailureBanner(failure: _failure!),
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _submitting
                    ? SizedBox.square(
                        key: const ValueKey('progress'),
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: palette.onAccent),
                      )
                    : Text(
                        _failure is NetworkFailure ? 'Повторить' : 'Сохранить',
                        key: ValueKey(_failure is NetworkFailure),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> _showDateTimePicker(BuildContext context, DateTime initialWallClock) {
  // The picker works with device-local DateTimes; only the fields matter here.
  var value = DateTime(
    initialWallClock.year,
    initialWallClock.month,
    initialWallClock.day,
    initialWallClock.hour,
    initialWallClock.minute,
  );
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) {
      final palette = context.palette;
      return Container(
        height: 320,
        padding: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(value),
                    child: const Text('Готово'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: value,
                    use24hFormat: true,
                    onDateTimeChanged: (picked) => value = picked,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.onChanged, this.error});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return Column(
      children: [
        Text('Сумма', style: text.labelMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Grows with the number so the currency sign stays right next to it.
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                style: text.displayMedium?.copyWith(fontFeatures: AppTheme.tabular),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: text.displayMedium?.copyWith(color: palette.textTertiary),
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text('₸', style: text.headlineMedium?.copyWith(color: palette.textSecondary)),
          ],
        ),
        _FieldError(error),
      ],
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    const options = [
      (PaymentMethod.card, 'Карта', Icons.credit_card_rounded),
      (PaymentMethod.cash, 'Наличные', Icons.payments_outlined),
    ];
    final selectedIndex = options.indexWhere((o) => o.$1 == value);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (method, label, icon) in options)
                Expanded(
                  child: Pressable(
                    scale: 0.98,
                    onPressed: () => onChanged(method),
                    semanticLabel: label,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: method == value
                                ? (method == PaymentMethod.cash ? palette.cash : palette.card)
                                : palette.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: text.labelLarge?.copyWith(
                              color: method == value ? palette.textPrimary : palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.trailing, this.onTap, this.error});

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: text.bodyLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(fit: BoxFit.scaleDown, child: trailing),
                ),
              ),
            ],
          ),
          _FieldError(error, alignment: Alignment.centerRight),
        ],
      ),
    );
    return onTap == null ? row : Pressable(scale: 0.99, onPressed: onTap, child: row);
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: text.bodyMedium?.copyWith(fontFeatures: AppTheme.tabular)),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message, {this.alignment = Alignment.center});

  final String? message;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.palette.negative),
                ),
              ),
            ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failure});

  final ShiftFailure failure;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final hint = failure is NetworkFailure
        ? 'Повторная отправка безопасна: дубль не появится.'
        : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.negative.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: palette.negative, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(failure.message, style: text.bodyMedium),
                if (hint != null) ...[const SizedBox(height: 4), Text(hint, style: text.bodySmall)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
