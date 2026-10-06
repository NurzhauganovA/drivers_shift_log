import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shift_log/src/core/format/formatters.dart';
import 'package:shift_log/src/core/theme/palette.dart';
import 'package:shift_log/src/core/time/driver_clock.dart';
import 'package:shift_log/src/core/widgets/surface_card.dart';
import 'package:shift_log/src/features/shift/domain/trip.dart';
import 'package:shift_log/src/features/shift/presentation/widgets/trip_tile.dart';

/// Trips of the day as an inset grouped list.
class TripsSection extends StatelessWidget {
  const TripsSection({required this.trips, required this.clock, super.key});

  final List<Trip> trips;
  final DriverClock clock;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Text('Поездки', style: text.titleLarge),
              const Spacer(),
              Text(formatTripCount(trips.length), style: text.bodySmall),
            ],
          ),
        ),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, trip) in trips.indexed) ...[
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 84),
                    child: Divider(color: context.palette.separator),
                  ),
                TripTile(trip: trip, clock: clock)
                    .animate(delay: (40 * index.clamp(0, 12)).ms)
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutCubic),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
