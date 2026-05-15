import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/google_keys.dart';
import '../services/places_service.dart';
import '../services/price_extraction_service.dart';
import '../utils/ai_trip_plan_markdown_parser.dart';
import '../utils/invalid_place_text.dart';

/// Converts Firestore-typed values ([Timestamp], [GeoPoint], …) and strips binary
/// ([Uint8List], [Blob], [TypedData]) so [jsonEncode] stays small and Firestore writes succeed.
///
/// **Important:** [Uint8List] implements [Iterable<int>]. If handled as a generic [Iterable],
/// each byte becomes a JSON number and the payload can exceed Firestore limits—often seen on
/// active itineraries (map tiles, thumbnails) while older completed trips are URL-only.
dynamic _tripDataJsonSafeValue(dynamic value) {
  if (value == null) return null;
  if (value is bool || value is String) return value;
  if (value is num) {
    if (value.isNaN || value.isInfinite) return null;
    return value;
  }
  if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is GeoPoint) {
    return <String, double>{
      'latitude': value.latitude,
      'longitude': value.longitude,
    };
  }
  if (value is DocumentReference) {
    return value.path;
  }
  if (value is Blob) {
    return null;
  }
  if (value is VectorValue) {
    return value.toArray();
  }
  if (value is TypedData) {
    return null;
  }
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      out[k.toString()] = _tripDataJsonSafeValue(v);
    });
    return out;
  }
  if (value is Iterable) {
    return value.map(_tripDataJsonSafeValue).toList();
  }
  return value.toString();
}

/// Keys (and key substrings) removed from the **shared copy only** — map, route, and binary.
bool _sharePayloadKeyIsBanned(String key) {
  final s = key.toLowerCase();

  const uriKeepers = {'googlemapsuri', 'googlenavigationuri'};
  if (uriKeepers.contains(s)) return false;

  const exactBan = {
    'geometry',
    'bounds',
    'viewport',
    'camera',
    'coordinates',
    'overview_polyline',
    'overviewpolyline',
    'encoded_polyline',
    'encodedpolyline',
    'polylines',
    'polyline',
    'routes',
    'routedata',
    'routepoints',
    'markers',
    'markerbitmap',
    'snapshot',
    'thumbnail',
    'thumbnails',
    'bitmap',
    'cached',
    'cache',
    'geopoint',
    'geojson',
    'geohash',
    'tiles',
    'tile',
    'groundoverlay',
    'vector',
    'blob',
    'contentbytes',
    'photos',
    'photometadata',
    'addresscomponents',
    'adrformataddress',
    'routesteps',
    'legs',
    'navigationendpoint',
    'daypolylines',
    'routematrix',
    'mapview',
    'mapstyle',
    'mapdata',
    'mapcache',
    'cachedmap',
    'staticmap',
    'mapsnapshot',
    'routeshape',
    'routeline',
    'markericon',
    'markerimage',
    'markerdata',
    'polylinepoints',
    'encodedpath',
  };
  if (exactBan.contains(s)) return true;

  if (s.contains('polyline')) return true;
  if (s.contains('viewport')) return true;
  if (s.contains('snapshot')) return true;
  if (s.contains('thumbnail')) return true;
  if (s.contains('geopoint')) return true;
  if (s.contains('groundoverlay')) return true;
  if (s.contains('encodedpolyline')) return true;
  if (s.contains('markerbitmap')) return true;
  if (s.contains('staticmap')) return true;
  if (s.contains('mapsnapshot')) return true;
  if (s.contains('routedata')) return true;
  if (s.contains('routepoints')) return true;
  if (s.contains('routeresponse')) return true;
  if (s.contains('mapcache')) return true;
  if (s.contains('cachedmap')) return true;

  if (s == 'map' || s == 'maps') return true;
  if (s.startsWith('map') && s != 'mapurl') return true;
  if (s.endsWith('map') && s.length > 3) return true;
  if (s.contains('_map') || s.contains('map_')) return true;

  if (s == 'route' || s == 'routes') return true;
  if (s.startsWith('route_') || s.endsWith('_route')) return true;
  if (s.contains('routepoints')) return true;

  if (s.contains('marker')) {
    if (s == 'scheduledtimeminutes') return false;
    if (s.contains('scheduledtime')) return false;
    if (s.contains('remark')) return false;
    return true;
  }

  return false;
}

dynamic _stripHeavyKeysForShare(
  dynamic value, {
  int depth = 0,
  Set<String>? removedKeys,
  String path = '',
}) {
  if (depth > 80) return null;
  if (value == null) return null;
  if (value is TypedData || value is Blob) {
    removedKeys?.add(path.isEmpty ? '<TypedData>' : path);
    return null;
  }
  if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is GeoPoint) {
    return <String, double>{
      'latitude': value.latitude,
      'longitude': value.longitude,
    };
  }
  if (value is DocumentReference) {
    removedKeys?.add(path.isEmpty ? '<DocumentReference>' : path);
    return null;
  }
  if (value is VectorValue) {
    removedKeys?.add(path.isEmpty ? '<VectorValue>' : path);
    return null;
  }
  if (value is String) {
    if (value.length > 12000) {
      removedKeys?.add('$path.<truncated>');
      return value.substring(0, 12000);
    }
    return value;
  }
  if (value is num) {
    if (value.isNaN || value.isInfinite) return null;
    return value;
  }
  if (value is bool) return value;

  if (value is Map) {
    final out = <String, dynamic>{};
    for (final e in value.entries) {
      final k = e.key.toString();
      final childPath = path.isEmpty ? k : '$path.$k';
      if (_sharePayloadKeyIsBanned(k)) {
        removedKeys?.add(childPath);
        continue;
      }
      final v = _stripHeavyKeysForShare(
        e.value,
        depth: depth + 1,
        removedKeys: removedKeys,
        path: childPath,
      );
      if (v != null) {
        out[k] = v;
      } else if (e.value is bool) {
        out[k] = e.value;
      } else if (e.value is num && e.value == 0) {
        out[k] = 0;
      }
    }
    return out;
  }

  if (value is Iterable) {
    final out = <dynamic>[];
    var i = 0;
    for (final e in value) {
      final childPath = '$path[$i]';
      i++;
      final v = _stripHeavyKeysForShare(
        e,
        depth: depth + 1,
        removedKeys: removedKeys,
        path: childPath,
      );
      if (v != null) {
        out.add(v);
      } else if (e is Map) {
        out.add(<String, dynamic>{});
      } else if (e is Iterable) {
        out.add(<dynamic>[]);
      }
    }
    return out;
  }

  return value.toString();
}

Map<String, dynamic> _buildShareableTripSnapshotForShare(
  Map<String, dynamic> trip,
) {
  final removed = <String>{};
  if (kDebugMode) {
    debugPrint(
      'TravelProvider share snapshot: original top-level keys=${trip.keys.toList()}',
    );
  }

  final normalized = _tripDataJsonSafeValue(trip);
  if (normalized is! Map) {
    return <String, dynamic>{};
  }

  final base = Map<String, dynamic>.from(normalized);
  final stripped = _stripHeavyKeysForShare(
    base,
    removedKeys: removed,
  );
  if (stripped is! Map) {
    return <String, dynamic>{};
  }

  final out = Map<String, dynamic>.from(stripped);

  if (kDebugMode) {
    debugPrint(
      'TravelProvider share snapshot: stripped top-level keys=${out.keys.toList()}',
    );
    debugPrint(
      'TravelProvider share snapshot: removed paths (showing up to 60): '
      '${removed.take(60).join(', ')}${removed.length > 60 ? '…' : ''}',
    );
    final enc = jsonEncode(out);
    debugPrint('TravelProvider share snapshot: final jsonBytes=${enc.length}');
    for (final k in out.keys) {
      final piece = jsonEncode(<String, dynamic>{k: out[k]});
      if (piece.length > 25000) {
        debugPrint(
          'TravelProvider share snapshot: LARGE top-level field "$k" '
          'bytes=${piece.length}',
        );
      }
    }
  }

  return out;
}

class TravelProvider extends ChangeNotifier {
  final _api = PlacesService(GoogleKeys.placesKey);

  bool loading = false;
  String? error;

  /// Set when [search] fails; kept separate from [error] so a search failure does
  /// not wipe a home-load error and vice versa.
  String? searchError;

  bool searchLoading = false;

  List<dynamic> homePlaces = [];

  /// True when the user is in "planning mode" (adding places into Trip Plan).
  bool planningModeActive = false;

  void enablePlanningMode() {
    if (planningModeActive) return;
    planningModeActive = true;
    notifyListeners();
  }

  void disablePlanningMode() {
    if (!planningModeActive) return;
    planningModeActive = false;
    notifyListeners();
  }

  /// True when the last [loadHome] applied [userInterestKeys] filtering.
  bool lastHomeLoadFilteredByInterests = false;

  List<dynamic> searchPlaces = [];
  List<String> searchHistory = [];
  List<Map<String, dynamic>> recentlyViewed = [];
  List<Map<String, dynamic>> favoritePlaces = [];

