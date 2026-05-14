import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

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
