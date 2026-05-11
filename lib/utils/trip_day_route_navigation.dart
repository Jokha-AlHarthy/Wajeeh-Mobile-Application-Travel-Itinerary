import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../pages/full_trip_route_map_screen.dart';
import '../providers/travel_provider.dart';
import '../services/full_trip_route_place_resolver.dart';

/// Resolves all days and opens one map with every day’s route in its own color.
Future<void> openFullTripRouteMap(
  BuildContext context,
  TravelProvider travel,
  Map<String, dynamic> trip,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(ctx.tr('preparing_route_map'))),
          ],
        ),
      ),
    ),
  );

  var resolution = FullTripRouteResolution(
    pins: [],
    dayPolylines: [],
    skippedCount: 0,
  );
  try {
    resolution = await FullTripRoutePlaceResolver.resolve(
      context: context,
      travel: travel,
      trip: trip,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  if (!context.mounted) return;

  if (resolution.pins.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('map_no_stops_to_show'))),
    );
    return;
  }

  final rawName = trip['tripName']?.toString().trim() ?? '';
  final loc = travel.historyLocationLinesForTrip(trip);
  final cityLine = loc['cities'] ?? '';
  final title = rawName.isNotEmpty
      ? rawName
      : (cityLine.isNotEmpty
          ? cityLine
          : context.tr('full_trip_route_map_title'));

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => FullTripRouteMapScreen(
        title: title,
        pins: resolution.pins,
        dayPolylines: resolution.dayPolylines,
        skippedFromGeocode: resolution.skippedCount,
      ),
    ),
  );
}
