// ignore_for_file: avoid_print -- Verbose AI request/response logs for debugging.

import 'dart:async';
import 'dart:convert';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/ai_trip_plan_markdown_parser.dart';
import '../utils/ai_trip_save_intent.dart';

typedef AiParsedTripSaveFn = Future<bool> Function(ParsedAiTripForSave parsed);

/// Gemini-backed chat with local history, save-to-trips, and GCC itinerary rules.
class AiChatService extends ChangeNotifier {
  static const String _prefsKeyHistory = 'wajeeh_ai_chat_history_v2';

  /// Google AI Studio model id (1.5 ids are often retired; 2.x stays compatible).
  static const String _geminiModel = 'gemini-2.5-flash';

  final ChatUser me = ChatUser(id: 'user', firstName: 'You');
  final ChatUser wajeeh = ChatUser(id: 'wajeeh', firstName: 'Wajeeh');

  /// DashChat expects **newest first** ([0] = latest, near the input). Persistence uses
  /// chronological order (oldest first) and is reversed on load.
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void _prependMessage(ChatMessage m) {
    _messages.insert(0, m);
  }

  void _logMessageOrder(String tag) {
    print('AiChatService message order [$tag] (index 0 = newest for DashChat):');
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final sender = m.user.id == me.id ? 'user' : m.user.id;
      var preview = m.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (preview.length > 48) preview = '${preview.substring(0, 48)}…';
      print('  #$i $sender createdAt=${m.createdAt.toIso8601String()} text="$preview"');
    }
  }

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  String? _apiKey;
  GenerativeModel? _model;
  ChatSession? _session;

  String? _lastAssistantPlanMarkdown;
  AiParsedTripSaveFn? _onSaveParsedTrip;

  /// First display token for welcome + DashChat "me" label; locked per signed-in [User.uid].
  String? _sessionGreetingName;
  String? get sessionGreetingName => _sessionGreetingName;
  String? _identityUserId;

  bool get isConfigured =>
      _apiKey != null && _apiKey!.trim().isNotEmpty && _model != null;

  static const String _systemPrompt = '''
You are **Wajeeh**, a travel assistant for the **GCC** only: Oman, UAE, Saudi Arabia, Qatar, Kuwait, Bahrain.
Never recommend destinations outside the GCC.

ITINERARY RULES (when the user asks for a multi-day plan):
- Each calendar day has exactly **five** tourist stops between hotel start/end (not counting the hotel):
  Breakfast, Morning Attraction, Lunch, Afternoon Attraction, Dinner.
- **Hotel** is only the start and end of the day (check-in / same-night return). Do **not** count the hotel as one of the five stops.
- **Day 2+** uses the **same hotel as Day 1** unless the user explicitly asks to change hotel.
- Use realistic **estimated** GCC prices or "Free" / "Included" where appropriate.

RESPONSE FORMAT for full itineraries (mandatory — one slot per line, English labels):
- No long intro. Start with **## Day 1 - CityName**
- Each line: `Label: Place | Price: …` (no markdown bold around labels)

## Day 1 - CityName
Hotel / Stay: Hotel name or area | Price: estimated/night in local currency
Breakfast: Venue | Price: estimate
Morning Attraction: Venue | Price: estimate or Free
Lunch: Venue | Price: estimate
Afternoon Attraction: Venue | Price: estimate or Free
Dinner: Venue | Price: estimate
Return: Same hotel | Price: Included

Repeat **## Day N - City** for more days with the same inner lines (real GCC venues only; no invented coordinates).

OTHER replies: short, helpful markdown when useful.
''';

  AiChatService() {
    _messages = [];
    _historyLoadFuture = _loadChatHistory();
  }

  /// Resolves greeting name from Firebase [User.displayName] then [authProfileFullName].
  /// Stays fixed while the same [User.uid] is signed in; resets when the account changes or logs out.
  void syncChatUserIdentity({String? authProfileFullName}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != _identityUserId) {
      _identityUserId = uid;
      _sessionGreetingName = null;
      me.firstName = 'You';
      notifyListeners();
    }

    if (_sessionGreetingName != null && _sessionGreetingName!.isNotEmpty) {
      return;
    }
    if (uid == null) return;

    final firebaseName = FirebaseAuth.instance.currentUser?.displayName;
    final token = _firstTokenFromDisplayName(firebaseName) ??
        _firstTokenFromDisplayName(authProfileFullName);
    if (token == null || token.isEmpty) return;

    _sessionGreetingName = token;
    me.firstName = token;
    notifyListeners();
  }

  static String? _firstTokenFromDisplayName(String? full) {
    if (full == null) return null;
    final t = full.trim();
    if (t.isEmpty) return null;
    return t.split(RegExp(r'\s+')).first;
  }

  bool _isLegacyPersistedWelcome(ChatMessage m) {
    if (m.user.id != wajeeh.id) return false;
    final t = m.text;
    return t.contains('Marhaba! Ask me about GCC') ||
        t.contains('Say save this plan after I draft');
  }

  /// Finished before [sendText] runs so prefs cannot overwrite an in-flight send.
  late final Future<void> _historyLoadFuture;

  void bindTripSaveHandler(AiParsedTripSaveFn? onSave) {
    _onSaveParsedTrip = onSave;
    notifyListeners();
  }

  void maybeConfigureFromEnvironment() {
    const gemini = String.fromEnvironment('GEMINI_API_KEY');
    const google = String.fromEnvironment('GOOGLE_API_KEY');
    final key = gemini.isNotEmpty ? gemini : google;
    if (key.isEmpty) return;
    configure(geminiApiKey: key, openRouteServiceApiKey: null);
  }

  void configure({
    String? geminiApiKey,
    String? openRouteServiceApiKey,
  }) {
    final key = geminiApiKey?.trim();
    if (key == null || key.isEmpty) {
      if (geminiApiKey != null && geminiApiKey.trim().isEmpty) {
        debugPrint(
          'AiChatService.configure: Gemini API key is missing (empty string). '
          'Use --dart-define=GEMINI_API_KEY=your_key when running.',
        );
      }
      _apiKey = null;
      _model = null;
      _session = null;
      notifyListeners();
      return;
    }
    if (_apiKey == key && _model != null) return;

    _apiKey = key;
    try {
      _model = GenerativeModel(
        model: _geminiModel,
        apiKey: _apiKey!,
        systemInstruction: Content.system(_systemPrompt),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
        ],
        generationConfig: GenerationConfig(maxOutputTokens: 8192),
      );
      _session = _model!.startChat();
      debugPrint('AiChatService.configure: model=$_geminiModel (ready)');
    } catch (e, st) {
      debugPrint('AiChatService.configure failed: $e\n$st');
      _model = null;
      _session = null;
    }
    notifyListeners();
  }

  Future<void> _persistChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store oldest → newest for stable JSON / debugging; UI list stays newest-first.
      final list = _messages.reversed
          .map(
            (m) => <String, dynamic>{
              'text': m.text,
              'uid': m.user.id,
              'fn': m.user.firstName,
              'at': m.createdAt.toUtc().toIso8601String(),
              'md': m.isMarkdown,
            },
          )
          .toList();
      await prefs.setString(_prefsKeyHistory, jsonEncode(list));
    } catch (e) {
      debugPrint('AiChatService._persistChatHistory: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyHistory);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <ChatMessage>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final text = e['text']?.toString() ?? '';
        final uid = e['uid']?.toString() ?? 'wajeeh';
        final fn = e['fn']?.toString();
        final at = DateTime.tryParse(e['at']?.toString() ?? '')?.toLocal() ??
            DateTime.now();
        final md = e['md'] == true;
        final user = uid == me.id
            ? me
            : ChatUser(id: uid, firstName: fn ?? 'Wajeeh');
        loaded.add(
          ChatMessage(
            text: text,
            user: user,
            createdAt: at,
            isMarkdown: md,
          ),
        );
      }
      loaded.removeWhere(_isLegacyPersistedWelcome);
      if (loaded.isNotEmpty) {
        _messages = loaded.reversed.toList();
        _lastAssistantPlanMarkdown = _latestAssistantMarkdown();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AiChatService._loadChatHistory: $e');
    }
  }

  String? _latestAssistantMarkdown() {
    for (final m in _messages) {
      if (m.user.id == wajeeh.id && m.text.contains('Day')) {
        return m.text;
      }
    }
    return null;
  }

  Future<void> sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    await _historyLoadFuture;

    if (userMessageLooksLikeSaveTripIntent(text)) {
      _prependMessage(ChatMessage(text: text, user: me, createdAt: DateTime.now()));
      notifyListeners();
      await _persistChatHistory();

      final saveFn = _onSaveParsedTrip;
      if (saveFn == null) {
        _prependMessage(
          ChatMessage(
            text:
                'Saving is not available here. Open the app from the home screen and try again.',
            user: wajeeh,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();
        await _persistChatHistory();
        _logMessageOrder('after save-intent no handler');
        return;
      }

      final source = _lastAssistantPlanMarkdown ?? _latestAssistantMarkdown();
      final parsed = source != null
          ? AiTripPlanMarkdownParser.parseAiTripMarkdownForSave(source)
          : null;
      if (parsed == null) {
        _prependMessage(
          ChatMessage(
            text:
                'I could not find a structured itinerary to save. Ask me for a day-by-day GCC plan first, then try saving again.',
            user: wajeeh,
            createdAt: DateTime.now(),
            isMarkdown: false,
          ),
        );
      } else {
        final ok = await saveFn(parsed);
        _prependMessage(
          ChatMessage(
            text: ok
                ? 'Your trip has been saved to Trips History. Open My Trips from the menu to view it.'
                : 'Could not save the trip. Please try again.',
            user: wajeeh,
            createdAt: DateTime.now(),
            isMarkdown: false,
          ),
        );
      }
      notifyListeners();
      await _persistChatHistory();
      _logMessageOrder('after save-intent complete');
      return;
    }

    _prependMessage(ChatMessage(text: text, user: me, createdAt: DateTime.now()));
    notifyListeners();
    await _persistChatHistory();
    _logMessageOrder('after user send');

    if (!isConfigured || _session == null) {
      _prependMessage(
        ChatMessage(
          text:
              'Gemini API key is missing. Run the app with:\n'
              'flutter run --dart-define=GEMINI_API_KEY=your_key',
          user: wajeeh,
          createdAt: DateTime.now(),
          isMarkdown: false,
        ),
      );
      notifyListeners();
      await _persistChatHistory();
      _logMessageOrder('after missing API key reply');
      return;
    }

    _isTyping = true;
    notifyListeners();

    try {
      print('Sending message to AI: $text');
      final response = await _session!.sendMessage(Content.text(text));

      String? reply;
      try {
        reply = response.text?.trim();
      } on GenerativeAIException catch (e, st) {
        print('AI ERROR (blocked or invalid response text): $e');
        print('STACK TRACE: $st');
        reply = null;
        final detail = kDebugMode ? ' $e' : '';
        _prependMessage(
          ChatMessage(
            text:
                'Failed to generate a response. Please try again.$detail',
            user: wajeeh,
            createdAt: DateTime.now(),
            isMarkdown: false,
          ),
        );
        return;
      }

      print('AI response received: ${reply ?? '(null or empty)'}');

      final failed = reply == null || reply.isEmpty;
      final String body;
      if (failed) {
        body = 'Failed to generate a response. Please try again.';
      } else {
        body = reply;
      }
      _prependMessage(
        ChatMessage(
          text: body,
          user: wajeeh,
          createdAt: DateTime.now(),
          isMarkdown: !failed,
        ),
      );
      if (!failed &&
          body.contains(RegExp(r'day\s*\d', caseSensitive: false))) {
        _lastAssistantPlanMarkdown = body;
      }
    } catch (e, st) {
      print('AI ERROR: $e');
      print('STACK TRACE: $st');
      final detail = kDebugMode ? ' $e' : '';
      _prependMessage(
        ChatMessage(
          text:
              'Failed to generate a response. Please try again.$detail',
          user: wajeeh,
          createdAt: DateTime.now(),
          isMarkdown: false,
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
      await _persistChatHistory();
      _logMessageOrder('after AI reply (sendText finally)');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyHistory);
    } catch (_) {}
    _messages = [];
    _lastAssistantPlanMarkdown = null;
    _session = _model?.startChat();
    notifyListeners();
    await _persistChatHistory();
  }
}
