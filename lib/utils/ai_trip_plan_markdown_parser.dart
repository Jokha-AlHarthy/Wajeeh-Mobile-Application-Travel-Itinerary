// AI itinerary markdown: display cleanup + parsing for Trips History save.

import 'package:intl/intl.dart';

/// Slot order for UI and map routes (hotel loop + five stops; no coffee slot).
const List<String> kAiStructuredCategoryKeys = [
  'hotel',
  'breakfast',
  'morning',
  'lunch',
  'afternoon',
  'dinner',
  'return',
];

const Map<String, String> _categoryTitles = {
  'hotel': 'Hotel / Stay',
  'breakfast': 'Breakfast',
  'morning': 'Morning Attraction',
  'lunch': 'Lunch',
  'afternoon': 'Afternoon Attraction',
  'dinner': 'Dinner',
  'return': 'Return',
};

bool _looksLikePriceFragment(String s) {
  final t = s.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t == 'free' || t == 'included' || t == 'not specified') return true;
  return RegExp(
    r'(omr|aed|sar|usd|bhd|kwd|qar|/night|estimated|\d)',
    caseSensitive: false,
  ).hasMatch(s);
}

String _stripSub(String s) =>
    s.replaceAll(RegExp(r'\$\d+'), '').trim();

class ParsedAiTripForSave {
  ParsedAiTripForSave({
    required this.tripName,
    required this.titleCities,
    required this.country,
    required this.start,
    required this.end,
    required this.days,
    required this.priceDisplay,
  });

  final String tripName;
  final String titleCities;
  final String country;
  final DateTime start;
  final DateTime end;
  final List<Map<String, dynamic>> days;
  final String priceDisplay;

  Map<String, dynamic> toTripMap() {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final id = now.millisecondsSinceEpoch.toString();
    final dateText = '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(end)}';
    return {
      'id': id,
      'createdAt': nowIso,
      'updatedAt': nowIso,
      'statusKey': 'on_going',
      'tripName': tripName,
      'title': titleCities,
      'country': country,
      'rating': '4.5',
      'persons': '2',
      'dateText': dateText,
      'price': priceDisplay,
      'image': '',
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'days': days,
      'source': 'ai_chat',
    };
  }
}

class AiTripPlanMarkdownParser {
  AiTripPlanMarkdownParser._();

  static bool looksLikeAiMarkdownBlob(String s) {
    if (s.length < 2) return false;
    if (s.contains('**') || s.contains('##')) return true;
    if (s.contains('•')) return true;
    if (RegExp(r'^\s*[\-*•]\s', multiLine: true).hasMatch(s)) return true;
    if (s.contains('|') && s.toLowerCase().contains('price')) return true;
    if (s.contains('*') && s.length > 40) return true;
    return false;
  }

