import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import 'ai_trip_plan_markdown_parser.dart';

DateTime? tripDetailTripStartDate(Map<String, dynamic> trip) {
  final s = trip['startDate']?.toString();

  if (s == null || s.isEmpty) return null;

  return DateTime.tryParse(s);
}

String tripDetailDayTitle(
  BuildContext context,
  int dayNumber,
  String dateStrFromMap,
  Map<String, dynamic> trip,
) {
  final start = tripDetailTripStartDate(trip);

  if (start != null) {
    final d = DateTime(start.year, start.month, start.day)
        .add(Duration(days: dayNumber - 1));
    final lang = Localizations.localeOf(context).languageCode;

    if (lang == 'ar') {
      return '${context.tr('day')} $dayNumber: ${DateFormat('EEEE، d MMMM y', 'ar').format(d)}';
    }

    return '${context.tr('day')} $dayNumber: ${DateFormat('EEEE, MMMM d, y', 'en').format(d)}';
  }

  return '${context.tr('day')} $dayNumber${dateStrFromMap.isNotEmpty ? ': $dateStrFromMap' : ''}';
}

String tripDetailActivityScheduleLabel(
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

int tripDetailMinutesForSort(TravelProvider travel, Map<String, dynamic> place) {
  if (travel.placeIsHotelStayInTrip(place)) return -1;

  return travel.scheduledTimeMinutesFromTripPlace(place) ?? 720;
}

bool tripDetailPlacesUseStructuredLayout(List<Map<String, dynamic>> places) {
  if (places.isEmpty) return false;
  for (final p in places) {
    final k = p['itineraryCategoryKey']?.toString().trim();
    if (k == null || k.isEmpty) return false;
  }
  return true;
}

/// Plain-text fields matching the trip detail itinerary row (for PDF / export).
class TripItineraryRowText {
  const TripItineraryRowText({
    required this.category,
    required this.activityTitle,
    required this.price,
    required this.subtitle,
  });

  final String category;
  final String activityTitle;
  final String price;
  final String subtitle;
}

TripItineraryRowText tripItineraryRowText(
  BuildContext context,
  TravelProvider travel,
  Map<String, dynamic> place,
  String dateStr,
  int dayNumber,
) {
  final rawName = travel.placeName(place);
  final stripped =
      AiTripPlanMarkdownParser.stripItineraryMarkdownForDisplay(rawName);
  final priceField = place['itineraryPriceLabel']?.toString().trim();
  final split = AiTripPlanMarkdownParser.splitNameAndPrice(stripped);
  final title = (priceField != null && priceField.isNotEmpty)
      ? stripped
      : split.$1;
  final price = (priceField != null && priceField.isNotEmpty)
      ? priceField
      : split.$2;
  final category = place['itineraryCategory']?.toString().trim() ?? '';
  final schedule =
      tripDetailActivityScheduleLabel(context, travel, place, dayNumber);

  final subParts = <String>[];
  if (dateStr.isNotEmpty) subParts.add(dateStr);
  final pending = context.tr('schedule_time_pending');
  if (schedule.isNotEmpty && schedule != pending) {
    subParts.add(schedule);
  }
  final subtitle = subParts.join(' · ');

  return TripItineraryRowText(
    category: category,
    activityTitle: title.isEmpty ? stripped : title,
    price: price,
    subtitle: subtitle,
  );
}
