/// Shared place-category keys for Home filters, Search, and user preferences.
const List<String> placeCategoryFilterKeys = [
  'filter_culture_heritage',
  'filter_transportation',
  'filter_shopping_souvenirs',
  'filter_museum',
  'filter_hotels_stays',
  'filter_food_restaurants',
];

const Set<String> _placeCategoryFilterKeySet = {
  'filter_culture_heritage',
  'filter_transportation',
  'filter_shopping_souvenirs',
  'filter_museum',
  'filter_hotels_stays',
  'filter_food_restaurants',
};

/// Maps legacy interest keys, display labels, and aliases to [placeCategoryFilterKeys].
String? preferenceInterestToFilterKey(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (_placeCategoryFilterKeySet.contains(s)) return s;

  final lower = s.toLowerCase();

  switch (lower) {
    case 'culture & heritage':
    case 'cultural and heritage exploration':
      return 'filter_culture_heritage';
    case 'transportation':
      return 'filter_transportation';
    case 'shopping & souvenirs':
    case 'shopping':
      return 'filter_shopping_souvenirs';
    case 'museum':
      return 'filter_museum';
    case 'hotels & stays':
      return 'filter_hotels_stays';
    case 'food & restaurants':
    case 'trying local food':
      return 'filter_food_restaurants';
  }

  switch (s) {
    case 'interest_cultural_heritage':
      return 'filter_culture_heritage';
    case 'interest_shopping':
      return 'filter_shopping_souvenirs';
    case 'interest_trying_local_food':
      return 'filter_food_restaurants';
    case 'interest_relaxation':
      return 'filter_hotels_stays';
    case 'interest_local_attractions':
      return 'filter_culture_heritage';
    case 'interest_outdoor_adventures':
    case 'interest_leisure':
    case 'interest_visiting_family_friends':
      return null;
    default:
      break;
  }

  if (lower.startsWith('filter_')) {
    final normalized = lower.replaceAll(' ', '_');
    if (_placeCategoryFilterKeySet.contains(normalized)) return normalized;
  }

  return null;
}

/// Normalizes saved preference values to stable filter keys; drops unknown entries.
List<String> normalizePreferenceInterestKeys(Iterable<String> raw) {
  final out = <String>[];
  for (final item in raw) {
    final key = preferenceInterestToFilterKey(item);
    if (key != null && !out.contains(key)) out.add(key);
  }
  return out;
}

bool isKnownPlaceCategoryFilterKey(String key) =>
    _placeCategoryFilterKeySet.contains(key.trim());
