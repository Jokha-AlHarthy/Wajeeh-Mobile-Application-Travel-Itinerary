/// Detects strings that look like Dart/network exceptions or API error bodies.
/// Used so these never appear as place titles, addresses, or list rows.
class InvalidPlaceText {
  InvalidPlaceText._();

  /// Public API — same behavior as requested `isInvalidPlaceText`.
  static bool isInvalid(String? s) {
    if (s == null) return false;
    final t = s.toLowerCase().trim();
    if (t.isEmpty) return false;

    // Very short user-facing titles are not treated as "errors" by substring rules.
    if (t.length < 4) return false;

    if (t.contains('handshakeexception')) return true;
    if (t.contains('socketexception')) return true;
    if (t.contains('timeoutexception')) return true;
    if (t.contains('timeouterror')) return true;
    if (t.contains('clientexception')) return true;
    if (t.contains('httpexception')) return true;
    if (t.contains('tlsexception')) return true;
    if (t.contains('sslhandshake')) return true;
    if (t.contains('tls handshake')) return true;
    if (t.contains('ssl handshake')) return true;
    if (t.contains('certificate verify failed')) return true;

    if (t.contains('connection terminated')) return true;
    if (t.contains('connection closed')) return true;
    if (t.contains('connection reset')) return true;
    if (t.contains('connection refused')) return true;

    if (t.contains('failed host lookup')) return true;
    if (t.contains('network is unreachable')) return true;

    if (t.contains('exception:')) return true;
    if (t.startsWith('error:')) return true;
    if (t.contains(' error:')) return true;
    if (t.contains('\nerror:')) return true;

    if (t.contains('os error:')) return true;
    if (t.contains('errno =')) return true;
    if (t.contains('errno:')) return true;

    if (t.contains('dart:io')) return true;
    if (t.contains('dart:')) return true;

    if (t.contains('http status')) return true;
    if (t.contains('statuscode:')) return true;

    if (t.contains('xmlhttp')) return true;

    return false;
  }

  /// Walks nested maps/lists (bounded depth) and returns true if any string field
  /// looks like a thrown exception or HTTP error body.
  static bool placeMapContainsErrorLikeStrings(Map<String, dynamic> place) {
    bool walk(dynamic v, int depth) {
      if (depth > 5) return false;
      if (v is String) return isInvalid(v);
      if (v is Map) {
        for (final e in v.values) {
          if (walk(e, depth + 1)) return true;
        }
      } else if (v is List) {
        for (final e in v) {
          if (walk(e, depth + 1)) return true;
        }
      }
      return false;
    }

    return walk(place, 0);
  }
}
