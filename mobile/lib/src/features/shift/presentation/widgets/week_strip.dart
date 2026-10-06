import 'package:flutter/material.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/time/calendar_day.dart';
import 'package:shift_log/src/core/widgets/pressable.dart';

/// A swipeable row of weeks. The last page is the current week; days after
/// today are shown but disabled, days with trips get a dot.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    required this.selected,
    required this.today,
    required this.shiftDays,
    required this.onSelected,
    super.key,
  });

  final CalendarDay selected;
  final CalendarDay today;
  final Set<CalendarDay> shiftDays;
  final ValueChanged<CalendarDay> onSelected;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  /// Enough pages to scroll back several years.
  static const _pageCount = 520;
  late final PageController _controller = PageController(initialPage: _pageFor(widget.selected));

  int _pageFor(CalendarDay day) {
    final weeksBack = widget.today.startOfWeek.differenceInDays(day.startOfWeek) ~/ 7;
    return (_pageCount - 1 - weeksBack).clamp(0, _pageCount - 1);
  }

  CalendarDay _weekStartFor(int page) =>
      widget.today.startOfWeek.addDays(-7 * (_pageCount - 1 - page));

  @override
  void didUpdateWidget(WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _pageFor(widget.selected);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: PageView.builder(
        controller: _controller,
        itemCount: _pageCount,
        itemBuilder: (context, page) {
          final start = _weekStartFor(page);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++) Expanded(child: _dayCell(context, start.addDays(i))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dayCell(BuildContext context, CalendarDay day) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final isSelected = day == widget.selected;
    final isToday = day == widget.today;
    final isFuture = day.isAfter(widget.today);
    final hasTrips = widget.shiftDays.contains(day);

    final numberColor = switch ((isSelected, isToday, isFuture)) {
      (true, _, _) => palette.background,
      (_, true, _) => palette.accent,
      (_, _, true) => palette.textTertiary,
      _ => palette.textPrimary,
    };

    return Pressable(
      onPressed: isFuture ? null : () => widget.onSelected(day),
      semanticLabel: formatFullDate(day),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatWeekdayShort(day).toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: isFuture ? palette.textTertiary : palette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? palette.textPrimary : Colors.transparent,
            ),
            child: Text(
              '${day.day}',
              style: text.titleMedium?.copyWith(
                color: numberColor,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: AppTheme.tabular,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedOpacity(
            opacity: hasTrips ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
