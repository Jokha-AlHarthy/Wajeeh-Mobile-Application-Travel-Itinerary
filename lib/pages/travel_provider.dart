import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/google_keys.dart';
import '../services/places_service.dart';
import '../services/price_extraction_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class TravelProvider extends ChangeNotifier {
  final _api = PlacesService(GoogleKeys.placesKey);

  bool loading = false;
  String? error;
  int? selectedDayForSuggestion;
  List<Map<String, dynamic>> suggestedNearbyPlaces = [];

  List<dynamic> homePlaces = [];

  /// True when the last [loadHome] applied interest-based filtering.
  bool lastHomeLoadFilteredByInterests = false;
  List<dynamic> searchPlaces = [];
  List<String> searchHistory = [];
  List<Map<String, dynamic>> recentlyViewed = [];
  List<Map<String, dynamic>> favoritePlaces = [];

  static const _favoritesPrefsKey = 'favorite_places_v1';
  static const _savedTripsPrefsKey = 'saved_trips_v1';
  static const _tripDraftPrefsKey = 'trip_plan_draft_v1';
  static const _homeCachePrefsKey = 'home_places_cache_v1';
  static const Duration _homeCacheTtl = Duration(hours: 24);

  String? _lastLoadedHomeCity;

  /// Logged-in users: `users/{uid}/travelStorage/v1`
  static const _firestoreTravelCollection = 'travelStorage';
  static const _firestoreTravelDocId = 'v1';

  /// Firebase uid, or `'guest'` when logged out — drives SharedPreferences keys.
  String _storageScope = 'guest';
  bool _storageReady = false;

  String _scopedPrefsKey(String base) => '${base}_$_storageScope';

  bool get _isGuestScope => _storageScope == 'guest';

  DocumentReference<Map<String, dynamic>>? _travelFirestoreRef() {
    if (_isGuestScope) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_storageScope)
        .collection(_firestoreTravelCollection)
        .doc(_firestoreTravelDocId);
  }

  TravelProvider();

  /// Call when auth user changes so favorites, saved itineraries, search/recent
  /// lists, and trip draft load from that user's storage.
  Future<void> setStorageUserId(String? uid) async {
    final next = (uid != null && uid.isNotEmpty) ? uid : 'guest';
    if (_storageReady && next == _storageScope) return;

    if (_storageReady) {
      if (!_isGuestScope) {
        await _pushFullTravelToFirestore();
      } else {
        await _persistTripPlanDraft();
      }
    }

    _storageScope = next;
    _storageReady = true;

    favoritePlaces = [];
    savedTrips = [];
    searchHistory = [];
    recentlyViewed = [];
    tripPlanStart = null;
    tripPlanEnd = null;
    tripPlanItineraryActive = false;
    tripPlanPlacesByDay = {};
    _editingSavedTripIndex = null;

    await _reloadTravelStorageForScope();
    notifyListeners();
  }

  Future<void> _reloadTravelStorageForScope() async {
    if (_isGuestScope) {
      await _loadFavoritesFromPrefs();
      await _loadSavedTripsFromPrefs();
      await _loadTripPlanDraftFromPrefs();
      return;
    }
    await _loadTravelFromFirestore();
  }

  void _schedulePersistTripDraft() {
    Future.microtask(() => _persistTripPlanDraft());
  }

  String placeFavoriteId(Map<String, dynamic> place) {
    return place["id"]?.toString() ?? placeName(place).toLowerCase().trim();
  }

  bool isFavorite(Map<String, dynamic> place) {
    final id = placeFavoriteId(place);
    return favoritePlaces.any((p) => placeFavoriteId(p) == id);
  }

  void toggleFavorite(Map<String, dynamic> place) {
    final id = placeFavoriteId(place);
    final idx = favoritePlaces.indexWhere((p) => placeFavoriteId(p) == id);
    if (idx >= 0) {
      favoritePlaces.removeAt(idx);
    } else {
      favoritePlaces.insert(0, Map<String, dynamic>.from(place));
    }
    notifyListeners();
    _persistFavorites();
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  Future<void> _loadFavoritesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoped = _scopedPrefsKey(_favoritesPrefsKey);
      var raw = prefs.getString(scoped);
      if (raw == null || raw.isEmpty) {
        final legacy = prefs.getString(_favoritesPrefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          await prefs.setString(scoped, legacy);
          await prefs.remove(_favoritesPrefsKey);
          raw = legacy;
        }
      }
      if (raw == null || raw.isEmpty) {
        favoritePlaces = [];
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        favoritePlaces = [];
        return;
      }
      favoritePlaces = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      favoritePlaces = [];
    }
  }

  Future<void> _mirrorTravelToPrefsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scopedPrefsKey(_favoritesPrefsKey),
        jsonEncode(favoritePlaces),
      );
      await prefs.setString(
        _scopedPrefsKey(_savedTripsPrefsKey),
        jsonEncode(savedTrips),
      );
      await _persistTripPlanDraftPrefsOnly();
    } catch (_) {}
  }

  void _applyTripPlanDraftFromMap(Map<String, dynamic> m) {
    final startStr = m['start']?.toString();
    final endStr = m['end']?.toString();
    tripPlanStart = startStr != null && startStr.isNotEmpty
        ? DateTime.tryParse(startStr)
        : null;
    tripPlanEnd = endStr != null && endStr.isNotEmpty
        ? DateTime.tryParse(endStr)
        : null;
    tripPlanItineraryActive = m['itineraryActive'] == true;

    tripPlanPlacesByDay = {};
    final byDay = m['placesByDay'];
    if (byDay is Map) {
      for (final e in byDay.entries) {
        final k = int.tryParse(e.key.toString());
        if (k == null || k < 1) continue;
        final list = e.value;
        if (list is! List) continue;
        tripPlanPlacesByDay[k] = list
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
      }
    }
  }

  void _clearTripPlanDraftState() {
    tripPlanStart = null;
    tripPlanEnd = null;
    tripPlanItineraryActive = false;
    tripPlanPlacesByDay = {};
  }

  void _applyTravelDataFromFirestore(Map<String, dynamic> data) {
    favoritePlaces = _asMapList(data['favoritePlaces']);
    savedTrips = _asMapList(data['savedTrips']);
    final draft = data['tripPlanDraft'];
    if (draft is Map<String, dynamic>) {
      _applyTripPlanDraftFromMap(draft);
    } else if (draft is Map) {
      _applyTripPlanDraftFromMap(Map<String, dynamic>.from(draft));
    } else {
      _clearTripPlanDraftState();
    }
  }

  Map<String, dynamic>? _tripPlanDraftMapForFirestore() {
    if (tripPlanStart == null &&
        tripPlanEnd == null &&
        !tripPlanItineraryActive &&
        tripPlanPlacesByDay.isEmpty) {
      return null;
    }
    final placesJson = <String, dynamic>{};
    for (final e in tripPlanPlacesByDay.entries) {
      placesJson[e.key.toString()] = e.value;
    }
    return {
      'start': tripPlanStart?.toIso8601String(),
      'end': tripPlanEnd?.toIso8601String(),
      'itineraryActive': tripPlanItineraryActive,
      'placesByDay': placesJson,
    };
  }

  Future<void> _pushFullTravelToFirestore() async {
    final ref = _travelFirestoreRef();
    if (ref == null) return;
    try {
      final payload = <String, dynamic>{
        'favoritePlaces': favoritePlaces,
        'savedTrips': savedTrips,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final draft = _tripPlanDraftMapForFirestore();
      if (draft == null) {
        payload['tripPlanDraft'] = FieldValue.delete();
      } else {
        payload['tripPlanDraft'] = draft;
      }
      await ref.set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('TravelProvider Firestore push: $e');
    }
  }

  Future<void> _loadTravelFromFirestore() async {
    final ref = _travelFirestoreRef();
    if (ref == null) return;
    try {
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) {
        _applyTravelDataFromFirestore(snap.data()!);
        await _mirrorTravelToPrefsCache();
        return;
      }
      await _loadFavoritesFromPrefs();
      await _loadSavedTripsFromPrefs();
      await _loadTripPlanDraftFromPrefs();
      await _pushFullTravelToFirestore();
    } catch (e) {
      debugPrint('TravelProvider Firestore load: $e');
      await _loadFavoritesFromPrefs();
      await _loadSavedTripsFromPrefs();
      await _loadTripPlanDraftFromPrefs();
    }
  }

  Future<void> _persistFavoritesPrefsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scopedPrefsKey(_favoritesPrefsKey),
        jsonEncode(favoritePlaces),
      );
    } catch (_) {}
  }

  Future<void> _persistFavorites() async {
    if (_isGuestScope) {
      await _persistFavoritesPrefsOnly();
      return;
    }
    final ref = _travelFirestoreRef();
    if (ref == null) {
      await _persistFavoritesPrefsOnly();
      return;
    }
    try {
      await ref.set({
        'favoritePlaces': favoritePlaces,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _persistFavoritesPrefsOnly();
    } catch (e) {
      debugPrint('TravelProvider Firestore save favorites: $e');
      await _persistFavoritesPrefsOnly();
    }
  }

  // --- Trip plan (itinerary: places per day, 1-based day index) ---

  DateTime? tripPlanStart;
  DateTime? tripPlanEnd;
  bool tripPlanItineraryActive = false;
  Map<int, List<Map<String, dynamic>>> tripPlanPlacesByDay = {};

  /// When non-null, [saveCurrentItinerary] replaces this index instead of inserting.
  int? _editingSavedTripIndex;

  int get tripPlanDayCount {
    if (tripPlanStart == null || tripPlanEnd == null) return 0;
    return tripPlanEnd!.difference(tripPlanStart!).inDays + 1;
  }

  /// Each calendar day in the plan must have at least one scheduled place.
  bool get isTripPlanItineraryEveryDayFilled {
    final n = tripPlanDayCount;
    if (n <= 0) return false;
    for (var d = 1; d <= n; d++) {
      final list = tripPlanPlacesByDay[d];
      if (list == null || list.isEmpty) return false;
    }
    return true;
  }

  static bool _sameCalendarDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Sets trip date range. Clears scheduled places if the range changes.
  void applyTripPlanDates(DateTime start, DateTime end) {
    final rangeChanged =
        !_sameCalendarDate(tripPlanStart, start) ||
        !_sameCalendarDate(tripPlanEnd, end);
    tripPlanStart = start;
    tripPlanEnd = end;
    if (rangeChanged) {
      tripPlanPlacesByDay.clear();
    }
    final n = tripPlanDayCount;
    tripPlanPlacesByDay.removeWhere((k, _) => k > n);
    notifyListeners();
    _schedulePersistTripDraft();
  }

  void activateTripPlanItinerary() {
    tripPlanItineraryActive = true;
    notifyListeners();
    _schedulePersistTripDraft();
  }

  void deactivateTripPlanItinerary() {
    tripPlanItineraryActive = false;
    tripPlanPlacesByDay.clear();
    notifyListeners();
    _schedulePersistTripDraft();
  }

  List<Map<String, dynamic>> placesForTripDay(int dayNumber) {
    final list = tripPlanPlacesByDay[dayNumber];
    if (list == null) return [];
    return List<Map<String, dynamic>>.from(list);
  }

  bool addPlaceToTripDay(int dayNumber, Map<String, dynamic> place) {
    if (dayNumber < 1 || dayNumber > tripPlanDayCount) return false;

    final id = placeFavoriteId(place);
    final list = tripPlanPlacesByDay.putIfAbsent(
      dayNumber,
      () => <Map<String, dynamic>>[],
    );
    if (list.length >= 5) {
      error = "max_places_per_day";
      notifyListeners();
      return false;
    }

    /// 🛑 1. منع التكرار
    final exists = list.any((p) => placeFavoriteId(p) == id);
    if (exists) {
      error = "place_already_added_same_day";
      notifyListeners();
      return false;
    }

    /// 🛑 2. منع اختلاف المدن
    final newCity = _extractCity(placeAddress(place));

    if (list.isNotEmpty) {
      final existingCity = _extractCity(placeAddress(list.first));

      if (newCity.isNotEmpty &&
          existingCity.isNotEmpty &&
          newCity.toLowerCase() != existingCity.toLowerCase()) {
        error = "different_cities_same_day";
        notifyListeners();
        return false;
      }
    }

    /// 🛑 3. منع الأماكن البعيدة
    if (list.isNotEmpty) {
      final lastPlace = list.last;

      final lastCoords = _extractLatLng(lastPlace);
      final newCoords = _extractLatLng(place);

      if (lastCoords.lat != null &&
          lastCoords.lng != null &&
          newCoords.lat != null &&
          newCoords.lng != null) {
        final distance = _calculateDistanceKm(
          lastCoords.lat!,
          lastCoords.lng!,
          newCoords.lat!,
          newCoords.lng!,
        );


        if (distance > 50) {
          selectedDayForSuggestion = dayNumber;
          error = "places_too_far_suggestion";

          final city = _extractCity(placeAddress(place));
          final types = ((place["types"] as List?) ?? [])
              .map((e) => e.toString().toLowerCase())
              .toList();

          _loadNearbySuggestions(city, types);

          notifyListeners();
          return false;
        }
      }
    }

    /// ✅ إضافة المكان
    list.add(Map<String, dynamic>.from(place));
    _sortPlacesByDistance(list);

    notifyListeners();
    _schedulePersistTripDraft();

    return true;
  }

  void removePlaceFromTripDay(int dayNumber, int index) {
    final list = tripPlanPlacesByDay[dayNumber];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      tripPlanPlacesByDay.remove(dayNumber);
    }
    notifyListeners();
    _schedulePersistTripDraft();
  }

  void movePlaceInTripDay(int dayNumber, int oldIndex, int newIndex) {
    final list = tripPlanPlacesByDay[dayNumber];
    if (list == null || list.isEmpty) return;

    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex >= list.length) return;
    if (oldIndex == newIndex) return;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    notifyListeners();
    _schedulePersistTripDraft();
  }

  /// Call when the user edits dates on Trip Plan (pickers). Deactivates itinerary until they tap Create again.
  void updateTripPlanDraftDates(DateTime? start, DateTime? end) {
    tripPlanItineraryActive = false;
    if (start != null && end != null) {
      applyTripPlanDates(start, end);
    } else {
      tripPlanStart = start;
      tripPlanEnd = end;
      tripPlanPlacesByDay.clear();
      notifyListeners();
      _schedulePersistTripDraft();
    }
  }

  static const double _gccLowLat = 16.0;
  static const double _gccLowLng = 34.0;
  static const double _gccHighLat = 33.5;
  static const double _gccHighLng = 60.5;

  bool _insideGccBox(Map<String, dynamic> place) {
    final loc = place["location"];
    if (loc is! Map) return true;

    final latRaw = loc["latitude"];
    final lngRaw = loc["longitude"];
    if (latRaw is! num || lngRaw is! num) return true;

    final lat = latRaw.toDouble();
    final lng = lngRaw.toDouble();

    return lat >= _gccLowLat &&
        lat <= _gccHighLat &&
        lng >= _gccLowLng &&
        lng <= _gccHighLng;
  }

  List<dynamic> _onlyGcc(List<dynamic> items) {
    final out = <dynamic>[];
    for (final it in items) {
      if (it is Map<String, dynamic> && _insideGccBox(it)) {
        out.add(it);
      }
    }
    return out;
  }
  // --- Saved itinerary history ---

  List<Map<String, dynamic>> savedTrips = [];

  Future<void> _loadSavedTripsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoped = _scopedPrefsKey(_savedTripsPrefsKey);
      var raw = prefs.getString(scoped);
      if (raw == null || raw.isEmpty) {
        final legacy = prefs.getString(_savedTripsPrefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          await prefs.setString(scoped, legacy);
          await prefs.remove(_savedTripsPrefsKey);
          raw = legacy;
        }
      }
      if (raw == null || raw.isEmpty) {
        savedTrips = [];
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        savedTrips = [];
        return;
      }

      savedTrips = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      savedTrips = [];
    }
  }

  Future<void> _persistSavedTripsPrefsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scopedPrefsKey(_savedTripsPrefsKey),
        jsonEncode(savedTrips),
      );
    } catch (_) {}
  }

  Future<void> _persistSavedTrips() async {
    if (_isGuestScope) {
      await _persistSavedTripsPrefsOnly();
      return;
    }
    final ref = _travelFirestoreRef();
    if (ref == null) {
      await _persistSavedTripsPrefsOnly();
      return;
    }
    try {
      await ref.set({
        'savedTrips': savedTrips,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _persistSavedTripsPrefsOnly();
    } catch (e) {
      debugPrint('TravelProvider Firestore save trips: $e');
      await _persistSavedTripsPrefsOnly();
    }
  }

  Future<void> _loadTripPlanDraftFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedPrefsKey(_tripDraftPrefsKey));
      if (raw == null || raw.isEmpty) {
        _clearTripPlanDraftState();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _applyTripPlanDraftFromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      _clearTripPlanDraftState();
    }
  }

  Future<void> _persistTripPlanDraftPrefsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _scopedPrefsKey(_tripDraftPrefsKey);
      if (tripPlanStart == null &&
          tripPlanEnd == null &&
          !tripPlanItineraryActive &&
          tripPlanPlacesByDay.isEmpty) {
        await prefs.remove(key);
        return;
      }
      final placesJson = <String, dynamic>{};
      for (final e in tripPlanPlacesByDay.entries) {
        placesJson[e.key.toString()] = e.value;
      }
      await prefs.setString(
        key,
        jsonEncode({
          'start': tripPlanStart?.toIso8601String(),
          'end': tripPlanEnd?.toIso8601String(),
          'itineraryActive': tripPlanItineraryActive,
          'placesByDay': placesJson,
        }),
      );
    } catch (_) {}
  }

  Future<void> _persistTripPlanDraft() async {
    if (_isGuestScope) {
      await _persistTripPlanDraftPrefsOnly();
      return;
    }
    final ref = _travelFirestoreRef();
    if (ref == null) {
      await _persistTripPlanDraftPrefsOnly();
      return;
    }
    try {
      final draft = _tripPlanDraftMapForFirestore();
      if (draft == null) {
        await ref.set({
          'tripPlanDraft': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await ref.set({
          'tripPlanDraft': draft,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _persistTripPlanDraftPrefsOnly();
    } catch (e) {
      debugPrint('TravelProvider Firestore save trip draft: $e');
      await _persistTripPlanDraftPrefsOnly();
    }
  }

  bool _isCompletedTrip(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.isBefore(today);
  }

  String _historyDateText(DateTime date) {
    return DateFormat('EEE, d MMM y').format(date);
  }

  String _buildSavedTripImage() {
    for (final entry in tripPlanPlacesByDay.entries) {
      if (entry.value.isNotEmpty) {
        final firstPlace = entry.value.first;
        final photo = firstPhotoUrl(firstPlace);
        if (photo != null && photo.isNotEmpty) {
          return photo;
        }
      }
    }
    return '';
  }

  int _savedTripPersonsCount() {
    int total = 0;
    for (final entry in tripPlanPlacesByDay.entries) {
      total += entry.value.length;
    }
    return total == 0 ? 1 : total;
  }

  String _savedTripPrice() {
    double total = 0;
    for (final entry in tripPlanPlacesByDay.entries) {
      for (final place in entry.value) {
        total += placeSortPriceValue(place);
      }
    }
    if (total <= 0) return 'OMR 0';
    return 'OMR ${total.toStringAsFixed(0)}';
  }

  List<Map<String, dynamic>> _buildSavedTripDays() {
    final days = <Map<String, dynamic>>[];
    if (tripPlanStart == null || tripPlanEnd == null) return days;

    final totalDays = tripPlanDayCount;

    for (int i = 0; i < totalDays; i++) {
      final dayNumber = i + 1;
      final date = tripPlanStart!.add(Duration(days: i));
      final places = List<Map<String, dynamic>>.from(
        tripPlanPlacesByDay[dayNumber] ?? [],
      );

      days.add({
        "dayNumber": dayNumber,
        "date": DateFormat('EEEE, MMMM d, y').format(date),
        "places": places,
      });
    }

    return days;
  }

  void clearEditingSavedTripTarget() {
    _editingSavedTripIndex = null;
  }

  /// Loads a history entry into the trip planner for editing. [listIndex] targets
  /// that row on save (replace instead of insert).
  void loadSavedTripIntoPlanner(Map<String, dynamic> trip, {int? listIndex}) {
    final startStr = trip['startDate']?.toString();
    final endStr = trip['endDate']?.toString();
    if (startStr == null || endStr == null) return;
    final start = DateTime.tryParse(startStr);
    final end = DateTime.tryParse(endStr);
    if (start == null || end == null) return;

    tripPlanStart = DateTime(start.year, start.month, start.day);
    tripPlanEnd = DateTime(end.year, end.month, end.day);
    tripPlanPlacesByDay = {};
    final days = trip['days'];
    if (days is List) {
      for (final raw in days) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final dn = m['dayNumber'];
        final dayNum = dn is int ? dn : int.tryParse(dn.toString());
        if (dayNum == null || dayNum < 1) continue;
        final placesRaw = m['places'];
        if (placesRaw is! List) continue;
        tripPlanPlacesByDay[dayNum] = placesRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    tripPlanItineraryActive = true;
    _editingSavedTripIndex = listIndex;
    notifyListeners();
    _schedulePersistTripDraft();
  }

  Future<void> saveCurrentItinerary() async {
    if (tripPlanStart == null || tripPlanEnd == null) return;
    if (!isTripPlanItineraryEveryDayFilled) return;

    final image = _buildSavedTripImage();
    final completed = _isCompletedTrip(tripPlanEnd!);

    final trip = <String, dynamic>{
      "statusKey": completed ? "completed" : "on_going",
      "title": _buildSavedTripCitiesLine(),
      "country": _buildSavedTripCountriesLine(),
      "rating": "4.5",
      "persons": _savedTripPersonsCount(),
      "dateText": _historyDateText(tripPlanStart!),
      "price": _savedTripPrice(),
      "image": image,
      "startDate": tripPlanStart!.toIso8601String(),
      "endDate": tripPlanEnd!.toIso8601String(),
      "days": _buildSavedTripDays(),
    };

    if (_editingSavedTripIndex != null &&
        _editingSavedTripIndex! >= 0 &&
        _editingSavedTripIndex! < savedTrips.length) {
      final existing = savedTrips[_editingSavedTripIndex!];
      trip['id'] =
          existing['id'] ??
          '${trip['startDate']}_${trip['endDate']}_${existing['title']}';
      savedTrips[_editingSavedTripIndex!] = trip;
      _editingSavedTripIndex = null;
    } else {
      trip['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      savedTrips.insert(0, trip);
    }

    await _persistSavedTrips();
    _clearTripPlanDraftState();
    await _persistTripPlanDraft();
    notifyListeners();
  }

  Future<void> loadHome(
    String city, {
    List<String> userInterestKeys = const [],
    bool forceRefresh = false,
  }) async {
    final cityClean = city.trim().isEmpty ? "Muscat" : city.trim();

    if (!forceRefresh &&
        _lastLoadedHomeCity == cityClean &&
        homePlaces.isNotEmpty &&
        userInterestKeys.isEmpty) {
      return;
    }

    if (!forceRefresh && userInterestKeys.isEmpty) {
      final cached = await _readHomeCache(cityClean);
      if (cached != null) {
        homePlaces = cached;
        _lastLoadedHomeCity = cityClean;
        lastHomeLoadFilteredByInterests = false;
        notifyListeners();
        return;
      }
    }

    loading = true;
    error = null;
    lastHomeLoadFilteredByInterests = false;
    notifyListeners();

    try {
      final Map<String, Map<String, dynamic>> merged = {};

      final queries = [
        "top tourist attractions hotels restaurants in $cityClean",
      ];

      for (final query in queries) {
        final results = _onlyGcc(await _api.searchText(query));
        for (final item in results) {
          if (item is Map<String, dynamic>) {
            final id =
                item["id"]?.toString() ??
                item["name"]?.toString() ??
                item["formattedAddress"]?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString();
            merged[id] = item;
          }
        }
      }

      var list = merged.values.toList();

      if (userInterestKeys.isNotEmpty) {
        lastHomeLoadFilteredByInterests = true;
        list = list
            .whereType<Map<String, dynamic>>()
            .where(
              (item) =>
                  userInterestKeys.any((key) => _matchesInterestKey(item, key)),
            )
            .toList();
      }

      homePlaces = list;

      homePlaces.sort((a, b) {
        final aRating = ((a["rating"] ?? 0) as num).toDouble();
        final bRating = ((b["rating"] ?? 0) as num).toDouble();
        return bRating.compareTo(aRating);
      });

      _lastLoadedHomeCity = cityClean;
      if (userInterestKeys.isEmpty) {
        await _writeHomeCache(cityClean, homePlaces);
      }
    } catch (e) {
      error = e.toString();
      homePlaces = [];
    }

    loading = false;
    notifyListeners();
  }

  Future<List<dynamic>?> _readHomeCache(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_homeCachePrefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final cachedCity = decoded['city']?.toString();
      final tsMs = decoded['ts'];
      final items = decoded['items'];
      if (cachedCity == null || tsMs is! int || items is! List) return null;
      if (cachedCity.toLowerCase() != city.toLowerCase()) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );
      if (age > _homeCacheTtl) return null;

      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeHomeCache(String city, List<dynamic> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _homeCachePrefsKey,
        jsonEncode({
          'city': city,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'items': items,
        }),
      );
    } catch (_) {}
  }

  /// Maps My Preference interest codes to Google Places type strings.
  bool _matchesInterestKey(Map<String, dynamic> place, String interestKey) {
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    bool hasAny(List<String> needles) =>
        needles.any((n) => types.any((t) => t.contains(n)));

    switch (interestKey) {
      case 'interest_cultural_heritage':
        return hasAny([
          'museum',
          'mosque',
          'art_gallery',
          'church',
          'hindu_temple',
          'synagogue',
          'historical',
          'heritage',
          'landmark',
          'tourist_attraction',
          'cultural',
        ]);
      case 'interest_local_attractions':
        return hasAny([
          'tourist_attraction',
          'point_of_interest',
          'amusement_park',
          'aquarium',
          'zoo',
          'stadium',
          'movie_theater',
          'observation_deck',
        ]);
      case 'interest_shopping':
        return hasAny([
          'shopping_mall',
          'department_store',
          'clothing_store',
          'shoe_store',
          'jewelry_store',
          'store',
          'market',
          'shopping',
        ]);
      case 'interest_outdoor_adventures':
        return hasAny([
          'park',
          'campground',
          'rv_park',
          'natural_feature',
          'hiking_area',
          'marina',
          'beach',
          'national_park',
          'adventure',
        ]);
      case 'interest_trying_local_food':
        return hasAny([
          'restaurant',
          'food',
          'cafe',
          'meal',
          'bakery',
          'bar',
          'meal_delivery',
          'fine_dining',
        ]);
      case 'interest_relaxation':
        return hasAny([
          'spa',
          'beauty_salon',
          'yoga',
          'massage',
          'lodging',
          'resort',
          'hotel',
          'wellness',
        ]);
      case 'interest_visiting_family_friends':
        return hasAny([
          'restaurant',
          'cafe',
          'food',
          'park',
          'lodging',
          'tourist_attraction',
          'shopping_mall',
        ]);
      case 'interest_leisure':
        return hasAny([
          'movie_theater',
          'night_club',
          'bowling_alley',
          'casino',
          'amusement',
          'tourist_attraction',
          'stadium',
          'event',
        ]);
      default:
        return false;
    }
  }

  Future<void> search(String query) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final q = query.trim();
      if (q.isEmpty) {
        searchPlaces = [];
      } else {
        final results = await _api.searchText(q);
        searchPlaces = _onlyGcc(results);
        addSearchHistory(q);
      }
    } catch (e) {
      error = e.toString();
      searchPlaces = [];
    }

    loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getDetails(String placeId) {
    return _api.details(placeId);
  }

  void addSearchHistory(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    searchHistory.removeWhere(
      (item) => item.toLowerCase() == text.toLowerCase(),
    );
    searchHistory.insert(0, text);

    if (searchHistory.length > 8) {
      searchHistory = searchHistory.take(8).toList();
    }

    notifyListeners();
  }

  void addRecentlyViewed(Map<String, dynamic> place) {
    final currentId = place["id"]?.toString() ?? placeName(place).toLowerCase();

    recentlyViewed.removeWhere((item) {
      final itemId = item["id"]?.toString() ?? placeName(item).toLowerCase();
      return itemId == currentId;
    });

    recentlyViewed.insert(0, Map<String, dynamic>.from(place));

    if (recentlyViewed.length > 10) {
      recentlyViewed = recentlyViewed.take(10).toList();
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> filteredPlaces({
    required String query,
    required List<String> filters,
    required double maxPrice,
    String? priceSortBy,
    String? ratingSortBy,
  }) {
    final source = searchPlaces.isNotEmpty ? searchPlaces : homePlaces;

    final list = source
        .where((item) {
          if (item is! Map<String, dynamic>) return false;

          final name = placeName(item).toLowerCase();
          final address = placeAddress(item).toLowerCase();
          final q = query.trim().toLowerCase();

          final matchesQuery =
              q.isEmpty || name.contains(q) || address.contains(q);

          final matchesFilter =
              filters.isEmpty || filters.every((f) => _matchesCategory(item, f));

          final matchesPrice = _mappedPrice(item) <= maxPrice;

          return matchesQuery && matchesFilter && matchesPrice;
        })
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();

    list.sort((a, b) {
      if (ratingSortBy != null) {
        final ra = (a["rating"] as num?)?.toDouble() ?? 0.0;
        final rb = (b["rating"] as num?)?.toDouble() ?? 0.0;
        final ratingCompare = ratingSortBy == 'rating_asc'
            ? ra.compareTo(rb)
            : rb.compareTo(ra);
        if (ratingCompare != 0) return ratingCompare;
      }

      if (priceSortBy != null) {
        final pa = placeSortPriceValue(a);
        final pb = placeSortPriceValue(b);
        final priceCompare = priceSortBy == 'price_asc'
            ? pa.compareTo(pb)
            : pb.compareTo(pa);
        if (priceCompare != 0) return priceCompare;
      }

      return 0;
    });

    return list;
  }

  bool _matchesCategory(Map<String, dynamic> place, String filter) {
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    switch (filter) {
      case "Hotels & Stays":
      case "filter_hotels_stays":
        return types.any(
          (t) =>
              t.contains("hotel") ||
              t.contains("lodging") ||
              t.contains("resort") ||
              t.contains("guest_house"),
        );
      case "Food & Restaurants":
      case "filter_food_restaurants":
        return types.any(
          (t) =>
              t.contains("restaurant") ||
              t.contains("food") ||
              t.contains("cafe") ||
              t.contains("meal"),
        );
      case "Transportation":
      case "filter_transportation":
        return types.any(
          (t) =>
              t.contains("airport") ||
              t.contains("bus_station") ||
              t.contains("train_station") ||
              t.contains("subway_station") ||
              t.contains("taxi_stand") ||
              t.contains("car_rental") ||
              t.contains("parking") ||
              t.contains("bus") ||
              t.contains("train") ||
              t.contains("taxi") ||
              t.contains("station") ||
              t.contains("transit"),
        );
      case "Culture & Heritage":
      case "filter_culture_heritage":
        return types.any(
          (t) =>
              t.contains("museum") ||
              t.contains("mosque") ||
              t.contains("art_gallery") ||
              t.contains("landmark") ||
              t.contains("tourist_attraction") ||
              t.contains("cultural"),
        );
      case "Shopping & Souvenirs":
      case "filter_shopping_souvenirs":
        return types.any(
          (t) =>
              t.contains("shopping_mall") ||
              t.contains("store") ||
              t.contains("market") ||
              t.contains("shop") ||
              t.contains("souvenir"),
        );
      case "Museum":
      case "museum":
      case "filter_museum":
        return types.any((t) => t.contains("museum"));

      default:
        // If admin adds a Google Places "type" (e.g. `travel_agency`, `car_rental`)
        // we can filter without adding new hardcoded cases.
        //
        // Otherwise, keep legacy behavior (unknown filters don't restrict results).
        final raw = filter.trim().toLowerCase();
        final normalized = raw.replaceAll(' ', '_');
        final looksLikePlacesType =
            RegExp(r'^[a-z_]+$').hasMatch(normalized) &&
            !normalized.startsWith('filter_') &&
            normalized.length >= 3;
        if (looksLikePlacesType) {
          if (types.any((t) => t.contains(normalized))) return true;
          // Many user-friendly filters (e.g. "Beach") may not appear as a type in
          // the API response; allow matching by keywords in name/address as well.
          final name = placeName(place).toLowerCase();
          final addr = placeAddress(place).toLowerCase();
          return name.contains(raw) || addr.contains(raw);
        }
        return false;
    }
  }

  double _mappedPrice(Map<String, dynamic> place) {
    final price = place["priceLevel"]?.toString() ?? "";

    switch (price) {
      case "PRICE_LEVEL_FREE":
        return 0;
      case "PRICE_LEVEL_INEXPENSIVE":
        return 50;
      case "PRICE_LEVEL_MODERATE":
        return 100;
      case "PRICE_LEVEL_EXPENSIVE":
        return 150;
      case "PRICE_LEVEL_VERY_EXPENSIVE":
        return 200;
      default:
        return 100;
    }
  }

  String placeName(Map<String, dynamic> place) {
    final dn = place["displayName"];
    if (dn is Map && dn["text"] != null) {
      return dn["text"].toString();
    }
    return place["displayName"]?.toString() ?? "Unknown";
  }

  String placeAddress(Map<String, dynamic> place) {
    return place["formattedAddress"]?.toString() ?? "";
  }

  String placeDescription(Map<String, dynamic> place) {
    final editorial = place["editorialSummary"];
    if (editorial is Map && editorial["text"] != null) {
      final text = editorial["text"].toString().trim();
      if (text.isNotEmpty) return text;
    }
    return placeSummaryDescription(place);
  }

  String placeSummaryDescription(Map<String, dynamic> place) {
    final name = placeName(place);
    final address = placeAddress(place);
    final rating = place["rating"];
    final reviews = place["userRatingCount"];
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    final city = _extractCity(address);
    final category = _categoryFromTypes(types);

    final parts = <String>[];
    parts.add("$name is a $category");
    if (city.isNotEmpty) parts.add(" in $city");
    parts.add(".");
    if (rating is num && rating > 0) {
      final r = rating.toDouble();
      final rev = reviews is num ? reviews.toInt() : 0;
      if (rev > 0) {
        parts.add(" It has a ${r.toStringAsFixed(1)} rating from $rev reviews");
      } else {
        parts.add(" It has a ${r.toStringAsFixed(1)} rating");
      }
      parts.add(".");
    }
    if (address.isNotEmpty) {
      parts.add(" Located at $address.");
    }

    return parts.join();
  }

  String _extractCity(String address) {
    if (address.isEmpty) return "";
    final parts = address.split(",").map((s) => s.trim()).toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return parts.isNotEmpty ? parts.last : "";
  }

  /// Last segment of a comma-separated formatted address (usually country).
  String _extractCountryFromAddress(String address) {
    if (address.isEmpty) return "";
    final parts = address
        .split(",")
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length < 2) return "";
    return parts.last;
  }

  /// Unique cities from all places on the itinerary (stable order).
  String _buildSavedTripCitiesLine() {
    final seen = <String>{};
    final ordered = <String>[];
    for (final entry in tripPlanPlacesByDay.entries) {
      for (final place in entry.value) {
        final city = _extractCity(placeAddress(place));
        if (city.isEmpty) continue;
        final key = city.toLowerCase();
        if (seen.add(key)) ordered.add(city);
      }
    }
    if (ordered.isEmpty) return 'Trip Plan';
    return ordered.join(', ');
  }

  /// Unique countries from all places on the itinerary (stable order).
  String _buildSavedTripCountriesLine() {
    final seen = <String>{};
    final ordered = <String>[];
    for (final entry in tripPlanPlacesByDay.entries) {
      for (final place in entry.value) {
        final country = _extractCountryFromAddress(placeAddress(place));
        if (country.isEmpty) continue;
        final key = country.toLowerCase();
        if (seen.add(key)) ordered.add(country);
      }
    }
    return ordered.join(', ');
  }

  /// City / country lines for history cards (uses [trip] `days` places; falls back to legacy address in `country`).
  Map<String, String> historyLocationLinesForTrip(Map<String, dynamic> trip) {
    final cityOrder = <String>[];
    final citySeen = <String>{};
    final countryOrder = <String>[];
    final countrySeen = <String>{};

    void considerPlace(Map<String, dynamic> place) {
      final addr = placeAddress(place);
      final city = _extractCity(addr);
      final country = _extractCountryFromAddress(addr);
      if (city.isNotEmpty && citySeen.add(city.toLowerCase())) {
        cityOrder.add(city);
      }
      if (country.isNotEmpty && countrySeen.add(country.toLowerCase())) {
        countryOrder.add(country);
      }
    }

    final days = trip['days'];
    if (days is List) {
      for (final raw in days) {
        if (raw is! Map) continue;
        final places = raw['places'];
        if (places is! List) continue;
        for (final p in places) {
          if (p is Map<String, dynamic>) {
            considerPlace(p);
          } else if (p is Map) {
            considerPlace(Map<String, dynamic>.from(p));
          }
        }
      }
    }

    if (cityOrder.isNotEmpty || countryOrder.isNotEmpty) {
      return {
        'cities': cityOrder.isEmpty ? 'Trip Plan' : cityOrder.join(', '),
        'countries': countryOrder.join(', '),
      };
    }

    final legacyAddr = trip['country']?.toString() ?? '';
    if (legacyAddr.contains(',')) {
      final c = _extractCity(legacyAddr);
      final co = _extractCountryFromAddress(legacyAddr);
      return {
        'cities': c.isEmpty ? (trip['title']?.toString() ?? 'Trip Plan') : c,
        'countries': co,
      };
    }

    return {
      'cities': trip['title']?.toString() ?? 'Trip Plan',
      'countries': trip['country']?.toString() ?? '',
    };
  }

  static const _packageIncludeKeyOrder = [
    'filter_hotels_stays',
    'filter_food_restaurants',
    'filter_culture_heritage',
    'filter_transportation',
    'filter_shopping_souvenirs',
    'package_attractions',
  ];

  /// All places stored on [trip] `days` (order: day 1..n, then list order).
  List<Map<String, dynamic>> placesFlatFromTripData(Map<String, dynamic> trip) {
    final out = <Map<String, dynamic>>[];
    final days = trip['days'];
    if (days is! List) return out;
    for (final raw in days) {
      if (raw is! Map) continue;
      final places = raw['places'];
      if (places is! List) continue;
      for (final p in places) {
        if (p is Map<String, dynamic>) {
          out.add(p);
        } else if (p is Map) {
          out.add(Map<String, dynamic>.from(p));
        }
      }
    }
    return out;
  }

  Set<String> _packageCategoryKeysForPlace(Map<String, dynamic> place) {
    final types = ((place['types'] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    bool has(bool Function(String t) pred) => types.any(pred);
    final s = <String>{};
    if (has(
      (t) =>
          t.contains('hotel') ||
          t.contains('lodging') ||
          t.contains('resort') ||
          t.contains('guest_house'),
    )) {
      s.add('filter_hotels_stays');
    }
    if (has(
      (t) =>
          t.contains('restaurant') ||
          t.contains('food') ||
          t.contains('cafe') ||
          t.contains('meal'),
    )) {
      s.add('filter_food_restaurants');
    }
    if (has(
      (t) =>
          t.contains('museum') ||
          t.contains('mosque') ||
          t.contains('art_gallery') ||
          t.contains('landmark') ||
          t.contains('tourist_attraction') ||
          t.contains('cultural') ||
          t.contains('church') ||
          t.contains('hindu_temple') ||
          t.contains('synagogue'),
    )) {
      s.add('filter_culture_heritage');
    }
    if (has(
      (t) =>
          t.contains('airport') ||
          t.contains('bus_station') ||
          t.contains('train_station') ||
          t.contains('subway_station') ||
          t.contains('taxi_stand') ||
          t.contains('car_rental') ||
          t.contains('parking') ||
          t.contains('transit'),
    )) {
      s.add('filter_transportation');
    }
    if (has(
      (t) =>
          t.contains('shopping_mall') ||
          t.contains('department_store') ||
          t.contains('market') ||
          t.contains('souvenir') ||
          (t.contains('store') && !t.contains('restaurant')),
    )) {
      s.add('filter_shopping_souvenirs');
    }
    if (s.isEmpty && types.isNotEmpty) {
      s.add('package_attractions');
    }
    return s;
  }

  /// Localization keys for "Package includes", ordered (hotels, food, culture, …).
  List<String> packageIncludeKeysForTrip(Map<String, dynamic> trip) {
    final found = <String>{};
    for (final place in placesFlatFromTripData(trip)) {
      found.addAll(_packageCategoryKeysForPlace(place));
    }
    final ordered = <String>[];
    for (final k in _packageIncludeKeyOrder) {
      if (found.contains(k)) ordered.add(k);
    }
    return ordered;
  }

  String _categoryFromTypes(List<String> types) {
    if (types.any(
      (t) =>
          t.contains("hotel") || t.contains("lodging") || t.contains("resort"),
    )) {
      return "well-rated hotel offering comfortable accommodation";
    }
    if (types.any(
      (t) =>
          t.contains("restaurant") || t.contains("food") || t.contains("cafe"),
    )) {
      return "popular dining spot";
    }
    if (types.any((t) => t.contains("museum") || t.contains("art_gallery"))) {
      return "cultural attraction";
    }
    if (types.any(
      (t) => t.contains("mosque") || t.contains("place_of_worship"),
    )) {
      return "notable place of worship";
    }
    if (types.any((t) => t.contains("shopping_mall") || t.contains("store"))) {
      return "shopping destination";
    }
    if (types.any(
      (t) => t.contains("tourist_attraction") || t.contains("landmark"),
    )) {
      return "popular tourist attraction";
    }
    if (types.any((t) => t.contains("airport") || t.contains("transit"))) {
      return "transport hub";
    }
    return "notable destination";
  }

  String placeRatingText(Map<String, dynamic> place) {
    final rating = place["rating"]?.toString() ?? "0";
    final reviews = place["userRatingCount"]?.toString() ?? "0";
    return "$rating Rating ($reviews reviews)";
  }

  List<String> photoUrls(Map<String, dynamic> place) {
    final photos = place["photos"] as List?;
    if (photos == null || photos.isEmpty) return [];

    return photos
        .take(4)
        .map((photo) {
          final name = photo["name"];
          if (name == null) return "";
          return _api.photoUrl(name.toString());
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String? firstPhotoUrl(Map<String, dynamic> place) {
    final photos = place["photos"] as List?;
    if (photos == null || photos.isEmpty) return null;
    final name = photos.first["name"];
    if (name == null) return null;
    return _api.photoUrl(name.toString());
  }

  String placeLink(Map<String, dynamic> place) {
    final googleMapsUri = place["googleMapsUri"]?.toString();
    if (googleMapsUri != null && googleMapsUri.isNotEmpty) {
      return googleMapsUri;
    }
    return "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(placeName(place))}";
  }

  String placePriceLevel(Map<String, dynamic> place) {
    final raw = place["priceLevel"];
    if (raw == null) return _fallbackPriceLevel(place);

    final price = raw.toString().trim().toUpperCase();
    if (price.isEmpty) return _fallbackPriceLevel(place);

    switch (price) {
      case "PRICE_LEVEL_FREE":
        return "Free";
      case "PRICE_LEVEL_INEXPENSIVE":
        return "Budget";
      case "PRICE_LEVEL_MODERATE":
        return "Standard";
      case "PRICE_LEVEL_EXPENSIVE":
        return "Premium";
      case "PRICE_LEVEL_VERY_EXPENSIVE":
        return "Luxury";
      case "PRICE_LEVEL_UNSPECIFIED":
        return _fallbackPriceLevel(place);
    }

    if (price == "FREE") return "Free";
    if (price == "INEXPENSIVE") return "Budget";
    if (price == "MODERATE") return "Standard";
    if (price == "EXPENSIVE") return "Premium";
    if (price == "VERY_EXPENSIVE") return "Luxury";

    final numVal = num.tryParse(price);
    if (numVal != null) {
      if (numVal <= 0) return "Free";
      if (numVal == 1) return "Budget";
      if (numVal == 2) return "Standard";
      if (numVal == 3) return "Premium";
      if (numVal >= 4) return "Luxury";
    }

    return _fallbackPriceLevel(place);
  }

  String _fallbackPriceLevel(Map<String, dynamic> place) {
    final ext = placePriceExtraction(place);
    if (ext["price_type"] == "exact_price") {
      final v = ext["price_value"] as num?;
      if (v != null) return _levelFromValue(v.toDouble());
    }
    if (ext["price_type"] == "estimated_price") {
      final min = ext["price_min"] as num?;
      final max = ext["price_max"] as num?;
      if (min != null || max != null) {
        final mid = min != null && max != null
            ? (min.toDouble() + max.toDouble()) / 2
            : (min ?? max)!.toDouble();
        return _levelFromValue(mid);
      }
    }
    return "Not available";
  }

  String _levelFromValue(double v) {
    if (v <= 0) return "Free";
    if (v < 10) return "Budget";
    if (v < 30) return "Standard";
    if (v < 80) return "Premium";
    return "Luxury";
  }

  String placePriceOmr(Map<String, dynamic> place) {
    final raw = place["priceLevel"];
    if (raw == null) return _fallbackPriceOmr(place);

    final price = raw.toString().trim().toUpperCase();
    if (price.isEmpty) return _fallbackPriceOmr(place);

    switch (price) {
      case "PRICE_LEVEL_FREE":
        return "OMR 0";
      case "PRICE_LEVEL_INEXPENSIVE":
        return "OMR 5 - 15";
      case "PRICE_LEVEL_MODERATE":
        return "OMR 15 - 30";
      case "PRICE_LEVEL_EXPENSIVE":
        return "OMR 30 - 60";
      case "PRICE_LEVEL_VERY_EXPENSIVE":
        return "OMR 60+";
      case "PRICE_LEVEL_UNSPECIFIED":
        return _fallbackPriceOmr(place);
    }

    if (price == "FREE") return "OMR 0";
    if (price == "INEXPENSIVE") return "OMR 5 - 15";
    if (price == "MODERATE") return "OMR 15 - 30";
    if (price == "EXPENSIVE") return "OMR 30 - 60";
    if (price == "VERY_EXPENSIVE") return "OMR 60+";

    final numVal = num.tryParse(price);
    if (numVal != null) {
      if (numVal <= 0) return "OMR 0";
      if (numVal == 1) return "OMR 5 - 15";
      if (numVal == 2) return "OMR 15 - 30";
      if (numVal == 3) return "OMR 30 - 60";
      if (numVal >= 4) return "OMR 60+";
    }

    return _fallbackPriceOmr(place);
  }

  String _fallbackPriceOmr(Map<String, dynamic> place) {
    final ext = placePriceExtraction(place);
    if (ext["price_type"] == "exact_price") {
      final v = ext["price_value"];
      if (v is num) {
        return "OMR ${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}";
      }
    }
    if (ext["price_type"] == "estimated_price") {
      final min = ext["price_min"];
      final max = ext["price_max"];
      if (min is num && max is num) {
        return "OMR ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}";
      }
      if (min is num) return "OMR ${min.toStringAsFixed(0)}+";
    }
    return "OMR not available";
  }

  Map<String, dynamic> placePriceExtraction(Map<String, dynamic> place) {
    return PriceExtractionService.extractPrice(place);
  }

  String placePriceExtractionJson(Map<String, dynamic> place) {
    return PriceExtractionService.extractPriceJson(place);
  }

  bool isHotel(Map<String, dynamic> place) {
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    return types.any(
      (t) =>
          t.contains("hotel") ||
          t.contains("lodging") ||
          t.contains("resort") ||
          t.contains("guest_house"),
    );
  }

  bool isRestaurant(Map<String, dynamic> place) {
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    return types.any(
      (t) =>
          t.contains("restaurant") ||
          t.contains("food") ||
          t.contains("cafe") ||
          t.contains("meal"),
    );
  }

  /// Approximate OMR per night for hotels (detail page, cards).
  String placeHotelPricePerNight(Map<String, dynamic> place) {
    if (!isHotel(place)) return "";
    final ext = placePriceExtraction(place);
    if (ext["price_type"] == "exact_price") {
      final v = ext["price_value"];
      if (v is num) {
        return "OMR ${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}";
      }
    }
    if (ext["price_type"] == "estimated_price") {
      final min = ext["price_min"];
      final max = ext["price_max"];
      if (min is num &&
          max is num &&
          min.toDouble() > 0 &&
          max.toDouble() > 0) {
        return "OMR ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}";
      }
      if (min is num && min.toDouble() > 0) {
        return "From OMR ${min.toStringAsFixed(0)}";
      }
    }
    return "";
  }

  /// Price display for cards and detail: hotels = approximate OMR, restaurants = level, others = empty.
  String placePriceDisplayText(Map<String, dynamic> place) {
    if (isHotel(place)) return placeHotelPricePerNight(place);
    if (isRestaurant(place)) return placePriceLevel(place);
    return "";
  }

  /// Short info for card subtext (replaces "View details"): rating or location snippet.
  String placeCardSubtext(Map<String, dynamic> place) {
    final rating = place["rating"];
    final reviews = place["userRatingCount"];
    final address = placeAddress(place);

    if (rating is num && rating > 0) {
      final r = rating.toDouble().toStringAsFixed(1);
      final rev = reviews is num ? reviews.toInt() : 0;
      if (rev > 0) return "$r rating ($rev reviews)";
      return "$r rating";
    }
    if (address.isNotEmpty) {
      final parts = address
          .split(",")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length >= 2) return parts[0];
      return address.length > 40 ? "${address.substring(0, 37)}..." : address;
    }
    return "Discover more";
  }

  bool placePriceShowInDetail(Map<String, dynamic> place) {
    return isHotel(place) || isRestaurant(place);
  }

  bool placePriceShowStartFrom(Map<String, dynamic> place) {
    return isHotel(place);
  }

  double placeSortPriceValue(Map<String, dynamic> place) {
    final ext = placePriceExtraction(place);
    if (ext["price_type"] == "exact_price") {
      final v = ext["price_value"];
      if (v is num) return v.toDouble();
    }
    if (ext["price_type"] == "estimated_price") {
      final min = ext["price_min"];
      final max = ext["price_max"];
      if (min is num && max is num) {
        return ((min.toDouble() + max.toDouble()) / 2);
      }
      if (min is num) return min.toDouble();
    }
    return _mappedPrice(place);
  }

  double budgetScore(Map<String, dynamic> place) {
    final price = place["priceLevel"]?.toString() ?? "";

    switch (price) {
      case "PRICE_LEVEL_FREE":
        return 0;
      case "PRICE_LEVEL_INEXPENSIVE":
        return 10;
      case "PRICE_LEVEL_MODERATE":
        return 25;
      case "PRICE_LEVEL_EXPENSIVE":
        return 45;
      case "PRICE_LEVEL_VERY_EXPENSIVE":
        return 70;
      default:
        return 25;
    }
  }

  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;

    final dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final dLng = (lng2 - lng1) * (3.141592653589793 / 180);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            (sin(dLng / 2) * sin(dLng / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  ({double? lat, double? lng}) _extractLatLng(Map<String, dynamic> place) {
    final loc = place['location'];
    if (loc is Map) {
      final lat = loc['latitude'];
      final lng = loc['longitude'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
    }
    return (lat: null, lng: null);
  }

  Future<void> _loadNearbySuggestions(
    String city,
    List<String> placeTypes,
  ) async {
    try {
      final category = _detectCategory(placeTypes);

      final results = await _api.searchText("$category in $city");

      suggestedNearbyPlaces = results
          .whereType<Map<String, dynamic>>()
          .take(5)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      suggestedNearbyPlaces = [];
    }
  }

  String _detectCategory(List<String> types) {
    if (types.any((t) => t.contains('restaurant') || t.contains('food'))) {
      return "restaurants";
    }

    if (types.any((t) => t.contains('hotel') || t.contains('lodging'))) {
      return "hotels";
    }

    if (types.any((t) => t.contains('shopping') || t.contains('store'))) {
      return "shopping places";
    }

    if (types.any((t) => t.contains('museum') || t.contains('tourist'))) {
      return "tourist attractions";
    }

    return "tourist attractions";
  }
  void _sortPlacesByDistance(List<Map<String, dynamic>> places) {
    if (places.length < 2) return;

    final sorted = <Map<String, dynamic>>[];
    final remaining = List<Map<String, dynamic>>.from(places);

    // نبدأ بأول مكان
    sorted.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      final last = sorted.last;

      final lastCoords = _extractLatLng(last);

      double minDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < remaining.length; i++) {
        final current = remaining[i];
        final currentCoords = _extractLatLng(current);

        if (lastCoords.lat == null ||
            lastCoords.lng == null ||
            currentCoords.lat == null ||
            currentCoords.lng == null) {
          continue;
        }

        final distance = _calculateDistanceKm(
          lastCoords.lat!,
          lastCoords.lng!,
          currentCoords.lat!,
          currentCoords.lng!,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      sorted.add(remaining.removeAt(nearestIndex));
    }

    places
      ..clear()
      ..addAll(sorted);
  }
}
