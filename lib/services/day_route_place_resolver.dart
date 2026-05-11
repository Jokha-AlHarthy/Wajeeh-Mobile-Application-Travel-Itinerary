import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import '../utils/ai_trip_plan_markdown_parser.dart';
import '../utils/saved_trip_extensions.dart';
import '../utils/trip_place_lat_lng.dart';

/// One stop on the day route map (itinerary order).
class DayRouteStop {
  const DayRouteStop({
    required this.order,
    required this.name,
    required this.position,
    required this.timeLabel,
    required this.activityLabel,
  });

  final int order;
  final String name;
  final LatLng position;
  final String timeLabel;
  final String activityLabel;
}

/// Result of resolving a single day's places to coordinates.
class DayRouteResolution {
  const DayRouteResolution({
    required this.dayTitle,
    required this.stops,
    required this.skippedCount,
  });

  final String dayTitle;
  final List<DayRouteStop> stops;
  final int skippedCount;
}

class DayRoutePlaceResolver {
  DayRoutePlaceResolver._();

  /// Same visit order as trip itinerary UI: hotel rows first, then timed by clock.
  static List<Map<String, dynamic>> orderedPlacesForRoute(
    TravelProvider travel,
    List<Map<String, dynamic>> places,
  ) {
    if (places.isNotEmpty &&
        places.every((p) =>
            (p['itineraryCategoryKey']?.toString().trim() ?? '').isNotEmpty)) {
      final out = List<Map<String, dynamic>>.from(places);
      out.sort(
        (a, b) => AiTripPlanMarkdownParser.slotOrderForCategoryKey(
              a['itineraryCategoryKey']?.toString(),
            )
            .compareTo(
              AiTripPlanMarkdownParser.slotOrderForCategoryKey(
                b['itineraryCategoryKey']?.toString(),
              ),
            ),
      );
      return out;
    }

    final hotels = <Map<String, dynamic>>[];
    final timed = <Map<String, dynamic>>[];
    for (final p in places) {
      if (travel.placeIsHotelStayInTrip(p)) {
        hotels.add(p);
      } else {
        timed.add(p);
      }
    }
    timed.sort((a, b) {
      final ma = travel.scheduledTimeMinutesFromTripPlace(a) ?? 720;
      final mb = travel.scheduledTimeMinutesFromTripPlace(b) ?? 720;
      return ma.compareTo(mb);
    });
    return [...hotels, ...timed];
  }

  static String scheduleLabelForTripPlace(
    BuildContext context,
    TravelProvider travel,
    Map<String, dynamic> place,
    int dayNumber,
  ) {
    if (travel.placeIsHotelStayInTrip(place)) {
      return context.tr('hotel_checkin_day_line', {
        'day': dayNumber.toString(),
      });
    }
    final mins = travel.scheduledTimeMinutesFromTripPlace(place);
    if (mins == null) {
      return context.tr('schedule_time_pending');
    }
    final dt = DateTime(2000, 1, 1, mins ~/ 60, mins % 60);
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ar') {
      return DateFormat.jm('ar').format(dt);
    }
    return DateFormat.jm('en').format(dt);
  }

  static String activityLineForPlace(Map<String, dynamic> place) {
    final editorial = place['editorialSummary'];
    if (editorial is Map && editorial['text'] != null) {
      final t = editorial['text'].toString().trim();
      if (t.isEmpty) return '';
      if (t.length > 140) {
        return '${t.substring(0, 137)}...';
      }
      return t;
    }
    final types = (place['types'] as List?)
        ?.map((e) => e.toString())
        .where((e) =>
            e.isNotEmpty &&
            e != 'establishment' &&
            e != 'point_of_interest')
        .toList();
    if (types != null && types.isNotEmpty) {
      return types.first.replaceAll('_', ' ');
    }
    return '';
  }

  static Future<LatLng?> coordsOrGeocode(
    TravelProvider travel,
    Map<String, dynamic> place,
  ) async {
    final ll = latLngFromTripPlace(place);
    if (ll.lat != null &&
        ll.lng != null &&
        latLngValid(ll.lat!, ll.lng!)) {
      return LatLng(ll.lat!, ll.lng!);
    }
    final addr = travel.placeAddress(place).trim();
    final name = travel.placeName(place).trim();
    final query = [name, addr].where((s) => s.isNotEmpty).join(', ');
    if (query.isEmpty) return null;
    try {
      final locs = await locationFromAddress(query);
      if (locs.isEmpty) return null;
      final l = locs.first;
      if (!latLngValid(l.latitude, l.longitude)) return null;
      return LatLng(l.latitude, l.longitude);
    } catch (_) {
      return null;
    }
  }

  /// [dayListIndex] indexes into [trip] `days` list (same as day selector).
  static Future<DayRouteResolution?> resolve({
    required BuildContext context,
    required TravelProvider travel,
    required Map<String, dynamic> trip,
    required int dayListIndex,
  }) async {
    final days = parsedDaysFromTrip(trip);
    if (dayListIndex < 0 || dayListIndex >= days.length) {
      return null;
    }
    final dayMap = days[dayListIndex];
    final dn = dayMap['dayNumber'];
    final dayNumber = dn is int ? dn : int.tryParse(dn.toString()) ?? dayListIndex + 1;
    final dateStr = dayMap['date']?.toString() ?? '';
    final dayTitle = _dayTitleLine(context, dayNumber, dateStr, trip);

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
      return DayRouteResolution(dayTitle: dayTitle, stops: [], skippedCount: 0);
    }

    final ordered = orderedPlacesForRoute(travel, places);
    final preMeta = <({Map<String, dynamic> place, String timeLabel, String activity})>[];
    for (final place in ordered) {
      preMeta.add((
        place: place,
        timeLabel: scheduleLabelForTripPlace(context, travel, place, dayNumber),
        activity: activityLineForPlace(place),
      ));
    }

    var skipped = 0;
    final stops = <DayRouteStop>[];
    var order = 1;

    for (final meta in preMeta) {
      final pos = await coordsOrGeocode(travel, meta.place);
      if (pos == null) {
        skipped++;
        continue;
      }
      final name = travel.placeName(meta.place);
      stops.add(
        DayRouteStop(
          order: order,
          name: name,
          position: pos,
          timeLabel: meta.timeLabel,
          activityLabel: meta.activity,
        ),
      );
      order++;
    }

    return DayRouteResolution(
      dayTitle: dayTitle,
      stops: stops,
      skippedCount: skipped,
    );
  }

  static String _dayTitleLine(
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
        return '${context.tr('day')} $dayNumber · ${DateFormat('d MMM', 'ar').format(d)}';
      }
      return '${context.tr('day')} $dayNumber · ${DateFormat('M/d', 'en').format(d)}';
    }
    if (dateStrFromMap.isNotEmpty) {
      return '${context.tr('day')} $dayNumber · $dateStrFromMap';
    }
    return '${context.tr('day')} $dayNumber';
  }
}