  /// Extra places loaded when Home filters match nothing in [homePlaces] (location-scoped).
  List<dynamic> _homeFilterSupplementPlaces = [];

  bool homeCategoryFallbackLoading = false;
  String? homeCategoryFallbackErrorKey;

  String? _lastHomeFilterSupplementSignature;
  int _homeFilterSupplementRequestId = 0;

  final Map<String, List<dynamic>> _homeCategoryTextSearchCache = {};
  static const int _homeCategoryCacheMaxEntries = 32;

  static const _favoritesPrefsKey = 'favorite_places_v1';
  static const _savedTripsPrefsKey = 'saved_trips_v1';
  static const _offlineSavedTripsPrefsKey = 'offline_saved_trips_v1';
  static const _tripDraftPrefsKey = 'trip_plan_draft_v1';
  static const _homeCachePrefsKey = 'home_places_cache_v1';
  static const Duration _homeCacheTtl = Duration(hours: 24);

  /// v2: slimmed place payloads (v1 caches could be huge and caused UI jank / ANR).
  static const _searchCachePrefsKey = 'search_places_cache_map_v2';
  static const Duration _searchCacheTtl = Duration(hours: 24);
  static const int _searchCacheMaxEntries = 20;
  static const int _searchCacheMaxPlacesPerQuery = 25;

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
    sharedTrips = [];
    offlineSavedTrips = [];
    searchHistory = [];
    recentlyViewed = [];
    _searchAutocompleteCache.clear();
    _searchPlacesSessionCache.clear();
    _homeCategoryTextSearchCache.clear();
    _homeFilterSupplementPlaces.clear();
    _lastHomeFilterSupplementSignature = null;
    homeCategoryFallbackLoading = false;
    homeCategoryFallbackErrorKey = null;
    tripPlanStart = null;
    tripPlanEnd = null;
    tripPlanItineraryActive = false;
    tripPlanPlacesByDay = {};
    _editingSavedTripId = null;

