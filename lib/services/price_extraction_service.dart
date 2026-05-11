import 'dart:convert';

/// Price extraction and estimation assistant for tourist places.
/// Handles API place data with explicit prices, price levels, or unknown cases.
class PriceExtractionService {
  static const String _defaultCurrency = 'OMR';

  /// Extracts or estimates price from place data.
  /// Returns a Map suitable for JSON serialization.
  static Map<String, dynamic> extractPrice(Map<String, dynamic> place) {
    final placeId = _getPlaceId(place);
    final placeName = _getPlaceName(place);

    // 1. Check for explicit numeric price in API fields
    final explicitResult = _tryExplicitPrice(place);
    if (explicitResult != null) {
      return _buildResult(
        placeId: placeId,
        placeName: placeName,
        priceType: 'exact_price',
        priceValue: explicitResult['value'],
        priceMin: null,
        priceMax: null,
        confidence: explicitResult['confidence'],
        reason: explicitResult['reason'],
        source: 'api',
      );
    }

    // 2. Try to parse price from text fields (description, editorialSummary, etc.)
    final textResult = _tryParsePriceFromText(place);
    if (textResult != null) {
      return _buildResult(
        placeId: placeId,
        placeName: placeName,
        priceType: textResult['isRange'] == true ? 'estimated_price' : 'exact_price',
        priceValue: textResult['value'],
        priceMin: textResult['min'],
        priceMax: textResult['max'],
        confidence: textResult['confidence'],
        reason: textResult['reason'],
        source: 'inferred',
      );
    }

    // 3. Use priceLevel for estimated range (only if confidence is sufficient)
    const minConfidenceForEstimate = 0.6;
    final priceLevel = place['priceLevel']?.toString() ?? '';
    if (priceLevel.isNotEmpty && priceLevel != 'PRICE_LEVEL_UNSPECIFIED') {
      final levelResult = _estimateFromPriceLevel(priceLevel, place);
      if (levelResult != null &&
          (levelResult['confidence'] as double) >= minConfidenceForEstimate) {
        return _buildResult(
          placeId: placeId,
          placeName: placeName,
          priceType: 'estimated_price',
          priceValue: null,
          priceMin: levelResult['min'],
          priceMax: levelResult['max'],
          confidence: levelResult['confidence'],
          reason: levelResult['reason'],
          source: 'api',
        );
      }
    }

    // 4. Fallback: estimate from place type when we have types (hotel, restaurant, etc.)
    final typeResult = _estimateFromPlaceType(place);
    if (typeResult != null) {
      return _buildResult(
        placeId: placeId,
        placeName: placeName,
        priceType: 'estimated_price',
        priceValue: null,
        priceMin: typeResult['min'],
        priceMax: typeResult['max'],
        confidence: typeResult['confidence'],
        reason: typeResult['reason'],
        source: 'inferred',
      );
    }

    // 5. Not enough information
    return _buildResult(
      placeId: placeId,
      placeName: placeName,
      priceType: 'unknown',
      priceValue: null,
      priceMin: null,
      priceMax: null,
      confidence: 0.0,
      reason: 'No explicit price or price level in API response.',
      source: 'api',
    );
  }

