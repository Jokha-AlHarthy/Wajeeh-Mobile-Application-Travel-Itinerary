/// Helpers for saved trip maps from [TravelProvider] / prefs.
extension SavedTripMapX on Map<String, dynamic> {
  /// Trip end date is today or in the future (or missing dates → treat as ongoing).
  bool get isOngoingTrip {
    final endStr = this['endDate']?.toString();
    if (endStr == null || endStr.isEmpty) return true;
    final end = DateTime.tryParse(endStr);
    if (end == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return !endOnly.isBefore(today);
  }

  bool get isCompletedTrip => !isOngoingTrip;

  DateTime? get tripStartDate {
    final s = this['startDate']?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  DateTime? get tripEndDate {
    final s = this['endDate']?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

List<Map<String, dynamic>> parsedDaysFromTrip(Map<String, dynamic> trip) {
  final daysRaw = trip['days'];
  if (daysRaw is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final raw in daysRaw) {
    if (raw is! Map) continue;
    out.add(Map<String, dynamic>.from(raw));
  }
  return out;
}

/// Number of itinerary days from the stored [days] list, or inclusive calendar span.
int tripDaySelectorCount(Map<String, dynamic> trip) {
  final parsed = parsedDaysFromTrip(trip);
  if (parsed.isNotEmpty) return parsed.length;
  final start = trip.tripStartDate;
  final end = trip.tripEndDate;
  if (start != null && end != null) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    final span = b.difference(a).inDays + 1;
    return span < 1 ? 1 : span;
  }
  return 1;
}

/// Default highlighted day for ongoing trips: calendar "today" within range.
int defaultTripDayListIndex(Map<String, dynamic> trip) {
  if (!trip.isOngoingTrip) return 0;
  final n = tripDaySelectorCount(trip);
  if (n <= 0) return 0;
  final start = trip.tripStartDate;
  final end = trip.tripEndDate;
  if (start == null || end == null) return 0;
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final startOnly = DateTime(start.year, start.month, start.day);
  final endOnly = DateTime(end.year, end.month, end.day);
  if (today.isBefore(startOnly)) return 0;
  if (today.isAfter(endOnly)) return n - 1;
  final idx = today.difference(startOnly).inDays;
  return idx.clamp(0, n - 1);
}