  static String stripItineraryMarkdownForDisplay(String raw) {
    if (raw.isEmpty) return raw;
    var t = raw.replaceAll(RegExp(r'\$\d+'), '');
    t = t.replaceAll('\r\n', '\n');
    t = t.replaceAll('**', '');
    t = t.replaceAll('__', '');
    t = t.replaceAll('`', '');
    t = t.replaceAll('#', '');
    t = t.replaceAll('•', '');
    final lines = t.split('\n');
    final out = <String>[];
    for (var line in lines) {
      var s = line.trimRight();
      s = s.replaceFirst(RegExp(r'^#+\s*'), '');
      s = s.replaceFirst(RegExp(r'^\s*[\-*•]\s+'), '');
      s = s.replaceFirst(RegExp(r'^\s*\d+[\.)]\s+'), '');
      s = s.trim();
      if (s.isNotEmpty) out.add(s);
    }
    t = out.join(' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = _stripLongProseAfterBreak(t);
    return _stripSub(t).trim();
  }

  static String _stripLongProseAfterBreak(String t) {
    for (final sep in [' — ', ' – ', ' - ']) {
      final i = t.indexOf(sep);
      if (i <= 0) continue;
      final head = t.substring(0, i).trim();
      final tail = t.substring(i + sep.length).trim();
      if (tail.isEmpty) continue;
      if (_looksLikePriceFragment(tail)) return t;
      if (tail.length > 40) return head;
    }
    return t;
  }

  static (String name, String price) splitNameAndPrice(String cleaned) {
    var v = cleaned.trim();
    if (v.isEmpty) return ('', '');
    var m = RegExp(
      r'^(.+?)\s*\|\s*Price\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(v);
    if (m != null) {
      return (_stripSub(m.group(1)!.trim()), _stripSub(m.group(2)!.trim()));
    }
    m = RegExp(r'^(.+?)\s+—\s+(.+)$').firstMatch(v);
    if (m != null && _looksLikePriceFragment(m.group(2)!)) {
      return (_stripSub(m.group(1)!.trim()), _stripSub(m.group(2)!.trim()));
    }
    m = RegExp(r'^(.+?)\s+[–-]\s+(.+)$').firstMatch(v);
    if (m != null && _looksLikePriceFragment(m.group(2)!)) {
      return (_stripSub(m.group(1)!.trim()), _stripSub(m.group(2)!.trim()));
    }
    return (_stripSub(v), '');
  }

  static int slotOrderForCategoryKey(String? key) {
    if (key == null || key.isEmpty) return 999;
    final i = kAiStructuredCategoryKeys.indexOf(key);
    return i < 0 ? 500 : i;
  }

  static int _slotMinutes(String key) {
    final i = kAiStructuredCategoryKeys.indexOf(key);
    if (i < 0) return 12 * 60;
    return 8 * 60 + i * 72;
  }

  static String? _mapLabelToKey(String label) {
    final L = label.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (L.contains('hotel') && L.contains('stay')) return 'hotel';
    if (L == 'hotel') return 'hotel';
    if (L == 'breakfast') return 'breakfast';
    if (L.contains('morning') && L.contains('attraction')) return 'morning';
    if (L == 'lunch') return 'lunch';
    if (L.contains('afternoon') && L.contains('attraction')) return 'afternoon';
    if (L == 'dinner') return 'dinner';
    if (L == 'return') return 'return';
    return null;
  }

  static (String title, String price) _splitTitleAndPrice(String value) {
    var v = _stripSub(value);
    if (v.isEmpty) return ('', 'Not specified');
    var pipe = RegExp(
      r'^(.+?)\s*\|\s*Price\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(v);
    if (pipe != null) {
      return (
        _stripSub(pipe.group(1)!.trim()),
        _normalizePrice(pipe.group(2)!),
      );
    }
    pipe = RegExp(r'^(.+?)\s*\|\s*(.+)$', caseSensitive: false).firstMatch(v);
    if (pipe != null) {
      final right = pipe.group(2)!.trim();
      if (RegExp(
        r'(OMR|AED|SAR|USD|BHD|KWD|QAR|Free|Included|estimated)',
        caseSensitive: false,
      ).hasMatch(right)) {
        return (_stripSub(pipe.group(1)!.trim()), _normalizePrice(right));
      }
    }
    final dash = RegExp(r'^(.+?)\s+[—\-]\s+(.+)$').firstMatch(v);
    if (dash != null) {
      final right = dash.group(2)!.trim();
      if (RegExp(
        r'(OMR|AED|SAR|/night|Free|Included|estimated|\d)',
        caseSensitive: false,
      ).hasMatch(right)) {
        return (_stripSub(dash.group(1)!.trim()), _normalizePrice(right));
      }
    }
    return (v, 'Not specified');
  }

  static String _normalizePrice(String raw) {
    var p = _stripSub(raw);
    if (p.isEmpty) return 'Not specified';
    if (RegExp(r'^\$\d+$').hasMatch(p.trim())) return 'Not specified';
    final low = p.toLowerCase();
    if (low.contains('free')) return 'Free';
    if (low.contains('included')) return 'Included';
    if (p.length > 72) return '${p.substring(0, 69)}...';
    return p;
  }

  static List<Map<String, dynamic>> _parseDayLines(
    List<String> lines,
    String mainCity,
    String country,
    int dayNum,
    int baseId,
  ) {
    final labelRe = RegExp(
      r'^(Hotel\s*/\s*Stay|Hotel|Breakfast|Morning\s*Attraction|Lunch|Afternoon\s*Attraction|Dinner|Return)\s*:\s*(.*)$',
      caseSensitive: false,
    );
    final byKey = <String, (String, String)>{};
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      var stripped = line;
      while (stripped.startsWith('*')) {
        stripped = stripped.substring(1).trimLeft();
      }
      final m = labelRe.firstMatch(stripped);
      if (m == null) continue;
      final label = m.group(1)!;
      final value = m.group(2)?.trim() ?? '';
      final key = _mapLabelToKey(label);
      if (key == null) continue;
      var pair = _splitTitleAndPrice(value);
      var title = pair.$1;
      var price = pair.$2;
      if (title.isEmpty && value.isNotEmpty) {
        title = _stripSub(value);
        price = 'Not specified';
      }
      title = _stripSub(title);
      if (title.length > 100) title = '${title.substring(0, 97)}...';
      byKey[key] = (title, price);
    }
    final orderedKeys = <String>[];
    for (final k in kAiStructuredCategoryKeys) {
      if (byKey.containsKey(k)) orderedKeys.add(k);
    }
    for (final k in byKey.keys) {
      if (!orderedKeys.contains(k)) orderedKeys.add(k);
    }
    final places = <Map<String, dynamic>>[];
    var idx = 0;
    for (final key in orderedKeys) {
      final pair = byKey[key];
      if (pair == null) continue;
      final title = pair.$1;
      final price = pair.$2;
      if (title.isEmpty) continue;
      final section = _categoryTitles[key] ?? key;
      final addr = '$title, $mainCity, $country';
      final mins = _slotMinutes(key);
      final isHotel = key == 'hotel';
      places.add({
        'id': 'ai_${baseId}_${dayNum}_${key}_$idx',
        'displayName': {'text': title},
        'formattedAddress': addr,
        'scheduledTimeMinutes': mins,
        'itineraryCategory': section,
        'itineraryCategoryKey': key,
        'itineraryPriceLabel': price,
        'aiStructuredSlot': true,
        'hotelStayOnDay': isHotel,
        'types': <String>[isHotel ? 'lodging' : 'tourist_attraction'],
      });
      idx++;
    }
    return places;
  }

  static Map<int, List<String>> _dayLinesByNumber(String raw) {
    final byDay = <int, List<String>>{};
    final lines = raw.split('\n');
    int? currentDay;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final dm = RegExp(
        r'^#{1,6}\s*Day\s*(\d+)\s*[-–—]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line.trim());
      if (dm != null) {
        final dayNum = int.tryParse(dm.group(1) ?? '') ?? 1;
        currentDay = dayNum;
        byDay.putIfAbsent(dayNum, () => []).add(line.trim());
        continue;
      }
      final dm2 = RegExp(
        r'^#{1,6}\s*Day\s*(\d+)\s*$',
        caseSensitive: false,
      ).firstMatch(line.trim());
      if (dm2 != null) {
        final dayNum = int.tryParse(dm2.group(1) ?? '') ?? 1;
        currentDay = dayNum;
        byDay.putIfAbsent(dayNum, () => []).add(line.trim());
        continue;
      }
      final cd = currentDay;
      if (cd != null) {
        byDay.putIfAbsent(cd, () => []).add(line);
      }
    }
    return byDay;
  }

  static bool _detectStructured(String raw) {
    return RegExp(
      r'^\*{0,2}\s*(Hotel\s*/\s*Stay|Breakfast)\s*:',
      caseSensitive: false,
      multiLine: true,
    ).hasMatch(raw);
  }

  static String _inferCountry(String text) {
    final low = text.toLowerCase();
    if (low.contains('oman') || low.contains('muscat') || low.contains('salalah')) {
      return 'Oman';
    }
    if (low.contains('uae') || low.contains('dubai') || low.contains('abu dhabi')) {
      return 'United Arab Emirates';
    }
    if (low.contains('qatar') || low.contains('doha')) return 'Qatar';
    if (low.contains('bahrain')) return 'Bahrain';
    if (low.contains('kuwait')) return 'Kuwait';
    if (low.contains('saudi') || low.contains('riyadh')) return 'Saudi Arabia';
    return 'GCC';
  }

  static ParsedAiTripForSave? parseAiTripMarkdownForSave(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (!text.contains(RegExp(r'day\s*\d', caseSensitive: false))) {
      return null;
    }
    final useStructured = _detectStructured(text);
    if (!useStructured) return null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dayBlocks = _dayLinesByNumber(text);
    if (dayBlocks.isEmpty) return null;

    var numDays = dayBlocks.keys.isEmpty
        ? 1
        : dayBlocks.keys.reduce((a, b) => a > b ? a : b);
    numDays = numDays.clamp(1, 30);

    String mainCity = 'Trip';
    final day1Lines = dayBlocks[1];
    String firstHeading = '';
    if (day1Lines != null && day1Lines.isNotEmpty) {
      for (final l in day1Lines) {
        if (RegExp(r'^#+\s*Day', caseSensitive: false).hasMatch(l.trim())) {
          firstHeading = l.trim();
          break;
        }
      }
    }
    if (firstHeading.isNotEmpty) {
      final m = RegExp(
        r'^#{1,6}\s*Day\s*\d+\s*[-–—]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(firstHeading.trim());
      if (m != null) {
        final c = m.group(1)!.replaceAll('#', '').trim();
        if (c.isNotEmpty && c.length <= 80) mainCity = c;
      }
    }

    final country = _inferCountry(text);
    final baseId = today.millisecondsSinceEpoch;
    final daysOut = <Map<String, dynamic>>[];
    for (var d = 1; d <= numDays; d++) {
      final date = todayDate.add(Duration(days: d - 1));
      final lines = dayBlocks[d] ?? [];
      final places = _parseDayLines(lines, mainCity, country, d, baseId);
      daysOut.add({
        'dayNumber': d,
        'date': DateFormat('EEEE, MMMM d, y').format(date),
        'places': places,
      });
    }

    final end = todayDate.add(Duration(days: numDays - 1));
    final tripName =
        mainCity.length > 60 ? '${mainCity.substring(0, 57)}...' : mainCity;

    return ParsedAiTripForSave(
      tripName: tripName,
      titleCities: mainCity,
      country: country,
      start: todayDate,
      end: end,
      days: daysOut,
      priceDisplay: 'Estimate',
    );
  }
}