  /// Conservative estimate from place type when priceLevel is missing.
  static Map<String, dynamic>? _estimateFromPlaceType(Map<String, dynamic> place) {
    final types = ((place['types'] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    if (types.isEmpty) return null;

    double min;
    double max;
    String category;

    if (types.any((t) => t.contains('hotel') || t.contains('lodging') || t.contains('resort') || t.contains('guest_house'))) {
      // Vary hotel estimate by rating and type (avoids all showing same price)
      final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
      final isResort = types.any((t) => t.contains('resort'));
      if (isResort) {
        min = 80;
        max = 200;
      } else if (rating >= 4.5) {
        min = 60;
        max = 120;
      } else if (rating >= 4.0) {
        min = 40;
        max = 85;
      } else if (rating >= 3.5) {
        min = 25;
        max = 55;
      } else {
        min = 18;
        max = 45;
      }
      category = 'accommodation (per night)';
    } else if (types.any((t) => t.contains('restaurant') || t.contains('food') || t.contains('cafe') || t.contains('meal'))) {
      min = 3;
      max = 25;
      category = 'dining (per person)';
    } else if (types.any((t) => t.contains('museum') || t.contains('tourist_attraction') || t.contains('landmark'))) {
      min = 0;
      max = 15;
      category = 'attraction';
    } else if (types.any((t) => t.contains('shopping_mall') || t.contains('store') || t.contains('market'))) {
      min = 5;
      max = 50;
      category = 'shopping';
    } else if (types.any((t) => t.contains('airport') || t.contains('transit') || t.contains('bus_station') || t.contains('train_station'))) {
      min = 0;
      max = 30;
      category = 'transit';
    } else {
      min = 5;
      max = 40;
      category = 'general visit';
    }

    return {
      'min': min,
      'max': max,
      'confidence': 0.55,
      'reason': 'Estimated from place type ($category). Price may vary.',
    };
  }

  /// Returns the result as a JSON string.
  static String extractPriceJson(Map<String, dynamic> place) {
    return jsonEncode(extractPrice(place));
  }

  static String _getPlaceId(Map<String, dynamic> place) {
    final id = place['id'];
    if (id != null) return id.toString();
    final name = place['name'];
    if (name != null) return name.toString();
    return '';
  }

  static String _getPlaceName(Map<String, dynamic> place) {
    final dn = place['displayName'];
    if (dn is Map && dn['text'] != null) return dn['text'].toString();
    if (dn is String) return dn;
    return place['displayName']?.toString() ?? 'Unknown';
  }

  static Map<String, dynamic>? _tryExplicitPrice(Map<String, dynamic> place) {
    // Check known API fields that might contain explicit price
    final priceFields = ['price', 'priceValue', 'admissionFee', 'currencyAmount'];
    for (final key in priceFields) {
      final val = place[key];
      if (val == null) continue;

      if (val is num) {
        final v = val.toDouble();
        if (v >= 0) {
          return {
            'value': v,
            'confidence': 1.0,
            'reason': 'Explicit price found in API field "$key".',
          };
        }
      }
      if (val is Map) {
        final amount = val['units'] ?? val['nanos'] ?? val['value'] ?? val['amount'];
        if (amount is num) {
          final v = amount.toDouble();
          if (v >= 0) {
            return {
              'value': v,
              'confidence': 1.0,
              'reason': 'Explicit price found in API field "$key".',
            };
          }
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _tryParsePriceFromText(Map<String, dynamic> place) {
    final texts = <String>[];
    _addText(texts, place['editorialSummary']);
    _addText(texts, place['displayName']);
    _addText(texts, place['description']);
    final combined = texts.join(' ');

    if (combined.isEmpty) return null;

    // OMR patterns: "OMR 5", "5 OMR", "OMR 10-20", "10-20 OMR", "OMR 5.5"
    final omrPattern = RegExp(
      r'(?:OMR|ر\.ع\.?)\s*(\d+(?:\.\d+)?)\s*(?:-|to|–)\s*(\d+(?:\.\d+)?)|'
      r'(?:OMR|ر\.ع\.?)\s*(\d+(?:\.\d+)?)|'
      r'(\d+(?:\.\d+)?)\s*(?:OMR|ر\.ع\.?)',
      caseSensitive: false,
    );

    final matches = omrPattern.allMatches(combined);
    if (matches.isEmpty) return null;

    double? minVal;
    double? maxVal;
    double? singleVal;

    for (final m in matches) {
      if (m.group(1) != null && m.group(2) != null) {
        // Range: OMR 10-20
        final a = double.tryParse(m.group(1)!) ?? 0;
        final b = double.tryParse(m.group(2)!) ?? 0;
        if (a >= 0 && b >= 0) {
          minVal = minVal == null ? (a < b ? a : b) : (minVal < (a < b ? a : b) ? minVal : (a < b ? a : b));
          maxVal = maxVal == null ? (a > b ? a : b) : (maxVal > (a > b ? a : b) ? maxVal : (a > b ? a : b));
        }
      } else if (m.group(3) != null) {
        final v = double.tryParse(m.group(3)!);
        if (v != null && v >= 0) {
          singleVal = v;
          minVal = minVal == null ? v : (minVal < v ? minVal : v);
          maxVal = maxVal == null ? v : (maxVal > v ? maxVal : v);
        }
      } else if (m.group(4) != null) {
        final v = double.tryParse(m.group(4)!);
        if (v != null && v >= 0) {
          singleVal = v;
          minVal = minVal == null ? v : (minVal < v ? minVal : v);
          maxVal = maxVal == null ? v : (maxVal > v ? maxVal : v);
        }
      }
    }

    if (minVal == null && maxVal == null && singleVal == null) return null;

    final isRange = (minVal != null && maxVal != null && (maxVal - minVal).abs() > 0.01) ||
        (minVal != null && maxVal == null && singleVal != null && (singleVal - minVal).abs() > 0.01);

    return {
      'value': singleVal ?? (minVal != null && maxVal != null ? (minVal + maxVal) / 2 : minVal ?? maxVal),
      'min': minVal,
      'max': maxVal,
      'isRange': isRange,
      'confidence': 0.75,
      'reason': 'Price parsed from description or editorial summary text.',
    };
  }

  static void _addText(List<String> out, dynamic val) {
    if (val == null) return;
    if (val is Map && val['text'] != null) {
      out.add(val['text'].toString());
    } else if (val is String) {
      out.add(val);
    }
  }

  static Map<String, dynamic>? _estimateFromPriceLevel(String priceLevel, Map<String, dynamic> place) {
    final types = ((place['types'] as List?) ?? []).map((e) => e.toString().toLowerCase()).toList();
    final isHotel = types.any((t) => t.contains('hotel') || t.contains('lodging') || t.contains('resort') || t.contains('guest_house'));

    // Hotel-specific OMR ranges per night (GCC region)
    if (isHotel) {
      double min;
      double max;
      double confidence;
      String reason;
      switch (priceLevel) {
        case 'PRICE_LEVEL_FREE':
          min = 0;
          max = 0;
          confidence = 0.9;
          reason = 'Free accommodation.';
          break;
        case 'PRICE_LEVEL_INEXPENSIVE':
          min = 15;
          max = 35;
          confidence = 0.75;
          reason = 'Budget hotel (per night).';
          break;
        case 'PRICE_LEVEL_MODERATE':
          min = 35;
          max = 70;
          confidence = 0.7;
          reason = 'Standard hotel (per night).';
          break;
        case 'PRICE_LEVEL_EXPENSIVE':
          min = 70;
          max = 130;
          confidence = 0.65;
          reason = 'Premium hotel (per night).';
          break;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          min = 130;
          max = 300;
          confidence = 0.6;
          reason = 'Luxury hotel (per night).';
          break;
        default:
          return null;
      }
      return {'min': min, 'max': max, 'confidence': confidence, 'reason': reason};
    }

    // Non-hotel: per person/visit or per meal
    double min;
    double max;
    double confidence;
    String reason;
    switch (priceLevel) {
      case 'PRICE_LEVEL_FREE':
        min = 0;
        max = 0;
        confidence = 0.9;
        reason = 'Price level indicates free entry.';
        break;
      case 'PRICE_LEVEL_INEXPENSIVE':
        min = 1;
        max = 10;
        confidence = 0.7;
        reason = 'Estimated from PRICE_LEVEL_INEXPENSIVE (budget-friendly).';
        break;
      case 'PRICE_LEVEL_MODERATE':
        min = 10;
        max = 30;
        confidence = 0.65;
        reason = 'Estimated from PRICE_LEVEL_MODERATE (standard pricing).';
        break;
      case 'PRICE_LEVEL_EXPENSIVE':
        min = 30;
        max = 80;
        confidence = 0.6;
        reason = 'Estimated from PRICE_LEVEL_EXPENSIVE (premium pricing).';
        break;
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        min = 60;
        max = 200;
        confidence = 0.55;
        reason = 'Estimated from PRICE_LEVEL_VERY_EXPENSIVE (luxury pricing).';
        break;
      default:
        return null;
    }

    if (types.any((t) => t.contains('restaurant') || t.contains('food') || t.contains('cafe'))) {
      reason += ' Per person/meal.';
    } else if (types.any((t) => t.contains('airport') || t.contains('transit'))) {
      confidence = 0.45;
      reason += ' Transit/airport pricing varies widely.';
    }

    return {'min': min, 'max': max, 'confidence': confidence, 'reason': reason.trim()};
  }

  static Map<String, dynamic> _buildResult({
    required String placeId,
    required String placeName,
    required String priceType,
    required double? priceValue,
    required double? priceMin,
    required double? priceMax,
    required double confidence,
    required String reason,
    required String source,
  }) {
    return {
      'place_id': placeId,
      'place_name': placeName,
      'currency': _defaultCurrency,
      'price_type': priceType,
      'price_value': priceValue,
      'price_min': priceMin,
      'price_max': priceMax,
      'confidence': confidence,
      'reason': reason,
      'source': source,
    };
  }
}
