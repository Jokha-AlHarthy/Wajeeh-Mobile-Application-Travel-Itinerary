import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes a picked image as JPEG Base64 for Firestore (no Firebase Storage).
class ProfileImageCodec {
  static const int _maxBytes = 700000;

  static Future<String?> encodeFile(
    File file, {
    int maxDimension = 512,
    int quality = 72,
  }) async {
    final bytes = await file.readAsBytes();
    return encodeBytes(bytes, maxDimension: maxDimension, quality: quality);
  }

  static Future<String?> encodeBytes(
    List<int> bytes, {
    int maxDimension = 512,
    int quality = 72,
  }) async {
    var decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;

    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
      );
    }

    var q = quality;
    List<int> jpg;
    do {
      jpg = img.encodeJpg(decoded, quality: q);
      if (jpg.length <= _maxBytes || q <= 40) break;
      q -= 10;
    } while (q >= 40);

    if (jpg.isEmpty) return null;
    return base64Encode(jpg);
  }
}
