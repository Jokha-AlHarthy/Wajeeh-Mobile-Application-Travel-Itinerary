/// One Google Places review row for place detail previews.
class PlaceReviewPreview {
  final String authorName;
  final double rating;
  final String text;
  final String? authorPhotoUri;

  const PlaceReviewPreview({
    required this.authorName,
    required this.rating,
    required this.text,
    this.authorPhotoUri,
  });

  /// Parses Places API (New) JSON [Review](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places.reviews#Review).
  static PlaceReviewPreview? tryParse(Map<String, dynamic> json) {
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;

    final textObj = json['text'];
    var body = '';
    if (textObj is Map) {
      body = textObj['text']?.toString() ?? '';
    } else if (textObj is String) {
      body = textObj;
    }

    final author = json['authorAttribution'] ?? json['author_attribution'];
    var name = '';
    String? photoUri;
    if (author is Map) {
      name = author['displayName']?.toString() ??
          author['display_name']?.toString() ??
          '';
      photoUri = author['photoUri']?.toString() ??
          author['photo_uri']?.toString();
    }
    if (name.isEmpty) {
      name = json['authorName']?.toString() ??
          json['author_name']?.toString() ??
          '';
    }
    if (name.isEmpty) name = '—';

    if (body.trim().isEmpty && rating <= 0) return null;

    return PlaceReviewPreview(
      authorName: name,
      rating: rating,
      text: body.trim(),
      authorPhotoUri: photoUri,
    );
  }
}
