import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  /// CLDR region codes for GCC (Places Autocomplete `includedRegionCodes`).
  static const gccRegionCodes = <String>['OM', 'AE', 'SA', 'QA', 'BH', 'KW'];

  static const _gccLowLat = 16.0;
  static const _gccLowLng = 34.0;
  static const _gccHighLat = 33.5;
  static const _gccHighLng = 60.5;

  Future<List<dynamic>> searchText(String query) async {
    final url = Uri.parse("https://places.googleapis.com/v1/places:searchText");

    final body = <String, dynamic>{
      "textQuery": query,
      "pageSize": 20,
      "locationRestriction": {
        "rectangle": {
          "low": {"latitude": _gccLowLat, "longitude": _gccLowLng},
          "high": {"latitude": _gccHighLat, "longitude": _gccHighLng},
        }
      }
    };

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
        "places.id,places.displayName,places.formattedAddress,places.addressComponents,places.rating,places.userRatingCount,places.photos,places.location,places.types,places.priceLevel,places.googleMapsUri,places.editorialSummary",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body);
    return (data["places"] as List? ?? []);
  }

  /// Places API (New) autocomplete — restricted to GCC via [includedRegionCodes].
  ///
  /// [sessionToken] should stay stable for one typing session (see Google billing docs).
  Future<List<Map<String, dynamic>>> autocomplete({
    required String input,
    required String sessionToken,
    String? languageCode,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');

    final body = <String, dynamic>{
      'input': trimmed,
      'sessionToken': sessionToken,
      'includedRegionCodes': gccRegionCodes,
      'includeQueryPredictions': true,
      if (languageCode != null && languageCode.isNotEmpty)
        'languageCode': languageCode,
    };

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': [
          'suggestions.placePrediction.placeId',
          'suggestions.placePrediction.text',
          'suggestions.placePrediction.structuredFormat',
          'suggestions.queryPrediction.text',
          'suggestions.queryPrediction.structuredFormat',
        ].join(','),
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List? ?? [];
    final out = <Map<String, dynamic>>[];

    String? textFromFormattable(dynamic ft) {
      if (ft is! Map) return null;
      final t = ft['text'];
      return t?.toString();
    }

    for (final s in suggestions) {
      if (s is! Map<String, dynamic>) continue;
      final placePred = s['placePrediction'];
      if (placePred is Map<String, dynamic>) {
        final main = textFromFormattable(placePred['structuredFormat']?['mainText']);
        final secondary =
            textFromFormattable(placePred['structuredFormat']?['secondaryText']);
        final full = textFromFormattable(placePred['text']) ??
            [main, secondary].whereType<String>().where((e) => e.isNotEmpty).join(', ');
        if (full.isEmpty) continue;
        out.add({
          'suggestionText': full,
          if (main != null && main.isNotEmpty) 'mainText': main,
          if (secondary != null && secondary.isNotEmpty) 'secondaryText': secondary,
          'placeId': placePred['placeId']?.toString() ?? '',
        });
        continue;
      }
      final queryPred = s['queryPrediction'];
      if (queryPred is Map<String, dynamic>) {
        final full = textFromFormattable(queryPred['text']);
        if (full == null || full.isEmpty) continue;
        final main = textFromFormattable(queryPred['structuredFormat']?['mainText']);
        final secondary =
            textFromFormattable(queryPred['structuredFormat']?['secondaryText']);
        out.add({
          'suggestionText': full,
          if (main != null && main.isNotEmpty) 'mainText': main,
          if (secondary != null && secondary.isNotEmpty) 'secondaryText': secondary,
          'placeId': '',
        });
      }
    }

    return out;
  }

  Future<Map<String, dynamic>> details(String placeId) async {
    final url = Uri.parse("https://places.googleapis.com/v1/places/$placeId");

    final res = await http.get(
      url,
      headers: {
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
        "id,displayName,formattedAddress,addressComponents,rating,userRatingCount,location,photos,editorialSummary,websiteUri,types,priceLevel,googleMapsUri,reviews",
      },
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String photoUrl(String photoName, {int maxWidth = 400}) {
    return "https://places.googleapis.com/v1/$photoName/media?maxWidthPx=$maxWidth&key=$apiKey";
  }
}
