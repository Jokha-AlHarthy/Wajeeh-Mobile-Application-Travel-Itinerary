import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import '../utils/saved_trip_extensions.dart';
import '../utils/trip_day_route_colors.dart';
import 'day_route_place_resolver.dart';

/// One map pin: numbered within its day; color matches that day’s route.
class FullTripPin {
  const FullTripPin({
    required this.dayListIndex,
    required this.dayNumber,
    required this.orderInDay,
    required this.color,
    required this.position,
    required this.name,
    required this.timeLabel,
    required this.activityLabel,
    required this.dayHeading,
  });

  final int dayListIndex;
  final int dayNumber;
  final int orderInDay;
  final Color color;
  final LatLng position;
  final String name;
  final String timeLabel;
  final String activityLabel;
  final String dayHeading;
}

/// One day’s polyline (same color as that day’s markers).
class FullTripDayPolyline {
  const FullTripDayPolyline({
    required this.dayListIndex,
    required this.color,
    required this.points,
  });

  final int dayListIndex;
  final Color color;
  final List<LatLng> points;
}

class FullTripRouteResolution {
  const FullTripRouteResolution({
    required this.pins,
    required this.dayPolylines,
    required this.skippedCount,
  });

  final List<FullTripPin> pins;
  final List<FullTripDayPolyline> dayPolylines;
  final int skippedCount;
}

class FullTripRoutePlaceResolver {
  FullTripRoutePlaceResolver._();

  static String dayHeadingLine(
    BuildContext context,
    int dayNumber,
    String dateStrFromMap,
    Map<String, dynamic> trip,
  ) {
    final start = trip.tripStartDate;
    if (start != null) {
      final d = DateTime(start.year, start.month, start.day)
          .add(Duration(days: dayNumber - 1));
      final lang = Localizations.localeOf(context).languageCode;
      if (lang == 'ar') {
        return '${context.tr('day')} $dayNumber · ${d.day}/${d.month}';
      }
      return '${context.tr('day')} $dayNumber · ${d.month}/${d.day}';
    }
    if (dateStrFromMap.isNotEmpty) {
      return '${context.tr('day')} $dayNumber · $dateStrFromMap';
    }
    return '${context.tr('day')} $dayNumber';
  }

  static Future<FullTripRouteResolution> resolve({
    required BuildContext context,
    required TravelProvider travel,
    required Map<String, dynamic> trip,
  }) async {
    final days = parsedDaysFromTrip(trip);
    if (days.isEmpty) {
      return const FullTripRouteResolution(
        pins: [],
        dayPolylines: [],
        skippedCount: 0,
      );
    }

    /// Built synchronously before any geocode await.
    final pending = <({
      int dayListIndex,
      int dayNumber,
      String heading,
      Color color,
      int orderInDay,
      Map<String, dynamic> place,
      String timeLabel,
      String activity,
    })>[];
    final colorByDayIndex = <int, Color>{};

    for (var dayIdx = 0; dayIdx < days.length; dayIdx++) {
      final dayMap = days[dayIdx];
      final dn = dayMap['dayNumber'];
      final dayNumber =
          dn is int ? dn : int.tryParse(dn.toString()) ?? dayIdx + 1;
      final dateStr = dayMap['date']?.toString() ?? '';
      final heading = dayHeadingLine(context, dayNumber, dateStr, trip);
      final color = TripDayRouteColors.accentFor(context, dayIdx);
      colorByDayIndex[dayIdx] = color;

      final placesRaw = dayMap['places'];
      final places = <Map<String, dynamic>>[];
      if (placesRaw is List) {
        for (final p in placesRaw) {
          if (p is Map<String, dynamic>) {
            places.add(p);
          } else if (p is Map) {
            places.add(Map<String, dynamic>.from(p));
          }
        }
      }

      if (places.isEmpty) {
        continue;
      }

      final ordered = DayRoutePlaceResolver.orderedPlacesForRoute(travel, places);
      var orderInDay = 1;
      for (final place in ordered) {
        pending.add((
          dayListIndex: dayIdx,
          dayNumber: dayNumber,
          heading: heading,
          color: color,
          orderInDay: orderInDay,
          place: place,
          timeLabel: DayRoutePlaceResolver.scheduleLabelForTripPlace(
            context,
            travel,
            place,
            dayNumber,
          ),
          activity: DayRoutePlaceResolver.activityLineForPlace(place),
        ));
        orderInDay++;
      }
    }

    var skipped = 0;
    final pins = <FullTripPin>[];
    final pointsByDay = <int, List<LatLng>>{};

    for (final row in pending) {
      final pos = await DayRoutePlaceResolver.coordsOrGeocode(travel, row.place);
      if (pos == null) {
        skipped++;
        continue;
      }
      final name = travel.placeName(row.place);
      pins.add(
        FullTripPin(
          dayListIndex: row.dayListIndex,
          dayNumber: row.dayNumber,
          orderInDay: row.orderInDay,
          color: row.color,
          position: pos,
          name: name,
          timeLabel: row.timeLabel,
          activityLabel: row.activity,
          dayHeading: row.heading,
        ),
      );
      pointsByDay.putIfAbsent(row.dayListIndex, () => <LatLng>[]).add(pos);
    }

    final polylines = <FullTripDayPolyline>[];
    for (final e in pointsByDay.entries) {
      final pts = e.value;
      if (pts.length >= 2) {
        final dayIdx = e.key;
        final color = colorByDayIndex[dayIdx]!;
        final closed = List<LatLng>.from(pts)..add(pts.first);
        polylines.add(
          FullTripDayPolyline(
            dayListIndex: dayIdx,
            color: color,
            points: closed,
          ),
        );
      }
    }

    return FullTripRouteResolution(
      pins: pins,
      dayPolylines: polylines,
      skippedCount: skipped,
    );
  }
}
