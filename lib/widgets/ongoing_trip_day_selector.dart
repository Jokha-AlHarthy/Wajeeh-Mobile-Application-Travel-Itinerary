import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../utils/saved_trip_extensions.dart';
import '../utils/trip_day_route_colors.dart';

/// Horizontal day chips: tap to select that day (itinerary / detail). No map control here.
class OngoingTripDaySelector extends StatelessWidget {
  const OngoingTripDaySelector({
    super.key,
    required this.trip,
    required this.dayCount,
    required this.selectedIndex,
    required this.onDaySelected,
    this.showSelectionHighlight = true,
  });

  final Map<String, dynamic> trip;
  final int dayCount;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  /// When false, no pill uses the selected fill style.
  final bool showSelectionHighlight;

  @override
  Widget build(BuildContext context) {
    if (dayCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final start = trip.tripStartDate;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: dayCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final accent = TripDayRouteColors.accentFor(context, index);
          final selected =
              showSelectionHighlight && index == selectedIndex;
          final label = _label(context, start, index);

          final surface = theme.brightness == Brightness.dark
              ? theme.colorScheme.surface.withValues(alpha: 0.92)
              : Colors.white;
          final bg = selected ? accent : surface;
          final fg = selected
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.9);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDaySelected(index),
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: accent,
                    width: selected ? 2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.35 : 0.07,
                      ),
                      blurRadius: selected ? 7 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 16,
                        color: fg,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _label(BuildContext context, DateTime? start, int index) {
    final dayNum = index + 1;
    if (start == null) {
      return '${context.tr('day')} $dayNum';
    }
    final d = DateTime(start.year, start.month, start.day)
        .add(Duration(days: index));
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ar') {
      return '${context.tr('day')} $dayNum · ${d.day}/${d.month}';
    }
    return '${context.tr('day')} $dayNum · ${d.month}/${d.day}';
  }
}
