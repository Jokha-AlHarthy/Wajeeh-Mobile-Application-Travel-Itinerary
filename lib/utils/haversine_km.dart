import 'dart:math' as math;

/// Straight-line distance on the WGS84 sphere (no external APIs).
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1 - a)));
  return earthKm * c;
}

/// Compact km value for UI (no unit suffix).
String formatApproxKm(double km) {
  if (km.isNaN || km < 0) return '0';
  if (km >= 100) return km.round().toString();
  if (km >= 10) return km.round().toString();
  final rounded = (km * 10).round() / 10;
  if ((rounded - rounded.round()).abs() < 1e-9) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}
