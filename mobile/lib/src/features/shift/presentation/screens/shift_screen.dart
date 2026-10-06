import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_log/src/core/config/app_config.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/core/widgets/pressable.dart';
import 'package:shift_log/src/features/shift/domain/day_summary.dart';
import 'package:shift_log/src/features/shift/domain/shift_failure.dart';
import 'package:shift_log/src/features/shift/presentation/screens/add_trip_sheet.dart';
import 'package:shift_log/src/features/shift/presentation/state/shift_providers.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/day_states.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/payment_split_card.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/summary_hero.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/summary_stats.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/trips_section.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/week_strip.dart';

class ShiftScreen extends ConsumerStatefulWidget {
  const ShiftScreen({super.key});

  @override
  ConsumerState<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends ConsumerState<ShiftScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(shiftDaysProvider, fireImmediately: true, (_, next) {
      if (next case AsyncData(:final value)) {
        ref.read(selectedDayProvider.notifier).openLatestShift(value);
      }
    });
  }

  SelectedDayNotifier get _days => ref.read(selectedDayProvider.notifier);

  Future<void> _refresh(CalendarDay day) async {
    try {
      await Future.wait([
        ref.refresh(dayReportProvider(day).future),
        ref.refresh(shiftDaysProvider.future),
      ]);
    } on ShiftFailure {
      // The error state of the day view explains what happened.
    }
  }

  Future<void> _pickDate(CalendarDay selected, CalendarDay today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.toDateTime(),
      firstDate: DateTime(2020),
      lastDate: today.toDateTime(),
    );
    if (picked != null) _days.select(CalendarDay.of(picked));
  }

  Future<void> _addTrip(CalendarDay day) async {
    _days.keepCurrentDay();
    final clock = ref.read(driverClockProvider);
    final report = ref.read(dayReportProvider(day)).value;
    final result = await showAddTripSheet(
      context,
      suggestedStart: _suggestStart(day, report, clock),
    );
    if (result == null || !mounted) return;
    _days.select(clock.dayOf(result.trip.start));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.created ? 'Поездка добавлена' : 'Эта поездка уже была сохранена ранее',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedDayProvider);
    final clock = ref.watch(driverClockProvider);
    final today = clock.today();
    final day = selection.day;
    final shiftDays = ref.watch(shiftDaysProvider).value ?? const <ShiftDay>[];
    final canGoForward = day.isBefore(today);
    final topInset = MediaQuery.paddingOf(context).top;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _days.shift(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _days.shift(1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              RefreshIndicator(
                edgeOffset: _Header.extent + topInset,
                onRefresh: () => _refresh(day),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _Header(
                        topInset: topInset,
                        selected: day,
                        today: today,
                        shiftDays: {for (final d in shiftDays) d.day},
                        onSelected: _days.select,
                        onToday: _days.goToToday,
                        onPickDate: () => _pickDate(day, today),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      sliver: SliverToBoxAdapter(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity > 300) _days.shift(-1);
                            if (velocity < -300 && canGoForward) _days.shift(1);
                          },
                          child: _DayTransition(
                            selection: selection,
                            child: _DayContent(
                              key: ValueKey(day),
                              day: day,
                              today: today,
                              clock: clock,
                              latestShift: shiftDays.firstOrNull?.day,
                              onAddTrip: () => _addTrip(day),
                              onOpenDay: _days.select,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 20),
                  child: Center(child: _AddTripButton(onPressed: () => _addTrip(day))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _suggestStart(CalendarDay day, DayReport? report, DriverClock clock) {
  DateTime roundDown(DateTime t) => DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch - t.millisecondsSinceEpoch % const Duration(minutes: 5).inMilliseconds,
    isUtc: true,
  );

  final now = clock.now();
  final lastEnd = report?.trips.lastOrNull?.end;
  if (lastEnd != null) {
    final afterLast = lastEnd.add(const Duration(minutes: 10));
    if (clock.dayOf(afterLast) == day && afterLast.isBefore(now)) return roundDown(afterLast);
  }
  if (day == clock.today()) return roundDown(now.subtract(const Duration(minutes: 25)));
  return clock.fromWallClock(day.toDateTime().add(const Duration(hours: 9)));
}

class _Header extends SliverPersistentHeaderDelegate {
  _Header({
    required this.topInset,
    required this.selected,
    required this.today,
    required this.shiftDays,
    required this.onSelected,
    required this.onToday,
    required this.onPickDate,
  });

  static const extent = 136.0;

  final double topInset;
  final CalendarDay selected;
  final CalendarDay today;
  final Set<CalendarDay> shiftDays;
  final ValueChanged<CalendarDay> onSelected;
  final VoidCallback onToday;
  final VoidCallback onPickDate;

  @override
  double get minExtent => extent + topInset;

  @override
  double get maxExtent => extent + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final scrolled = shrinkOffset > 0 || overlapsContent;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: scrolled ? 0.78 : 1),
            border: Border(
              bottom: BorderSide(
                color: scrolled ? palette.separator : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Pressable(
                            onPressed: onPickDate,
                            semanticLabel: 'Выбрать дату',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatMonthYear(selected),
                                    style: text.headlineMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more_rounded, color: palette.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedOpacity(
                        opacity: selected == today ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Pressable(
                          onPressed: selected == today ? null : onToday,
                          child: _Pill(label: 'Сегодня', color: palette.accent, filled: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              WeekStrip(
                selected: selected,
                today: today,
                shiftDays: shiftDays,
                onSelected: onSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_Header old) =>
      old.selected != selected ||
      old.today != today ||
      old.topInset != topInset ||
      !_sameDays(old.shiftDays, shiftDays);

  static bool _sameDays(Set<CalendarDay> a, Set<CalendarDay> b) =>
      a.length == b.length && a.containsAll(b);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.12 : 0),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

/// Slides the day content in the direction of travel through the calendar.
class _DayTransition extends StatelessWidget {
  const _DayTransition({required this.selection, required this.child});

  final DaySelection selection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(selection.day);
        final dx = 0.06 * selection.direction * (incoming ? 1 : -1);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DayContent extends ConsumerWidget {
  const _DayContent({
    required this.day,
    required this.today,
    required this.clock,
    required this.latestShift,
    required this.onAddTrip,
    required this.onOpenDay,
    super.key,
  });

  final CalendarDay day;
  final CalendarDay today;
  final DriverClock clock;
  final CalendarDay? latestShift;
  final VoidCallback onAddTrip;
  final ValueChanged<CalendarDay> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(dayReportProvider(day));
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(formatRelativeDay(day, today), style: text.headlineLarge)),
                  if (AppConfig.isDemo)
                    Tooltip(
                      message: 'Данные хранятся в браузере, сервер не используется',
                      child: _Pill(label: 'Демо-режим', color: context.palette.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                day.differenceInDays(today).abs() <= 1
                    ? '${_capitalized(formatWeekday(day))}, ${formatDayMonth(day)}'
                    : _capitalized(formatWeekday(day)),
                style: text.bodyMedium?.copyWith(color: context.palette.textSecondary),
              ),
            ],
          ),
        ),
        switch (report) {
          // Keeps showing the previous data while a refresh is in flight.
          AsyncValue(:final value?) => _DayReportView(
            report: value,
            clock: clock,
            onAddTrip: onAddTrip,
            onOpenLatest: latestShift != null && latestShift != day
                ? () => onOpenDay(latestShift!)
                : null,
          ),
          AsyncError(:final error) => DayErrorView(
            message: error is ShiftFailure ? error.message : const UnexpectedFailure().message,
            onRetry: () => ref.invalidate(dayReportProvider(day)),
          ),
          _ => const DaySkeleton(),
        },
      ],
    );
  }

  static String _capitalized(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _DayReportView extends StatelessWidget {
  const _DayReportView({
    required this.report,
    required this.clock,
    required this.onAddTrip,
    required this.onOpenLatest,
  });

  final DayReport report;
  final DriverClock clock;
  final VoidCallback onAddTrip;
  final VoidCallback? onOpenLatest;

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryHero(summary: summary),
        const SizedBox(height: 12),
        if (report.trips.isEmpty)
          EmptyDayView(onAddTrip: onAddTrip, onOpenLatest: onOpenLatest)
        else ...[
          SummaryStats(summary: summary),
          const SizedBox(height: 12),
          PaymentSplitCard(summary: summary),
          const SizedBox(height: 28),
          TripsSection(trips: report.trips, clock: clock),
        ],
      ],
    );
  }
}

class _AddTripButton extends StatelessWidget {
  const _AddTripButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Добавить поездку',
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: palette.background),
            const SizedBox(width: 8),
            Text(
              'Новая поездка',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: palette.background, fontFeatures: AppTheme.tabular),
            ),
          ],
        ),
      ),
    );
  }
}
