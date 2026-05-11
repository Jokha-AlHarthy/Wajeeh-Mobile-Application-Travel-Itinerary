/// Detects user phrases that mean "save this AI plan to Trips History".
bool userMessageLooksLikeSaveTripIntent(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t.contains('save') &&
      (t.contains('plan') ||
          t.contains('itinerary') ||
          t.contains('trip') ||
          t.contains('history'))) {
    return true;
  }
  if (t.contains('add') &&
      (t.contains('history') || t.contains('my trips') || t.contains('trips'))) {
    return true;
  }
  if (t.contains('save itinerary') || t.contains('save this itinerary')) {
    return true;
  }
  return false;
}
