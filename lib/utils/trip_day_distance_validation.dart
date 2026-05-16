import 'haversine_km.dart';
import 'trip_place_lat_lng.dart';

/// Maximum straight-line distance (km) between any two places on the same day.
const double maxSameDayPlaceDistanceKm = 85.0;

/// Returns a localization key when any pair on [places] exceeds [maxSameDayPlaceDistanceKm].
/// Pairs without valid coordinates on both sides are skipped (no API calls).
String? sameDayPlaceDistanceErrorKey(List<Map<String, dynamic>> places) {
  if (places.length < 2) return null;

  for (var i = 0; i < places.length; i++) {
    final a = latLngFromTripPlace(places[i]);
    if (a.lat == null ||
        a.lng == null ||
        !latLngValid(a.lat!, a.lng!)) {
      continue;
    }

    for (var j = i + 1; j < places.length; j++) {
      final b = latLngFromTripPlace(places[j]);
      if (b.lat == null ||
          b.lng == null ||
          !latLngValid(b.lat!, b.lng!)) {
        continue;
      }

      final km = haversineKm(a.lat!, a.lng!, b.lat!, b.lng!);
      if (km > maxSameDayPlaceDistanceKm) {
        return 'place_too_far_same_day';
      }
    }
  }

  return null;
}
