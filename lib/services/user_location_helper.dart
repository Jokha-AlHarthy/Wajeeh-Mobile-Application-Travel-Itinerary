import 'package:geolocator/geolocator.dart';

/// Best-effort device position for approximate distance (no thrown errors).
class UserLocationHelper {
  UserLocationHelper._();

  /// Prefers [getLastKnownPosition] for a quick estimate, then a single
  /// low-accuracy fix. Null when unavailable, denied, or services are off.
  static Future<Position?> tryGetEstimatedPosition({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      return last;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: timeLimit,
      );
    } catch (_) {
      return null;
    }
  }
}