    await _reloadTravelStorageForScope();
    notifyListeners();
  }

  Future<void> _reloadTravelStorageForScope() async {
    if (_isGuestScope) {
      await _loadFavoritesFromPrefs();
      await _loadSavedTripsFromPrefs();
      await _loadOfflineSavedTripsFromPrefs();
      await _loadTripPlanDraftFromPrefs();
      return;
    }

    await _loadTravelFromFirestore();
    await _loadOfflineSavedTripsFromPrefs();
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

    if (InvalidPlaceText.placeMapContainsErrorLikeStrings(place)) return;

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

      final beforeCt = favoritePlaces.length;
      favoritePlaces.removeWhere(InvalidPlaceText.placeMapContainsErrorLikeStrings);
      if (favoritePlaces.length != beforeCt) {
        unawaited(_persistFavoritesPrefsOnly());
      }
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

    tripPlanTripName = (m['tripName'] ?? '').toString();

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

    _backfillMissingScheduleTimesInDraft();

    final eId = m['editingTripId']?.toString().trim();
    _editingSavedTripId = (eId != null && eId.isNotEmpty) ? eId : null;
  }

  /// Legacy trips saved before scheduling: assign non-colliding times so save/validate works.
  void _backfillMissingScheduleTimesInDraft() {
    for (final list in tripPlanPlacesByDay.values) {
      final used = <int>{};

      for (final x in list) {
        if (_placeIsHotelStayInTrip(x)) continue;

        final m = scheduledTimeMinutesFromTripPlace(x);

        if (m != null) used.add(m);
      }

      var slot = 9 * 60;

      for (final p in list) {
        if (_placeIsHotelStayInTrip(p)) {
          p['hotelStayOnDay'] = true;
          p.remove('scheduledTimeMinutes');
          continue;
        }

        if (p['scheduledTimeMinutes'] == null) {
          while (used.contains(slot)) {
            slot = (slot + 1) % 1440;
          }

          p['scheduledTimeMinutes'] = slot;
          p['hotelStayOnDay'] = false;
          used.add(slot);
          slot = (slot + 30) % 1440;
        } else {
          p['hotelStayOnDay'] = false;
        }
      }

      _sortTripDayPlacesBySchedule(list);
    }
  }

  void _clearTripPlanDraftState() {
    tripPlanStart = null;
    tripPlanEnd = null;
    tripPlanItineraryActive = false;
    tripPlanPlacesByDay = {};
    tripPlanTripName = '';
    _editingSavedTripId = null;
  }

  void _applyTravelDataFromFirestore(Map<String, dynamic> data) {
    favoritePlaces = _asMapList(data['favoritePlaces']);
    favoritePlaces.removeWhere(InvalidPlaceText.placeMapContainsErrorLikeStrings);
    savedTrips = _asMapList(data['savedTrips']);
    sharedTrips = _asMapList(data['sharedTrips']);
    // Offline saved itineraries are intentionally local-only; do not sync to Firestore.
    offlineSavedTrips = [];

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

    final out = <String, dynamic>{
      'start': tripPlanStart?.toIso8601String(),
      'end': tripPlanEnd?.toIso8601String(),
      'itineraryActive': tripPlanItineraryActive,
      'tripName': tripPlanTripName,
      'placesByDay': placesJson,
    };

    final eId = _editingSavedTripId?.trim();
    if (eId != null && eId.isNotEmpty) {
      out['editingTripId'] = eId;
    }

    return out;
  }

  Future<void> _pushFullTravelToFirestore() async {
    final ref = _travelFirestoreRef();

    if (ref == null) return;

    try {
      final payload = <String, dynamic>{
        'favoritePlaces': favoritePlaces,
        'savedTrips': savedTrips,
        'sharedTrips': sharedTrips,
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
      await ref.set(
        {
          'favoritePlaces': favoritePlaces,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _persistFavoritesPrefsOnly();
    } catch (e) {
      debugPrint('TravelProvider Firestore save favorites: $e');
      await _persistFavoritesPrefsOnly();
    }
  }

  // ---------------------------------------------------------------------------
  // Trip plan
  // ---------------------------------------------------------------------------

  DateTime? tripPlanStart;
  DateTime? tripPlanEnd;
  bool tripPlanItineraryActive = false;
  Map<int, List<Map<String, dynamic>>> tripPlanPlacesByDay = {};

  /// User-visible trip name (draft + save).
  String tripPlanTripName = '';

  /// When non-null, [saveCurrentItinerary] updates the existing trip with this id.
  String? _editingSavedTripId;

  void setTripPlanTripName(String value) {
    tripPlanTripName = value;
    notifyListeners();
    _schedulePersistTripDraft();
  }

  int get tripPlanDayCount {
    if (tripPlanStart == null || tripPlanEnd == null) return 0;
    return tripPlanEnd!.difference(tripPlanStart!).inDays + 1;
  }

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

  void applyTripPlanDates(DateTime start, DateTime end) {
    final rangeChanged = !_sameCalendarDate(tripPlanStart, start) ||
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

  /// True when this row is a hotel / check-in style entry (no clock time).
  bool placeIsHotelStayInTrip(Map<String, dynamic> place) =>
      _placeIsHotelStayInTrip(place);

  bool _placeIsHotelStayInTrip(Map<String, dynamic> place) {
    if (place['hotelStayOnDay'] == true) return true;

    return isHotel(place);
  }

  /// Minutes from midnight for scheduled activities; null for hotel stays.
  int? scheduledTimeMinutesFromTripPlace(Map<String, dynamic> place) {
    if (_placeIsHotelStayInTrip(place)) return null;

    final v = place['scheduledTimeMinutes'];

    if (v is int) return v.clamp(0, 1439);

    if (v is num) return v.toInt().clamp(0, 1439);

    return null;
  }

  /// Manual trip planner: max activities + hotel rows per calendar day.
  static const int maxManualPlacesPerTripDay = 7;

  String? _validateDayPlacesList(List<Map<String, dynamic>> list) {
    if (list.length > maxManualPlacesPerTripDay) return 'max_places_per_day';

    final seenIds = <String>{};

    for (final p in list) {
      final id = placeFavoriteId(p);

      if (!seenIds.add(id)) return 'place_already_added_same_day';
    }

    if (list.isEmpty) return null;

    final anchorAddr = placeAddress(list.first);
    final anchorCountry = _extractCountryFromAddress(anchorAddr);

    for (final p in list.skip(1)) {
      final addr = placeAddress(p);
      final newCountry = _extractCountryFromAddress(addr);

      if (newCountry.isNotEmpty &&
          anchorCountry.isNotEmpty &&
          newCountry.toLowerCase() != anchorCountry.toLowerCase()) {
        return 'different_countries_same_day';
      }
    }

    String? anchorGov;

    for (final p in list) {
      final g = _governorateComparableKey(p);

      if (g.isNotEmpty) {
        anchorGov = g;
        break;
      }
    }

    if (anchorGov == null) return null;

    for (final p in list) {
      final gov = _governorateComparableKey(p);

      if (gov.isNotEmpty && gov != anchorGov) {
        return 'different_governorates_same_day';
      }
    }

    return null;
  }

  void _sortTripDayPlacesBySchedule(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final ha = _placeIsHotelStayInTrip(a);
      final hb = _placeIsHotelStayInTrip(b);

      if (ha && !hb) return 1;

      if (!ha && hb) return -1;

      if (ha && hb) {
        return placeName(a).toLowerCase().compareTo(placeName(b).toLowerCase());
      }

      final ma = scheduledTimeMinutesFromTripPlace(a) ?? 720;
      final mb = scheduledTimeMinutesFromTripPlace(b) ?? 720;

      final c = ma.compareTo(mb);

      if (c != 0) return c;

      return placeName(a).toLowerCase().compareTo(placeName(b).toLowerCase());
    });
  }

  /// Add [place] to a trip day with optional schedule. Hotels only need [hotelStayOnDay].
  bool addPlaceToTripDay(
    int dayNumber,
    Map<String, dynamic> place, {
    int? scheduledTimeMinutes,
    bool hotelStayOnDay = false,
  }) {
    if (dayNumber < 1 || dayNumber > tripPlanDayCount) return false;

    final id = placeFavoriteId(place);

    final list = tripPlanPlacesByDay.putIfAbsent(
      dayNumber,
      () => <Map<String, dynamic>>[],
    );

    if (list.length >= maxManualPlacesPerTripDay) {
      error = 'max_places_per_day';
      notifyListeners();
      return false;
    }

    final exists = list.any((p) => placeFavoriteId(p) == id);

    if (exists) {
      error = 'place_already_added_same_day';
      notifyListeners();
      return false;
    }

    final effectiveHotel = hotelStayOnDay || isHotel(place);

    if (!effectiveHotel &&
        (scheduledTimeMinutes == null ||
            scheduledTimeMinutes < 0 ||
            scheduledTimeMinutes > 1439)) {
      error = 'activity_time_required';
      notifyListeners();
      return false;
    }

    final trial = List<Map<String, dynamic>>.from(list);
    final enriched = Map<String, dynamic>.from(place);

    if (effectiveHotel) {
      enriched['hotelStayOnDay'] = true;
      enriched.remove('scheduledTimeMinutes');
    } else {
      enriched['hotelStayOnDay'] = false;
      enriched['scheduledTimeMinutes'] = scheduledTimeMinutes!.clamp(0, 1439);

      for (final existing in list) {
        if (_placeIsHotelStayInTrip(existing)) continue;

        final em = scheduledTimeMinutesFromTripPlace(existing);

        if (em != null && em == enriched['scheduledTimeMinutes']) {
          error = 'duplicate_activity_time_same_day';
          notifyListeners();
          return false;
        }
      }
    }

    trial.add(enriched);

    final dayErr = _validateDayPlacesList(trial);

    if (dayErr != null) {
      error = dayErr;
      notifyListeners();
      return false;
    }

    list.add(enriched);
    _sortTripDayPlacesBySchedule(list);

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

  // ---------------------------------------------------------------------------
  // GCC filtering
  // ---------------------------------------------------------------------------

  static const double _gccLowLat = 16.0;
  static const double _gccLowLng = 34.0;
  static const double _gccHighLat = 33.5;
  static const double _gccHighLng = 60.5;

  static const Set<String> _gccCountryCodes = {
    'OM',
    'AE',
    'SA',
    'QA',
    'BH',
    'KW',
  };

  /// In-memory autocomplete cache for the Search page (session lifetime).
  final Map<String, List<Map<String, dynamic>>> _searchAutocompleteCache = {};

  /// In-memory Text Search results for the session (normalized query key).
  final Map<String, List<Map<String, dynamic>>> _searchPlacesSessionCache = {};

  static const int _searchSessionCacheMaxEntries = 36;

  List<String> _popularTripInterestLabelsMem = [];
  DateTime? _popularTripInterestLabelsFetchedAt;
  static const Duration _popularTripInterestTtl = Duration(minutes: 45);

  static String generateAutocompleteSessionToken() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final r = Random.secure();
    return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Collapses verbose selected autocomplete strings into a concise Text Search query.
  ///
  /// Example: "UAE - Dubai - United Arab Emirates" -> "Dubai"
  static String normalizePlacesSearchQuery(String raw) {
    var s = raw.trim();

    if (s.isEmpty) return s;

    s = s.replaceAll(RegExp(r'[\t\n\r]+'), ' ');
    s = s.replaceAll(RegExp(r'[\s\-_,;|]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (s.isEmpty) return raw.trim();

    const noiseTokens = <String>[
      'united arab emirates',
      'united arab emirate',
      'uae',
      'kingdom of saudi arabia',
      'kingdom of bahrain',
      'state of qatar',
      'state of kuwait',
      'saudi arabia',
      'ksa',
      'bahrain',
      'qatar',
      'kuwait',
      'oman',
      'gcc',
      'middle east',
    ];

    for (final token in noiseTokens) {
      s = s.replaceAll(
        RegExp('\\b${RegExp.escape(token)}\\b', caseSensitive: false),
        ' ',
      );
    }

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (s.length < 2) return raw.trim();

    return s;
  }

  static const String searchFailureLocalizationKey = 'places_connection_error';

  /// Shared validation for place titles, addresses, history chips, etc.
  static bool isInvalidPlaceText(String? text) => InvalidPlaceText.isInvalid(text);

  void _stripInvalidMapsFromDynamicList(List<dynamic> list) {
    list.removeWhere((e) {
      if (e is! Map) return true;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      return InvalidPlaceText.placeMapContainsErrorLikeStrings(m);
    });
  }

  List<Map<String, dynamic>> _stripInvalidPlaceMapsFromList(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .where((m) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(m))
        .toList();
  }

  String _searchFailureLocalizationKeyFor(Object e) {
    if (kDebugMode) {
      debugPrint('TravelProvider.search failed: $e');
    }

    return searchFailureLocalizationKey;
  }

  void _rememberSearchSessionPlaces(String key, List<dynamic> items) {
    final copy = items
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((m) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(m))
        .toList();

    _searchPlacesSessionCache[key] = copy;

    while (_searchPlacesSessionCache.length > _searchSessionCacheMaxEntries) {
      final k = _searchPlacesSessionCache.keys.first;

      _searchPlacesSessionCache.remove(k);
    }
  }

  String? _countryShortFromPlace(Map<String, dynamic> place) {
    final raw = place['addressComponents'];
    if (raw is! List) return null;

    for (final item in raw) {
      if (item is! Map) continue;

      final types = item['types'];

      if (types is! List) continue;

      final typeStrs = types.map((e) => e.toString()).toList();

      if (!typeStrs.contains('country')) continue;

      final st = item['shortText']?.toString() ?? item['short_name']?.toString();

      if (st != null && st.trim().isNotEmpty) return st.trim().toUpperCase();
    }

    return null;
  }

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

  /// True when the place is in a GCC country (prefer address country code).
  bool _placeInGcc(Map<String, dynamic> place) {
    final code = _countryShortFromPlace(place);

    if (code != null && code.isNotEmpty) {
      return _gccCountryCodes.contains(code);
    }

    final addr = placeAddress(place).toLowerCase();

    if (addr.contains('oman') ||
        addr.contains('uae') ||
        addr.contains('emirates') ||
        addr.contains('dubai') ||
        addr.contains('abu dhabi') ||
        addr.contains('sharjah') ||
        addr.contains('saudi') ||
        addr.contains('qatar') ||
        addr.contains('bahrain') ||
        addr.contains('kuwait')) {
      return true;
    }

    return _insideGccBox(place);
  }

  List<dynamic> _onlyGcc(List<dynamic> items) {
    final out = <dynamic>[];

    for (final it in items) {
      if (it is! Map) continue;

      final m = Map<String, dynamic>.from(it);

      if (_placeInGcc(m) && !InvalidPlaceText.placeMapContainsErrorLikeStrings(m)) {
        out.add(m);
      }
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Saved itinerary history
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> savedTrips = [];

  /// Itineraries shared with this user (Firestore `sharedTrips` on travel storage).
  List<Map<String, dynamic>> sharedTrips = [];

  // ---------------------------------------------------------------------------
  // Offline Saved Itinerary (explicit user action from Trip Detail)
  // ---------------------------------------------------------------------------

  /// Trips explicitly saved for offline use from Trip Detail.
  ///
  /// This is separate from [savedTrips] (trip history / planner saves).
  List<Map<String, dynamic>> offlineSavedTrips = [];

  Future<void> _loadOfflineSavedTripsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoped = _scopedPrefsKey(_offlineSavedTripsPrefsKey);

      var raw = prefs.getString(scoped);

      if (raw == null || raw.isEmpty) {
        final legacy = prefs.getString(_offlineSavedTripsPrefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          await prefs.setString(scoped, legacy);
          await prefs.remove(_offlineSavedTripsPrefsKey);
          raw = legacy;
        }
      }

      if (raw == null || raw.isEmpty) {
        offlineSavedTrips = [];
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        offlineSavedTrips = [];
        return;
      }

      offlineSavedTrips = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      offlineSavedTrips = [];
    }
  }

  Future<void> _persistOfflineSavedTripsPrefsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scopedPrefsKey(_offlineSavedTripsPrefsKey),
        jsonEncode(offlineSavedTrips),
      );
    } catch (_) {}
  }

  /// OFFLINE SAVE/LOAD LOGIC
  ///
  /// Stores a full itinerary payload locally so it can be opened without internet.
  /// This list is shown in Settings > Saved Itinerary.
  Future<bool> saveItineraryOffline(Map<String, dynamic> trip) async {
    try {
      // Deep copy to avoid accidental mutations from UI code.
      final copy = jsonDecode(jsonEncode(trip));
      if (copy is! Map) return false;

      final nowIso = DateTime.now().toUtc().toIso8601String();
      final t = Map<String, dynamic>.from(copy);

      final existingId = t['id']?.toString().trim();
      final id = (existingId != null && existingId.isNotEmpty)
          ? existingId
          : DateTime.now().millisecondsSinceEpoch.toString();

      t['id'] = id;
      t['updatedAt'] = nowIso;
      t['createdAt'] = (t['createdAt']?.toString().isNotEmpty == true)
          ? t['createdAt']?.toString()
          : nowIso;

      final idx =
          offlineSavedTrips.indexWhere((x) => x['id']?.toString() == id);
      if (idx >= 0) {
        offlineSavedTrips[idx] = t;
      } else {
        offlineSavedTrips.insert(0, t);
      }

      notifyListeners();
      await _persistOfflineSavedTripsPrefsOnly();
      return true;
    } catch (e) {
      debugPrint('TravelProvider saveItineraryOffline: $e');
      return false;
    }
  }

  /// Returns true when there is at least one locally saved itinerary.
  Future<bool> hasOfflineSavedItinerary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedPrefsKey(_offlineSavedTripsPrefsKey));
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      return decoded is List && decoded.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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
      await ref.set(
        {
          'savedTrips': savedTrips,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _persistSavedTripsPrefsOnly();
    } catch (e) {
      debugPrint('TravelProvider Firestore save trips: $e');
      await _persistSavedTripsPrefsOnly();
    }
  }

  /// Removes this itinerary from [savedTrips] and persists (Firestore when logged in).
  Future<bool> deleteSavedTrip(Map<String, dynamic> trip) async {
    final id = trip['id']?.toString().trim();
    final start = trip['startDate']?.toString();
    final end = trip['endDate']?.toString();

    final initialLen = savedTrips.length;

    if (id != null && id.isNotEmpty) {
      savedTrips.removeWhere((t) => t['id']?.toString() == id);
    } else if (start != null &&
        end != null &&
        start.isNotEmpty &&
        end.isNotEmpty) {
      savedTrips.removeWhere(
        (t) =>
            t['startDate']?.toString() == start &&
            t['endDate']?.toString() == end,
      );
    } else {
      return false;
    }

    if (savedTrips.length == initialLen) {
      return false;
    }

    notifyListeners();

    try {
      await _persistSavedTrips();
      return true;
    } catch (e) {
      debugPrint('TravelProvider deleteSavedTrip: $e');
      return false;
    }
  }

  /// Reloads travel data from Firestore for the current storage scope (e.g. after a share was received).
  Future<void> refreshTravelFromFirestore() async {
    if (_isGuestScope) return;

    try {
      await _loadTravelFromFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('TravelProvider refreshTravelFromFirestore: $e');
    }
  }

  /// Returns a deep copy of [trip] suitable for [loadSavedTripIntoPlanner] so the user saves a new itinerary.
  Map<String, dynamic> prepareTripSnapshotForPlannerReuse(
    Map<String, dynamic> trip,
  ) {
    try {
      final sanitized = _tripDataJsonSafeValue(trip);
      if (sanitized is! Map) return Map<String, dynamic>.from(trip);

      final raw = jsonDecode(jsonEncode(sanitized));
      if (raw is! Map) return Map<String, dynamic>.from(trip);

      final m = Map<String, dynamic>.from(raw);
      m.remove('id');
      m.remove('sharedEntryId');
      m.remove('sharedByUid');
      m.remove('sharedByEmail');
      m.remove('sharedAt');
      return m;
    } catch (_) {
      final m = Map<String, dynamic>.from(trip);
      m.remove('id');
      return m;
    }
  }

  /// Shares a snapshot of [trip] with the account registered in Firestore under [emailInput].
  /// Returns `null` on success, or a localization key for an error message.
  Future<String?> shareItineraryWithUserByEmail(
    String emailInput,
    Map<String, dynamic> trip,
  ) async {
    if (_isGuestScope) return 'share_requires_login';

    final trimmed = emailInput.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return 'share_invalid_email';
    }

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return 'share_requires_login';

    final myEmail = me.email?.trim().toLowerCase() ?? '';
    if (trimmed.toLowerCase() == myEmail) {
      return 'share_cannot_share_with_self';
    }

    String? receiverUid;

    final candidates = <String>{trimmed, trimmed.toLowerCase()};
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;

      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: candidate)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          receiverUid = snap.docs.first.id;
          break;
        }
      } catch (e) {
        debugPrint('TravelProvider shareItinerary lookup: $e');
        return 'share_failed';
      }
    }

    if (receiverUid == null || receiverUid.isEmpty) {
      return 'share_user_not_found';
    }

    if (receiverUid == me.uid) return 'share_cannot_share_with_self';

    final statusKey = trip['statusKey']?.toString();
    final tripId = trip['id']?.toString();
    final endDate = trip['endDate']?.toString();
    if (kDebugMode) {
      debugPrint(
        'TravelProvider share: start statusKey=$statusKey id=$tripId endDate=$endDate '
        'receiver=$receiverUid email=$trimmed',
      );
    }

    Map<String, dynamic> tripCopy;

    try {
      final snapshot = _buildShareableTripSnapshotForShare(
        Map<String, dynamic>.from(trip),
      );
      if (snapshot.isEmpty) {
        debugPrint('TravelProvider share: share snapshot is empty');
        return 'share_failed';
      }

      final encoded = jsonEncode(snapshot);
      if (kDebugMode) {
        debugPrint(
          'TravelProvider share: share payload jsonBytes=${encoded.length}',
        );
      }

      final raw = jsonDecode(encoded);
      if (raw is! Map) return 'share_failed';

      tripCopy = Map<String, dynamic>.from(raw);
      tripCopy.remove('id');
      tripCopy.remove('sharedEntryId');
      tripCopy.remove('sharedByUid');
      tripCopy.remove('sharedByEmail');
      tripCopy.remove('sharedAt');
    } catch (e, st) {
      debugPrint('TravelProvider shareItineraryWithUserByEmail encode: $e\n$st');
      return 'share_failed';
    }

    final entry = <String, dynamic>{
      'sharedEntryId': DateTime.now().microsecondsSinceEpoch.toString(),
      'trip': tripCopy,
      'sharedByUid': me.uid,
      'sharedByEmail': me.email ?? '',
      'sharedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUid)
        .collection(_firestoreTravelCollection)
        .doc(_firestoreTravelDocId);

    try {
      await ref.set(
        {
          'sharedTrips': FieldValue.arrayUnion([entry]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (kDebugMode) {
        debugPrint(
          'TravelProvider share: Firestore arrayUnion ok sharedEntryId=${entry['sharedEntryId']}',
        );
      }
      return null;
    } catch (e, st) {
      debugPrint(
        'TravelProvider shareItineraryWithUserByEmail arrayUnion failed: $e\n$st',
      );
      try {
        await FirebaseFirestore.instance.runTransaction((txn) async {
          final snap = await txn.get(ref);
          final data = snap.data() ?? {};
          final merged = <Map<String, dynamic>>[];
          final cur = data['sharedTrips'];
          if (cur is List) {
            for (final x in cur) {
              if (x is Map<String, dynamic>) {
                merged.add(Map<String, dynamic>.from(x));
              } else if (x is Map) {
                merged.add(Map<String, dynamic>.from(x));
              }
            }
          }
          merged.add(entry);
          txn.set(
            ref,
            {
              'sharedTrips': merged,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });
        if (kDebugMode) {
          debugPrint(
            'TravelProvider share: Firestore transaction append ok '
            'sharedEntryId=${entry['sharedEntryId']}',
          );
        }
        return null;
      } catch (e2, st2) {
        debugPrint(
          'TravelProvider shareItineraryWithUserByEmail transaction failed: $e2\n$st2',
        );
        return 'share_failed';
      }
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

      final draftBody = <String, dynamic>{
        'start': tripPlanStart?.toIso8601String(),
        'end': tripPlanEnd?.toIso8601String(),
        'itineraryActive': tripPlanItineraryActive,
        'tripName': tripPlanTripName,
        'placesByDay': placesJson,
      };

      final eId = _editingSavedTripId?.trim();
      if (eId != null && eId.isNotEmpty) {
        draftBody['editingTripId'] = eId;
      }

      await prefs.setString(
        key,
        jsonEncode(draftBody),
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
        await ref.set(
          {
            'tripPlanDraft': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        await ref.set(
          {
            'tripPlanDraft': draft,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
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
    _editingSavedTripId = null;
  }

  void loadSavedTripIntoPlanner(
    Map<String, dynamic> trip, {
    int? listIndex,
  }) {
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

    final idFromTrip = trip['id']?.toString();
    if (idFromTrip != null && idFromTrip.isNotEmpty) {
      _editingSavedTripId = idFromTrip;
    } else if (listIndex != null &&
        listIndex >= 0 &&
        listIndex < savedTrips.length) {
      _editingSavedTripId = savedTrips[listIndex]['id']?.toString();
    } else {
      _editingSavedTripId = null;
    }

    tripPlanTripName = (trip['tripName'] ?? trip['title'] ?? '').toString();

    _backfillMissingScheduleTimesInDraft();

    notifyListeners();
    _schedulePersistTripDraft();
  }

  /// Full validation before persisting a trip (same rules as add-place).
  String? validateEntireTripPlanForSave() {
    final n = tripPlanDayCount;

    if (n <= 0) return null;

    for (var d = 1; d <= n; d++) {
      final list = tripPlanPlacesByDay[d];

      if (list == null || list.isEmpty) {
        return 'itinerary_each_day_needs_place';
      }

      final err = _validateDayPlacesList(list);

      if (err != null) return err;

      final seenTimes = <int>{};

      for (final p in list) {
        if (_placeIsHotelStayInTrip(p)) continue;

        final mins = scheduledTimeMinutesFromTripPlace(p);

        if (mins == null) return 'activity_time_required';

        if (seenTimes.contains(mins)) {
          return 'duplicate_activity_time_same_day';
        }

        seenTimes.add(mins);
      }
    }

    return null;
  }

  Future<bool> saveCurrentItinerary() async {
    if (tripPlanStart == null || tripPlanEnd == null) return false;
    if (!isTripPlanItineraryEveryDayFilled) return false;

    final name = tripPlanTripName.trim();

    if (name.isEmpty) {
      error = 'trip_name_required';
      notifyListeners();
      return false;
    }

    final planErr = validateEntireTripPlanForSave();

    if (planErr != null) {
      error = planErr;
      notifyListeners();
      return false;
    }

    final image = _buildSavedTripImage();
    final completed = _isCompletedTrip(tripPlanEnd!);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final trip = <String, dynamic>{
      "statusKey": completed ? "completed" : "on_going",
      "tripName": name,
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
      "updatedAt": nowIso,
    };

    final editId = _editingSavedTripId?.trim();

    if (editId != null && editId.isNotEmpty) {
      trip['id'] = editId;

      final idMatches = <int>[];
      for (var i = 0; i < savedTrips.length; i++) {
        final tid = savedTrips[i]['id']?.toString();
        if (tid != null && tid.trim() == editId) idMatches.add(i);
      }

      if (idMatches.isNotEmpty) {
        final keepIdx = idMatches.first;
        final existing = savedTrips[keepIdx];
        trip['createdAt'] =
            existing['createdAt']?.toString() ?? existing['created_at']?.toString() ?? nowIso;
        savedTrips[keepIdx] = trip;

        for (var j = idMatches.length - 1; j >= 1; j--) {
          savedTrips.removeAt(idMatches[j]);
        }
      } else {
        trip['createdAt'] = nowIso;
        savedTrips.add(trip);
      }
    } else {
      trip['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      trip['createdAt'] = nowIso;
      savedTrips.insert(0, trip);
    }

    await _persistSavedTrips();

    _clearTripPlanDraftState();

    await _persistTripPlanDraft();

    notifyListeners();

    return true;
  }

  /// Persists an AI-parsed itinerary into [savedTrips] (same storage as manual trips).
  Future<bool> saveAiGeneratedTripFromParsed(ParsedAiTripForSave parsed) async {
    final trip = parsed.toTripMap();
    savedTrips.insert(0, trip);
    await _persistSavedTrips();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Home and search
  // ---------------------------------------------------------------------------

  /// Aggregates interest labels from all users' `trips` documents (Firestore).
  Future<List<String>> _fetchPopularTripInterestLabels() async {
    final now = DateTime.now();

    if (_popularTripInterestLabelsFetchedAt != null &&
        now.difference(_popularTripInterestLabelsFetchedAt!) <
            _popularTripInterestTtl &&
        _popularTripInterestLabelsMem.isNotEmpty) {
      return _popularTripInterestLabelsMem;
    }

    try {
      final snap =
          await FirebaseFirestore.instance.collection('trips').limit(400).get();

      final counts = <String, int>{};

      for (final d in snap.docs) {
        final raw = d.data()['interest'];

        if (raw is! List) continue;

        for (final e in raw) {
          final s = e.toString().trim().toLowerCase();

          if (s.isEmpty) continue;

          counts[s] = (counts[s] ?? 0) + 1;
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _popularTripInterestLabelsMem =
          sorted.take(12).map((e) => e.key).toList();

      _popularTripInterestLabelsFetchedAt = now;

      return _popularTripInterestLabelsMem;
    } catch (_) {
      return _popularTripInterestLabelsMem;
    }
  }

  bool _tripInterestLabelMatchesPlace(
    String labelLower,
    Map<String, dynamic> place,
  ) {
    final l = labelLower;

    final keys = <String>{};

    if (RegExp(r'cultur|herit|hist|museum|mosque|gallery|art|تراث|ثقاف')
        .hasMatch(l)) {
      keys.add('interest_cultural_heritage');
    }

    if (RegExp(r'shop|mall|market|souven|تسوق').hasMatch(l)) {
      keys.add('interest_shopping');
    }

    if (RegExp(r'food|restaurant|cafe|cuisine|dining|طعام').hasMatch(l)) {
      keys.add('interest_trying_local_food');
    }

    if (RegExp(r'outdoor|adventure|hiking|beach|park|desert|طبيعة')
        .hasMatch(l)) {
      keys.add('interest_outdoor_adventures');
    }

    if (RegExp(r'relax|spa|wellness|resort').hasMatch(l)) {
      keys.add('interest_relaxation');
    }

    if (RegExp(r'attraction|sight|landmark|explore').hasMatch(l)) {
      keys.add('interest_local_attractions');
    }

    if (RegExp(r'leisure|night|entertain|game').hasMatch(l)) {
      keys.add('interest_leisure');
    }

    if (RegExp(r'family|friend|social').hasMatch(l)) {
      keys.add('interest_visiting_family_friends');
    }

    for (final k in keys) {
      if (_matchesInterestKey(place, k)) return true;
    }

    final hay =
        '${placeName(place)} ${placeAddress(place)} ${_placeTypesCategoryHaystack(place)}'
            .toLowerCase();

    return hay.contains(l);
  }

  int _popularAggregateScore(
    Map<String, dynamic> place,
    List<String> labels,
  ) {
    if (labels.isEmpty) return 0;

    var score = 0;

    for (final lb in labels) {
      if (_tripInterestLabelMatchesPlace(lb, place)) score++;
    }

    return score;
  }

  void _sortHomePlacesByPopularInterestsThenRating(
    List<dynamic> list,
    List<String> popularLabels,
  ) {
    if (popularLabels.isEmpty) {
      list.sort((a, b) {
        final aRating = ((a["rating"] ?? 0) as num).toDouble();
        final bRating = ((b["rating"] ?? 0) as num).toDouble();

        return bRating.compareTo(aRating);
      });

      return;
    }

    list.sort((a, b) {
      if (a is! Map || b is! Map) return 0;

      final ma = Map<String, dynamic>.from(a);
      final mb = Map<String, dynamic>.from(b);

      final sa = _popularAggregateScore(ma, popularLabels);
      final sb = _popularAggregateScore(mb, popularLabels);

      if (sa != sb) return sb.compareTo(sa);

      final aRating = ((a["rating"] ?? 0) as num).toDouble();
      final bRating = ((b["rating"] ?? 0) as num).toDouble();

      return bRating.compareTo(aRating);
    });
  }

  Future<void> loadHome(
    String city, {
    List<String> userInterestKeys = const [],
    bool forceRefresh = false,
  }) async {
    final cityClean = city.trim().isEmpty ? 'Oman' : city.trim();
    final interestKeys = userInterestKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_lastLoadedHomeCity != null &&
        _lastLoadedHomeCity!.toLowerCase() != cityClean.toLowerCase()) {
      _clearHomeFilterSupplement();
    }

    if (!forceRefresh &&
        _lastLoadedHomeCity == cityClean &&
        homePlaces.isNotEmpty &&
        interestKeys.isEmpty) {
      return;
    }

    if (!forceRefresh && interestKeys.isEmpty) {
      final cached = await _readHomeCache(cityClean);

      if (cached != null) {
        final labels = await _fetchPopularTripInterestLabels();

        homePlaces = cached;
        _lastLoadedHomeCity = cityClean;
        lastHomeLoadFilteredByInterests = false;

        _stripInvalidMapsFromDynamicList(homePlaces);

        _sortHomePlacesByPopularInterestsThenRating(homePlaces, labels);

        notifyListeners();

        return;
      }
    }

    loading = true;
    error = null;
    lastHomeLoadFilteredByInterests = false;
    notifyListeners();

    try {
      final popularLabels = await _fetchPopularTripInterestLabels();

      final Map<String, Map<String, dynamic>> merged = {};

      final queries = [
        "top tourist attractions hotels restaurants in $cityClean",
      ];

      for (final query in queries) {
        final results = _onlyGcc(await _api.searchText(query));

        for (final item in results) {
          if (item is Map<String, dynamic>) {
            final id = item["id"]?.toString() ??
                item["name"]?.toString() ??
                item["formattedAddress"]?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString();

            merged[id] = item;
          }
        }
      }

      var list = merged.values.toList();

      _stripInvalidMapsFromDynamicList(list);

      if (interestKeys.isNotEmpty) {
        lastHomeLoadFilteredByInterests = true;

        list = list
            .whereType<Map<String, dynamic>>()
            .where(
              (item) => interestKeys.any(
                (key) => _matchesInterestKey(item, key),
              ),
            )
            .toList();

        list.sort((a, b) {
          final aRating = ((a["rating"] ?? 0) as num).toDouble();
          final bRating = ((b["rating"] ?? 0) as num).toDouble();

          return bRating.compareTo(aRating);
        });
      } else {
        _sortHomePlacesByPopularInterestsThenRating(list, popularLabels);
      }

      homePlaces = list;

      _lastLoadedHomeCity = cityClean;

      if (interestKeys.isEmpty) {
        await _writeHomeCache(cityClean, homePlaces);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TravelProvider.loadHome: $e');
      }

      error = searchFailureLocalizationKey;
      homePlaces = [];
    }

    loading = false;
    notifyListeners();
  }

  Future<List<dynamic>?> _readHomeCache(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedPrefsKey(_homeCachePrefsKey));

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

      final parsed = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return List<dynamic>.from(_stripInvalidPlaceMapsFromList(parsed));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeHomeCache(String city, List<dynamic> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _scopedPrefsKey(_homeCachePrefsKey),
        jsonEncode({
          'city': city,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'items': items,
        }),
      );
    } catch (_) {}
  }

  /// Strips heavy fields so SharedPreferences JSON stays small (avoids main-thread freezes).
  Map<String, dynamic> _slimPlaceForSearchCache(Map<String, dynamic> p) {
    final photos = p['photos'];
    List<dynamic>? slimPhotos;

    if (photos is List && photos.isNotEmpty) {
      slimPhotos = [photos.first];
    }

    return <String, dynamic>{
      if (p['id'] != null) 'id': p['id'],
      if (p['displayName'] != null) 'displayName': p['displayName'],
      if (p['formattedAddress'] != null) 'formattedAddress': p['formattedAddress'],
      if (p['rating'] != null) 'rating': p['rating'],
      if (p['userRatingCount'] != null) 'userRatingCount': p['userRatingCount'],
      'types': p['types'],
      'location': p['location'],
      if (p['priceLevel'] != null) 'priceLevel': p['priceLevel'],
      if (p['googleMapsUri'] != null) 'googleMapsUri': p['googleMapsUri'],
      if (p['editorialSummary'] != null) 'editorialSummary': p['editorialSummary'],
      if (slimPhotos != null) 'photos': slimPhotos,
    };
  }

  Future<List<dynamic>?> _readSearchResultsCache(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedPrefsKey(_searchCachePrefsKey));

      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);

      if (decoded is! Map) return null;

      final key = query.trim().toLowerCase();

      if (key.isEmpty) return null;

      final entry = decoded[key];

      if (entry is! Map) return null;

      final tsMs = entry['ts'];

      if (tsMs is! int) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );

      if (age > _searchCacheTtl) return null;

      final items = entry['items'];

      if (items is! List) return null;

      final parsed = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return List<dynamic>.from(_stripInvalidPlaceMapsFromList(parsed));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSearchResultsCache(
    String query,
    List<dynamic> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scopedKey = _scopedPrefsKey(_searchCachePrefsKey);
      final key = query.trim().toLowerCase();

      if (key.isEmpty) return;

      final slimItems = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(m))
          .take(_searchCacheMaxPlacesPerQuery)
          .map((e) => _slimPlaceForSearchCache(e))
          .toList();

      Map<String, dynamic> map = {};

      final existingRaw = prefs.getString(scopedKey);

      if (existingRaw != null && existingRaw.isNotEmpty) {
        final decoded = jsonDecode(existingRaw);

        if (decoded is Map) {
          map = Map<String, dynamic>.from(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }

      map[key] = {
        'ts': DateTime.now().millisecondsSinceEpoch,
        'items': slimItems,
      };

      while (map.length > _searchCacheMaxEntries) {
        String? oldestKey;
        int? oldestTs;

        for (final e in map.entries) {
          final m = e.value;

          if (m is! Map) continue;

          final ts = m['ts'];

          if (ts is! int) continue;

          if (oldestTs == null || ts < oldestTs) {
            oldestTs = ts;
            oldestKey = e.key;
          }
        }

        if (oldestKey == null) break;

        map.remove(oldestKey);
      }

      await prefs.setString(scopedKey, jsonEncode(map));
    } catch (_) {}
  }

  bool _matchesInterestKey(Map<String, dynamic> place, String interestKey) {
    final types = ((place["types"] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    bool hasAny(List<String> needles) {
      return needles.any((n) => types.any((t) => t.contains(n)));
    }

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

  void _clearHomeFilterSupplement() {
    _homeFilterSupplementPlaces.clear();
    _lastHomeFilterSupplementSignature = null;
    homeCategoryFallbackLoading = false;
    homeCategoryFallbackErrorKey = null;
  }

  /// Merges [homePlaces] with category supplement (deduped) for Home filter display.
  List<dynamic> homeMergedSourceForFilters() {
    if (_homeFilterSupplementPlaces.isEmpty) return homePlaces;

    final byId = <String, Map<String, dynamic>>{};

    void add(dynamic p) {
      if (p is! Map) return;

      final m = Map<String, dynamic>.from(p);

      if (InvalidPlaceText.placeMapContainsErrorLikeStrings(m)) return;

      final id = m['id']?.toString().trim();

      final key = (id != null && id.isNotEmpty)
          ? id
          : '${m['formattedAddress']?.toString() ?? ''}|${m['location']?.toString() ?? ''}';

      byId.putIfAbsent(key, () => m);
    }

    for (final p in homePlaces) {
      add(p);
    }

    for (final p in _homeFilterSupplementPlaces) {
      add(p);
    }

    return byId.values.toList();
  }

  /// Maps a Home filter chip key to a single low-cost Places text query (GCC box already in service).
  static String? placesTextQueryForHomeCategory(String filterKey, String location) {
    final loc = location.trim();

    if (loc.isEmpty) return null;

    final fk = filterKey.trim();

    switch (fk) {
      case 'filter_food_restaurants':
      case 'Food & Restaurants':
        return 'restaurants in $loc';

      case 'filter_hotels_stays':
      case 'Hotels & Stays':
        return 'hotels lodging resorts in $loc';

      case 'filter_museum':
      case 'Museum':
      case 'museum':
        return 'museums in $loc';

      case 'filter_culture_heritage':
      case 'Culture & Heritage':
        return 'museums mosques heritage landmarks cultural attractions in $loc';

      case 'filter_shopping_souvenirs':
      case 'Shopping & Souvenirs':
        return 'shopping malls souks markets souvenir stores in $loc';

      case 'filter_transportation':
      case 'Transportation':
        return 'bus stations airports train stations taxi stands car rental transport in $loc';

      default:
        if (fk.startsWith('filter_')) {
          final tail = fk.replaceFirst('filter_', '').replaceAll('_', ' ');

          return '$tail places in $loc';
        }

        return 'tourist attractions $fk in $loc';
    }
  }

  Future<void> syncHomeFilterSupplement(
    String location,
    List<String> filters, {
    String? priceSortBy,
    String? ratingSortBy,
  }) async {
    final loc = location.trim().isEmpty ? 'Oman' : location.trim();

    homeCategoryFallbackErrorKey = null;

    if (filters.isEmpty) {
      _clearHomeFilterSupplement();
      notifyListeners();

      return;
    }

    final base = filteredPlaces(
      query: '',
      filters: filters,
      maxPrice: null,
      priceSortBy: priceSortBy,
      ratingSortBy: ratingSortBy,
      sourceOverride: homePlaces,
    );

    if (base.isNotEmpty) {
      _clearHomeFilterSupplement();
      notifyListeners();

      return;
    }

    final sortedKeys = filters.map((e) => e.toLowerCase()).toList()..sort();
    final sig = '${loc.toLowerCase()}|${sortedKeys.join(',')}';

    if (sig == _lastHomeFilterSupplementSignature &&
        _homeFilterSupplementPlaces.isNotEmpty) {
      return;
    }

    final rid = ++_homeFilterSupplementRequestId;

    homeCategoryFallbackLoading = true;
    notifyListeners();

    try {
      final merged = <String, Map<String, dynamic>>{};

      for (final fk in filters) {
        final qText = placesTextQueryForHomeCategory(fk, loc);

        if (qText == null || qText.trim().isEmpty) continue;

        final cacheKey = '${loc.toLowerCase()}::${fk.toLowerCase()}';

        final List<dynamic> chunk;

        if (_homeCategoryTextSearchCache.containsKey(cacheKey)) {
          chunk = _homeCategoryTextSearchCache[cacheKey]!;
          _stripInvalidMapsFromDynamicList(chunk);
        } else {
          final raw = await _api.searchText(qText);

          chunk = _onlyGcc(raw);
          _stripInvalidMapsFromDynamicList(chunk);
          _homeCategoryTextSearchCache[cacheKey] = chunk;

          while (_homeCategoryTextSearchCache.length > _homeCategoryCacheMaxEntries) {
            _homeCategoryTextSearchCache.remove(
              _homeCategoryTextSearchCache.keys.first,
            );
          }
        }

        for (final item in chunk) {
          if (item is! Map) continue;

          final m = Map<String, dynamic>.from(item);
          final pid = m['id']?.toString().trim();
          final key = (pid != null && pid.isNotEmpty)
              ? pid
              : '${m['formattedAddress']?.toString() ?? ''}|${m['location']?.toString() ?? ''}';

          merged.putIfAbsent(key, () => m);
        }
      }

      if (rid != _homeFilterSupplementRequestId) return;

      _homeFilterSupplementPlaces = merged.values.toList();
      _stripInvalidMapsFromDynamicList(_homeFilterSupplementPlaces);
      _lastHomeFilterSupplementSignature = sig;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('syncHomeFilterSupplement: $e');
      }

      if (rid != _homeFilterSupplementRequestId) return;

      _homeFilterSupplementPlaces.clear();
      homeCategoryFallbackErrorKey = searchFailureLocalizationKey;
    } finally {
      if (rid == _homeFilterSupplementRequestId) {
        homeCategoryFallbackLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> search(String query) async {
    searchLoading = true;
    searchError = null;
    notifyListeners();

    try {
      final raw = query.trim();

      if (raw.isEmpty) {
        searchPlaces = [];
      } else {
        final qForApi = normalizePlacesSearchQuery(raw);
        final keyNorm = qForApi.toLowerCase();

        final memHit = _searchPlacesSessionCache[keyNorm];

        if (memHit != null) {
          searchPlaces = memHit.map(Map<String, dynamic>.from).toList();
          addSearchHistory(qForApi, notify: false);
        } else {
          final cached = await _readSearchResultsCache(qForApi);

          if (cached != null) {
            searchPlaces = cached;
            _rememberSearchSessionPlaces(keyNorm, searchPlaces);
            addSearchHistory(qForApi, notify: false);
          } else {
            final results = await _api.searchText(qForApi);
            searchPlaces = _onlyGcc(results);
            _rememberSearchSessionPlaces(keyNorm, searchPlaces);
            addSearchHistory(qForApi, notify: false);
            // Never block the UI thread on prefs JSON for large payloads.
            unawaited(_writeSearchResultsCache(qForApi, searchPlaces));
          }
        }

        _stripInvalidMapsFromDynamicList(searchPlaces);
      }
    } catch (e) {
      searchError = _searchFailureLocalizationKeyFor(e);
      searchPlaces = [];
    }

    searchLoading = false;
    notifyListeners();
  }

  /// Clears Search-page results without calling remote APIs.
  void clearSearchResults() {
    searchPlaces = [];
    searchError = null;
    searchLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> autocompletePlaces(String query) async {
    final q = query.trim();

    if (q.length < 2) return [];

    try {
      final results = await _api.searchText(q);

      return _onlyGcc(results)
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(m))
          .take(8)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search-page only: debounced caller should pass [sessionToken] from the page.
  /// Results are cached in memory per normalized query for the app session.
  Future<List<Map<String, dynamic>>> searchPageAutocompleteSuggestions({
    required String query,
    required String sessionToken,
    String? languageCode,
  }) async {
    final q = query.trim();

    if (q.length < 3) return [];

    final key = q.toLowerCase();

    final hit = _searchAutocompleteCache[key];

    if (hit != null) {
      return hit
          .where((row) {
            final t = row['suggestionText']?.toString() ?? '';

            return !InvalidPlaceText.isInvalid(t) &&
                !InvalidPlaceText.placeMapContainsErrorLikeStrings(row);
          })
          .toList();
    }

    try {
      final raw = await _api.autocomplete(
        input: q,
        sessionToken: sessionToken,
        languageCode: languageCode,
      );

      final dedup = <String, Map<String, dynamic>>{};

      for (final row in raw) {
        final text = row['suggestionText']?.toString().trim() ?? '';

        if (text.isEmpty) continue;

        if (InvalidPlaceText.isInvalid(text)) continue;

        final lk = text.toLowerCase();

        dedup.putIfAbsent(lk, () => Map<String, dynamic>.from(row));
      }

      final list = dedup.values.take(10).toList();

      _searchAutocompleteCache[key] = list;

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDetails(String placeId) {
    return _api.details(placeId);
  }

  void addSearchHistory(String value, {bool notify = true}) {
    final text = value.trim();

    if (text.isEmpty) return;

    if (InvalidPlaceText.isInvalid(text)) return;

    searchHistory.removeWhere(
      (item) => item.toLowerCase() == text.toLowerCase(),
    );

    searchHistory.insert(0, text);

    if (searchHistory.length > 8) {
      searchHistory = searchHistory.take(8).toList();
    }

    if (notify) notifyListeners();
  }

  void sanitizeUserFacingLists() {
    final favBefore = favoritePlaces.length;

    searchHistory.removeWhere(InvalidPlaceText.isInvalid);
    recentlyViewed.removeWhere(InvalidPlaceText.placeMapContainsErrorLikeStrings);
    favoritePlaces.removeWhere(InvalidPlaceText.placeMapContainsErrorLikeStrings);
    _stripInvalidMapsFromDynamicList(homePlaces);
    _stripInvalidMapsFromDynamicList(searchPlaces);
    _stripInvalidMapsFromDynamicList(_homeFilterSupplementPlaces);

    if (favoritePlaces.length != favBefore) {
      unawaited(_persistFavoritesPrefsOnly());
    }

    notifyListeners();
  }

  void addRecentlyViewed(Map<String, dynamic> place) {
    if (InvalidPlaceText.placeMapContainsErrorLikeStrings(place)) return;

    final title = placeName(place);

    if (InvalidPlaceText.isInvalid(title)) return;

    final currentId = place["id"]?.toString() ?? title.toLowerCase();

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

  /// Types + derived category only (used when name/address do not match).
  String _placeTypesCategoryHaystack(Map<String, dynamic> item) {
    final raw = (item['types'] as List?) ?? const [];
    final types = <String>[];
    for (final e in raw) {
      types.add(e.toString().toLowerCase());
    }
    final joined = types.join(' ');
    final cat = _categoryFromTypes(types).toLowerCase();
    return '$joined $cat';
  }

  /// [qLower] must be [query.trim().toLowerCase()] (caller normalizes once per filter pass).
  bool _placeMatchesSearchQuery(Map<String, dynamic> item, String qLower) {
    if (qLower.isEmpty) return true;

    final name = placeName(item).toLowerCase();
    if (name.contains(qLower)) return true;

    final address = placeAddress(item).toLowerCase();
    if (address.contains(qLower)) return true;

    return _placeTypesCategoryHaystack(item).contains(qLower);
  }

  List<Map<String, dynamic>> filteredPlaces({
    required String query,
    required List<String> filters,
    double? maxPrice,
    String? priceSortBy,
    String? ratingSortBy,
    /// When set (e.g. Search page), use this list instead of inferring from [searchPlaces]/[homePlaces].
    List<dynamic>? sourceOverride,
  }) {
    final List<dynamic> source;

    if (sourceOverride != null) {
      source = sourceOverride;
    } else {
      source = homePlaces;
    }

    final qLower = query.trim().toLowerCase();
    final list = <Map<String, dynamic>>[];
    for (final item in source) {
      if (item is! Map) continue;

      final Map<String, dynamic> map = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);

      if (InvalidPlaceText.placeMapContainsErrorLikeStrings(map)) continue;

      if (!_placeMatchesSearchQuery(map, qLower)) continue;

      if (filters.isNotEmpty &&
          !filters.any((f) => _matchesCategory(map, f))) {
        continue;
      }

      if (maxPrice != null && _mappedPrice(map) > maxPrice) continue;

      list.add(Map<String, dynamic>.from(map));
    }

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
        final raw = filter.trim().toLowerCase();
        final normalized = raw.replaceAll(' ', '_');

        final looksLikePlacesType = RegExp(r'^[a-z_]+$').hasMatch(normalized) &&
            !normalized.startsWith('filter_') &&
            normalized.length >= 3;

        if (looksLikePlacesType) {
          if (types.any((t) => t.contains(normalized))) return true;

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

  // ---------------------------------------------------------------------------
  // Place helpers
  // ---------------------------------------------------------------------------

  String placeName(Map<String, dynamic> place) {
    final dn = place["displayName"];

    String raw;
    if (dn is Map && dn["text"] != null) {
      raw = dn["text"].toString();
    } else if (dn is String) {
      raw = dn;
    } else {
      raw = "";
    }

    if (raw.trim().isEmpty) {
      final n = place["name"]?.toString().trim();
      if (n != null && n.isNotEmpty) {
        raw = n;
      }
    }

    if (raw.trim().isEmpty) {
      raw = "Unknown";
    }

    if (AiTripPlanMarkdownParser.looksLikeAiMarkdownBlob(raw)) {
      return AiTripPlanMarkdownParser.stripItineraryMarkdownForDisplay(raw);
    }

    if (InvalidPlaceText.isInvalid(raw)) {
      return 'Unknown';
    }

    return raw;
  }

  String placeAddress(Map<String, dynamic> place) {
    final addr = place["formattedAddress"]?.toString() ?? "";

    if (InvalidPlaceText.isInvalid(addr)) {
      return "";
    }

    return addr;
  }

  String placeDescription(Map<String, dynamic> place) {
    final editorial = place["editorialSummary"];

    if (editorial is Map && editorial["text"] != null) {
      final text = editorial["text"].toString().trim();

      if (text.isNotEmpty && !InvalidPlaceText.isInvalid(text)) return text;
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

  /// Normalized governorate / admin-area key for same-day GCC rules (Oman-focused fallbacks).
  String _governorateComparableKey(Map<String, dynamic> place) {
    final stored = place['governorateKey']?.toString().trim();

    if (stored != null && stored.isNotEmpty) {
      return _normalizeGovernorateComparable(stored);
    }

    final fromComponents = _adminAreaLevel1FromAddressComponents(place['addressComponents']);

    if (fromComponents.isNotEmpty) {
      return _normalizeGovernorateComparable(fromComponents);
    }

    final addr = placeAddress(place);
    final fromAddr = _governorateFromFreeformAddress(addr);

    if (fromAddr.isNotEmpty) return fromAddr;

    final city = _extractCity(addr);
    var key = _omanLocalityToGovernorateKey(city);

    if (key.isNotEmpty) return key;

    key = _omanGovernorateFromAddressSegments(addr);

    if (key.isNotEmpty) return key;

    key = _omanLocalityToGovernorateKey(placeName(place));

    return key;
  }

  String _normalizeGovernorateComparable(String raw) {
    var s = raw.toLowerCase().trim();

    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(' governorate', '');
    s = s.replaceAll('muḥāfaẓat', 'muhafazat');
    s = s.replaceAll(RegExp(r'^محافظة\s*'), '');
    s = s.replaceAll(RegExp(r'\s+'), '_');

    return s;
  }

  String _adminAreaLevel1FromAddressComponents(dynamic raw) {
    if (raw is! List) return '';

    for (final item in raw) {
      if (item is! Map) continue;

      final types = item['types'];

      if (types is! List) continue;

      final typeStrs = types.map((e) => e.toString()).toList();

      if (!typeStrs.contains('administrative_area_level_1')) continue;

      final lt = item['longText']?.toString() ?? item['long_name']?.toString();
      final st = item['shortText']?.toString() ?? item['short_name']?.toString();

      if (lt != null && lt.trim().isNotEmpty) return lt.trim();

      if (st != null && st.trim().isNotEmpty) return st.trim();
    }

    return '';
  }

  static const Map<String, String> _omanGovernoratePhraseKeys = {
    'ash sharqiyah north governorate': 'ash_sharqiyah_north',
    'ash sharqiyah south governorate': 'ash_sharqiyah_south',
    'al batinah north governorate': 'al_batinah_north',
    'al batinah south governorate': 'al_batinah_south',
    'ad dakhiliyah governorate': 'ad_dakhiliyah',
    'adh dakhiliyah governorate': 'ad_dakhiliyah',
    'ad dhahirah governorate': 'ad_dhahirah',
    'adh dhahirah governorate': 'ad_dhahirah',
    'al buraimi governorate': 'al_buraimi',
    'al wusta governorate': 'al_wusta',
    'musandam governorate': 'musandam',
    'dhofar governorate': 'dhofar',
    'muscat governorate': 'muscat',
    'محافظة شمال الشرقية': 'ash_sharqiyah_north',
    'محافظة جنوب الشرقية': 'ash_sharqiyah_south',
    'محافظة شمال الباطنة': 'al_batinah_north',
    'محافظة جنوب الباطنة': 'al_batinah_south',
    'محافظة الداخلية': 'ad_dakhiliyah',
    'محافظة الظاهرة': 'ad_dhahirah',
    'محافظة البريمي': 'al_buraimi',
    'محافظة الوسطى': 'al_wusta',
    'محافظة مسندم': 'musandam',
    'محافظة ظفار': 'dhofar',
    'محافظة مسقط': 'muscat',
  };

  String _governorateFromFreeformAddress(String address) {
    if (address.isEmpty) return '';

    final lower = address.toLowerCase();
    final keys = _omanGovernoratePhraseKeys.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final phrase in keys) {
      final isAscii = phrase.isNotEmpty && phrase.codeUnitAt(0) < 128;
      final hit = isAscii ? lower.contains(phrase) : address.contains(phrase);

      if (hit) return _omanGovernoratePhraseKeys[phrase]!;
    }

    return '';
  }

  static const Map<String, String> _omanLocalityGovernorateKeys = {
    'seeb': 'muscat',
    'as sib': 'muscat',
    'sib': 'muscat',
    'al seeb': 'muscat',
    'muscat': 'muscat',
    'muttrah': 'muscat',
    'matrah': 'muscat',
    'qurum': 'muscat',
    'al qurum': 'muscat',
    'ruwi': 'muscat',
    'bawshar': 'muscat',
    'al amerat': 'muscat',
    'al aziba': 'muscat',
    'al khuwair': 'muscat',
    'ghubrah': 'muscat',
    'ghala': 'muscat',
    'al rusayl': 'muscat',
    'madinat as sultan qaboos': 'muscat',
    'al mouj': 'muscat',
    'almouj': 'muscat',
    'nizwa': 'ad_dakhiliyah',
    'bahla': 'ad_dakhiliyah',
    'adam': 'ad_dakhiliyah',
    'manah': 'ad_dakhiliyah',
    'al hamra': 'ad_dakhiliyah',
    'izki': 'ad_dakhiliyah',
    'bidbid': 'ad_dakhiliyah',
    'samail': 'ad_dakhiliyah',
    'sohar': 'al_batinah_north',
    'shinas': 'al_batinah_north',
    'liwa': 'al_batinah_north',
    'saham': 'al_batinah_north',
    'al khaburah': 'al_batinah_north',
    'suwaiq': 'al_batinah_north',
    'al awabi': 'al_batinah_south',
    'nakhal': 'al_batinah_south',
    'wadi al maawil': 'al_batinah_south',
    'rustaq': 'al_batinah_south',
    'barka': 'al_batinah_south',
    'al musannah': 'al_batinah_south',
    'ibra': 'ash_sharqiyah_north',
    'bidiyah': 'ash_sharqiyah_north',
    'al mudaybi': 'ash_sharqiyah_north',
    'wadi bani khalid': 'ash_sharqiyah_north',
    'sur': 'ash_sharqiyah_south',
    'al kamil wal wafi': 'ash_sharqiyah_south',
    'jalan': 'ash_sharqiyah_south',
    'masirah': 'ash_sharqiyah_south',
    'salalah': 'dhofar',
    'taqah': 'dhofar',
    'mirbat': 'dhofar',
    'rakhyut': 'dhofar',
    'thumrait': 'dhofar',
    'sadh': 'dhofar',
    'mughsayl': 'dhofar',
    'dibba': 'musandam',
    'khasab': 'musandam',
    'bukha': 'musandam',
    'haima': 'al_wusta',
    'duqm': 'al_wusta',
    'mahout': 'al_wusta',
    'al jazer': 'al_wusta',
    'ibri': 'ad_dhahirah',
    'yanqul': 'ad_dhahirah',
    'dhank': 'ad_dhahirah',
    'al buraimi': 'al_buraimi',
    'mahdah': 'al_buraimi',
    'as sunaynah': 'al_buraimi',
  };

  String _omanLocalityToGovernorateKey(String raw) {
    if (raw.isEmpty) return '';

    final k = raw.toLowerCase().trim();

    return _omanLocalityGovernorateKeys[k] ?? '';
  }

  String _omanGovernorateFromAddressSegments(String address) {
    if (address.isEmpty) return '';

    for (final seg in address.split(',')) {
      final g = _omanLocalityToGovernorateKey(seg.trim());

      if (g.isNotEmpty) return g;
    }

    return '';
  }

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

  String placePriceDisplayText(Map<String, dynamic> place) {
    if (isHotel(place)) return placeHotelPricePerNight(place);
    if (isRestaurant(place)) return placePriceLevel(place);

    return "";
  }

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

}
