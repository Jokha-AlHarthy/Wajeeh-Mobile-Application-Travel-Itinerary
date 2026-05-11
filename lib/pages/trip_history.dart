import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import '../utils/saved_trip_extensions.dart';
import '../utils/trip_day_route_navigation.dart';
import '../widgets/app_footer.dart';
import '../widgets/completed_trip_date_row.dart';
import 'notifications_screen.dart';
import 'trip_detail_screen.dart';

class TripHistory extends StatefulWidget {
  const TripHistory({super.key});

  @override
  State<TripHistory> createState() => _TripHistoryState();
}

class _TripHistoryState extends State<TripHistory> {
  void _openTripPlanForEdit(
    BuildContext context,
    Map<String, dynamic> trip,
    int index,
  ) {
    Navigator.pushNamed(
      context,
      '/trip_planing',
      arguments: <String, dynamic>{'trip': trip, 'index': index},
    );
  }

  void _openTripDetail(
    BuildContext context,
    Map<String, dynamic> t, {
    int? initialDayIndex,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          trip: t,
          initialDayIndex: initialDayIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travel = context.watch<TravelProvider>();
    final trips = travel.savedTrips;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.dividerTheme.color ??
        (theme.brightness == Brightness.dark
            ? Colors.white24
            : Colors.black87);
    final placeholderFill = theme.brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final mutedText = onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            Image.asset('images/logo.png', height: 55),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications,
                    size: 28,
                    color: onSurface,
                  ),
                  PositionedDirectional(
                    end: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: trips.isEmpty
            ? Center(
                child: Text(
                  context.tr('no_saved_itinerary'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      context.tr('my_trips_history'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final t = trips[index];
                        final loc = travel.historyLocationLinesForTrip(t);
                        return _TripHistoryTripCard(
                          key: ValueKey(
                            t['id']?.toString() ??
                                '${t['startDate']}_${t['endDate']}_$index',
                          ),
                          trip: t,
                          cityLine: loc['cities'] ?? '',
                          countryLine: loc['countries'] ?? '',
                          primary: primary,
                          onPrimary: onPrimary,
                          onSurface: onSurface,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          placeholderFill: placeholderFill,
                          mutedText: mutedText,
                          onEditPlan: () =>
                              _openTripPlanForEdit(context, t, index),
                          onOpenDetail: ({int? initialDayIndex}) =>
                              _openTripDetail(
                            context,
                            t,
                            initialDayIndex: initialDayIndex,
                          ),
                          onOpenFullTripMap: () => openFullTripRouteMap(
                            context,
                            travel,
                            t,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 1),
    );
  }
}

class _TripHistoryTripCard extends StatelessWidget {
  const _TripHistoryTripCard({
    super.key,
    required this.trip,
    required this.cityLine,
    required this.countryLine,
    required this.primary,
    required this.onPrimary,
    required this.onSurface,
    required this.cardColor,
    required this.borderColor,
    required this.placeholderFill,
    required this.mutedText,
    required this.onEditPlan,
    required this.onOpenDetail,
    required this.onOpenFullTripMap,
  });

  final Map<String, dynamic> trip;
  final String cityLine;
  final String countryLine;
  final Color primary;
  final Color onPrimary;
  final Color onSurface;
  final Color cardColor;
  final Color borderColor;
  final Color placeholderFill;
  final Color mutedText;
  final VoidCallback onEditPlan;
  final void Function({int? initialDayIndex}) onOpenDetail;
  final VoidCallback onOpenFullTripMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = trip;
    final ongoing = t.isOngoingTrip;
    final image = t['image']?.toString() ?? '';
    final dateLine = t['dateText']?.toString() ?? '';
    final rawName = t['tripName']?.toString().trim() ?? '';
    final tripTitle = rawName.isNotEmpty ? rawName : cityLine;
    final subtitleCities = rawName.isNotEmpty ? cityLine : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.white.withValues(alpha: 0.65)
              : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 96,
                              height: 96,
                              color: placeholderFill,
                              child: Icon(
                                Icons.image_outlined,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 96,
                          height: 96,
                          color: placeholderFill,
                          child: Icon(
                            Icons.image_outlined,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              tripTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                          ),
                          if (ongoing && parsedDaysFromTrip(t).isNotEmpty)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              tooltip: context.tr('view_full_trip_route_semantic'),
                              onPressed: onOpenFullTripMap,
                              icon: Icon(
                                Icons.map_outlined,
                                color: primary,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      if (ongoing && dateLine.isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            dateLine,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: mutedText,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: countryLine.isNotEmpty ? 6 : 4,
                      ),
                      if (subtitleCities.isNotEmpty)
                        Text(
                          subtitleCities,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (subtitleCities.isNotEmpty) const SizedBox(height: 4),
                      if (countryLine.isNotEmpty)
                        Text(
                          countryLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: mutedText,
                          ),
                        ),
                      SizedBox(
                        height: countryLine.isNotEmpty ? 8 : 6,
                      ),
                      Text(
                        '${context.tr('price')}: ${t['price']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!ongoing) ...[
              const SizedBox(height: 10),
              CompletedTripDateRow(
                trip: t,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedText,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (ongoing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEditPlan,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: primary,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.white
                            : Colors.transparent,
                      ),
                      child: Text(
                        context.tr('edit_plan'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onOpenDetail(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('detail'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onOpenDetail(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('details'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
