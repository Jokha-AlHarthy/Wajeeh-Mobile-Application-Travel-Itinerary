import 'dart:math' as math;

/// Reads coordinates from a saved trip place map (Google Places v1 + legacy shapes).
({double? lat, double? lng}) latLngFromTripPlace(Map<String, dynamic> place) {
  final loc = place['location'];
  if (loc is Map) {
    final lat = loc['latitude'];
    final lng = loc['longitude'];
    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }
  }

  final geometry = place['geometry'];
  if (geometry is Map) {
    final gLoc = geometry['location'];
    if (gLoc is Map) {
      final lat = gLoc['lat'] ?? gLoc['latitude'];
      final lng = gLoc['lng'] ?? gLoc['longitude'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
    }
  }

  return (lat: null, lng: null);
}

bool latLngValid(double lat, double lng) {
  return lat.isFinite &&
      lng.isFinite &&
      !lat.isNaN &&
      !lng.isNaN &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;
}

double quickDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final p = math.pi / 180;
  final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
  return 2 * r * math.asin(math.sqrt(a));
}
