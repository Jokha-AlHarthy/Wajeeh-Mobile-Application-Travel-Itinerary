import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../constants/place_category_options.dart';
import '../utils/invalid_place_text.dart';
import 'DisplayResultScreen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

/// GCC-only quick chips when there is no personal search history (never uses Home data).
const List<String> _defaultGccSearchChips = [
  'Dubai',
  'Abu Dhabi',
  'Muscat',
  'Riyadh',
  'Jeddah',
  'Doha',
  'Manama',
  'Kuwait City',
];

/// Static GCC highlights for Search-page placeholders (not tied to Home recommendations).
final List<Map<String, dynamic>> _popularGccSpotlightPlaces = [
  {
    'displayName': {'text': 'Burj Khalifa'},
    'formattedAddress': 'Dubai, United Arab Emirates',
    'location': {'latitude': 25.1972, 'longitude': 55.2744},
    'types': ['tourist_attraction'],
  },
  {
    'displayName': {'text': 'Sultan Qaboos Grand Mosque'},
    'formattedAddress': 'Muscat, Oman',
    'location': {'latitude': 23.5852, 'longitude': 58.3891},
    'types': ['mosque'],
  },
  {
    'displayName': {'text': 'National Museum of Qatar'},
    'formattedAddress': 'Doha, Qatar',
    'location': {'latitude': 25.2867, 'longitude': 51.5333},
    'types': ['museum'],
  },
  {
    'displayName': {'text': 'Al Faisaliah Tower'},
    'formattedAddress': 'Riyadh, Saudi Arabia',
    'location': {'latitude': 24.6904, 'longitude': 46.6853},
    'types': ['tourist_attraction'],
  },
  {
    'displayName': {'text': 'Bahrain Fort'},
    'formattedAddress': 'Karana, Bahrain',
    'location': {'latitude': 26.2333, 'longitude': 50.5167},
    'types': ['tourist_attraction'],
  },
  {
    'displayName': {'text': 'Kuwait Towers'},
    'formattedAddress': 'Kuwait City, Kuwait',
    'location': {'latitude': 29.3891, 'longitude': 48.0044},
    'types': ['tourist_attraction'],
  },
];

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _filterDebounce;
  Timer? _autocompleteDebounce;
  Timer? _notificationTimer;

  List<String> selectedFilters = [];

  /// Last query we ran against the API (lowercase). Avoids mixing home list + search text.
  String _lastSubmittedQueryKey = '';

  /// Avoid re-running [TravelProvider.filteredPlaces] on every rebuild (e.g. while scrolling).
  int? _placesMemoKey;
  List<Map<String, dynamic>> _placesMemoList = const [];

  List<Map<String, dynamic>> _autocompleteRows = [];
  bool _autocompleteLoading = false;
  int _autocompleteRequestId = 0;
  String? _autocompleteSessionToken;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TravelProvider>().sanitizeUserFacingLists();
    });

    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _autocompleteDebounce?.cancel();
    _notificationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchFieldChanged(String value) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() {});
    });

    final t = value.trim();

    if (t.isEmpty) {
      _autocompleteDebounce?.cancel();
      _autocompleteSessionToken = null;
      _lastSubmittedQueryKey = '';
      _autocompleteRequestId++;
      if (_autocompleteRows.isNotEmpty || _autocompleteLoading) {
        setState(() {
          _autocompleteRows = [];
          _autocompleteLoading = false;
        });
      }
      context.read<TravelProvider>().clearSearchResults();
      return;
    }

    if (t.length < 3) {
      _autocompleteDebounce?.cancel();
      _autocompleteSessionToken = null;
      _autocompleteRequestId++;
      if (_autocompleteRows.isNotEmpty || _autocompleteLoading) {
        setState(() {
          _autocompleteRows = [];
          _autocompleteLoading = false;
        });
      }
      return;
    }

    _autocompleteSessionToken ??=
        TravelProvider.generateAutocompleteSessionToken();

    _autocompleteDebounce?.cancel();
    _autocompleteDebounce = Timer(const Duration(milliseconds: 650), () async {
      final rq = ++_autocompleteRequestId;

      if (!mounted) return;

      setState(() => _autocompleteLoading = true);

      final travel = context.watch<TravelProvider>();
      final lang = Localizations.localeOf(context).languageCode;

      final rows = await travel.searchPageAutocompleteSuggestions(
        query: t,
        sessionToken: _autocompleteSessionToken!,
        languageCode: lang,
      );

      if (!mounted || rq != _autocompleteRequestId) return;

      setState(() {
        _autocompleteRows = rows;
        _autocompleteLoading = false;
      });
    });
  }

  Future<void> _onAutocompletePick(Map<String, dynamic> row) async {
    final text = row['suggestionText']?.toString().trim() ?? '';

    if (text.isEmpty) return;

    _autocompleteDebounce?.cancel();
    _autocompleteRows = [];
    _autocompleteSessionToken = null;
    _autocompleteLoading = false;

    _controller.text = text;
    _lastSubmittedQueryKey = text.toLowerCase();

    if (!mounted) return;
    setState(() {});

    await context.read<TravelProvider>().search(text);

    if (!mounted) return;
    setState(() {});
  }

  List<Map<String, dynamic>> _memoizedFilteredPlaces({
    required TravelProvider travel,
    required String q,
    required String qKey,
  }) {
    final List<dynamic> searchSource;
    if (q.isEmpty) {
      searchSource = const <dynamic>[];
    } else if (qKey == _lastSubmittedQueryKey) {
      searchSource = travel.searchPlaces;
    } else {
      searchSource = const <dynamic>[];
    }

    final memoKey = Object.hash(
      qKey,
      _lastSubmittedQueryKey,
      Object.hashAll(selectedFilters),
      identityHashCode(searchSource),
      searchSource.length,
    );

    if (_placesMemoKey == memoKey) return _placesMemoList;

    _placesMemoKey = memoKey;
    final filterQuery = (qKey == _lastSubmittedQueryKey && searchSource.isNotEmpty)
        ? ''
        : q;
    final raw = travel.filteredPlaces(
      query: filterQuery,
      filters: selectedFilters,
      maxPrice: null,
      sourceOverride: searchSource,
    );
    _placesMemoList = raw
        .where((m) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(m))
        .toList();
    return _placesMemoList;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final travel = context.watch<TravelProvider>();

    final q = _controller.text.trim();
    final qKey = q.toLowerCase();

    final places = _memoizedFilteredPlaces(
      travel: travel,
      q: q,
      qKey: qKey,
    );

    final waitingForSubmit =
        q.isNotEmpty && qKey != _lastSubmittedQueryKey;
    final showSearchLoading =
        travel.searchLoading && q.isNotEmpty && qKey == _lastSubmittedQueryKey;

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardFill = theme.cardTheme.color ?? theme.colorScheme.surface;

    final safeSearchHistory = travel.searchHistory
        .where((s) => !InvalidPlaceText.isInvalid(s))
        .toList();
    final safeRecentlyViewed = travel.recentlyViewed
        .where((p) => !InvalidPlaceText.placeMapContainsErrorLikeStrings(p))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 40),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications, size: 28, color: accentColor),
                  PositionedDirectional(
                    end: -1,
                    top: -2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("notifications")
                          .where(
                        "userId",
                        isEqualTo:
                        firebase_auth.FirebaseAuth.instance.currentUser?.uid,
                      )
                          .where("isRead", isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        final now = DateTime.now();

                        final count = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final scheduledAt = data["scheduledAt"];

                          if (scheduledAt == null) return true;

                          if (scheduledAt is Timestamp) {
                            return !scheduledAt.toDate().isAfter(now);
                          }

                          return true;
                        }).length;

                        if (count == 0) {
                          return const SizedBox();
                        }
                        return Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CustomScrollView(
          slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  Text(
                    context.tr(
                      'hi_user',
                      {'name': auth.fullName ?? context.tr('user')},
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.locationText != null &&
                            auth.locationText!.trim().isNotEmpty
                        ? auth.locationText!.trim()
                        : context.tr('browse_near_location_fallback'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cardFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardFill,
                        border: InputBorder.none,
                        hintText: context.tr('search_places_hint'),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: _onSearchFieldChanged,
                      onSubmitted: (value) async {
                        _filterDebounce?.cancel();
                        _autocompleteDebounce?.cancel();
                        _autocompleteRows = [];
                        _autocompleteSessionToken = null;
                        _autocompleteLoading = false;
                        final submitted = value.trim();
                        _lastSubmittedQueryKey = submitted.toLowerCase();
                        if (!mounted) return;
                        setState(() {});
                        await context.read<TravelProvider>().search(submitted);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Icon(Icons.tune, color: accentColor),
                  ),
                ],
              ),
            ),
          ),
          if (travel.searchError != null && travel.searchError!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr(travel.searchError!),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (_autocompleteLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          if (!_autocompleteLoading && _autocompleteRows.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: cardFill,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _autocompleteRows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, i) {
                      final row = _autocompleteRows[i];
                      final title =
                          row['suggestionText']?.toString() ?? '';
                      return ListTile(
                        dense: true,
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => _onAutocompletePick(row),
                      );
                    },
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Text(
              context.tr('last_search'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in safeSearchHistory)
                  GestureDetector(
                    onTap: () async {
                      _autocompleteDebounce?.cancel();
                      _autocompleteRows = [];
                      _autocompleteSessionToken = null;
                      _autocompleteLoading = false;
                      _controller.text = item;
                      _lastSubmittedQueryKey = item.trim().toLowerCase();
                      if (!mounted) return;
                      setState(() {});
                      await context.read<TravelProvider>().search(item);
                      if (!mounted) return;
                      setState(() {});
                    },
                    child: _chip(context, item),
                  ),
                if (safeSearchHistory.isEmpty)
                  for (final label in _defaultGccSearchChips.take(5))
                    GestureDetector(
                      onTap: () async {
                        _autocompleteDebounce?.cancel();
                        _autocompleteRows = [];
                        _autocompleteSessionToken = null;
                        _autocompleteLoading = false;
                        _controller.text = label;
                        _lastSubmittedQueryKey = label.trim().toLowerCase();
                        if (!mounted) return;
                        setState(() {});
                        await context.read<TravelProvider>().search(label);
                        if (!mounted) return;
                        setState(() {});
                      },
                      child: _chip(context, label),
                    ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: Text(
              context.tr('recently_viewed'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (safeRecentlyViewed.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = _popularGccSpotlightPlaces[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _placeRow(
                      context,
                      Map<String, dynamic>.from(place),
                    ),
                  );
                },
                childCount: _popularGccSpotlightPlaces.length >= 2
                    ? 2
                    : _popularGccSpotlightPlaces.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = safeRecentlyViewed[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _placeRow(context, place),
                  );
                },
                childCount: safeRecentlyViewed.length >= 3
                    ? 3
                    : safeRecentlyViewed.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Text(
              context.tr('popular_destinations'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _popularGccSpotlightPlaces.take(6).map((place) {
                  return _popularCard(
                    context,
                    Map<String, dynamic>.from(place),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Text(
              context.tr('search_results'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (q.isEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 4))
          else if (waitingForSubmit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    context.tr('search_press_enter_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          else if (showSearchLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (places.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.tr('no_places_found'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _placeRow(context, places[index]),
                    ),
                  );
                },
                childCount: places.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        List<String> tempFilters = List.from(selectedFilters);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      context.tr("filter_service"),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    context.tr("place_categories"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: placeCategoryFilterKeys.map((key) {
                      final isSelected = tempFilters.contains(key);

                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              tempFilters.remove(key);
                            } else {
                              tempFilters.add(key);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            context.tr(key),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedFilters = tempFilters;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.tr("apply_filter"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _chip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface)),
    );
  }

  Widget _placeRow(BuildContext context, Map<String, dynamic> place) {
    final travel = context.read<TravelProvider>();
    final image = travel.firstPhotoUrl(place) ??
        "https://via.placeholder.com/300x200?text=No+Image";
    final thumbPx =
        (70 * MediaQuery.devicePixelRatioOf(context)).round().clamp(70, 280);

    return GestureDetector(
      onTap: () {
        travel.addRecentlyViewed(place);
        if (_controller.text.trim().isNotEmpty) {
          travel.addSearchHistory(_controller.text.trim());
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DisplayResultScreen(place: place)),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              image,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              cacheWidth: thumbPx,
              cacheHeight: thumbPx,
              filterQuality: FilterQuality.low,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  travel.placeName(place),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  travel.placeAddress(place),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _popularCard(BuildContext context, Map<String, dynamic> place) {
    final travel = context.read<TravelProvider>();
    final image = travel.firstPhotoUrl(place) ??
        "https://via.placeholder.com/300x200?text=No+Image";

    return GestureDetector(
      onTap: () {
        travel.addRecentlyViewed(place);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DisplayResultScreen(place: place)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsetsDirectional.only(end: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 12,
              end: 12,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                icon: Icon(
                  travel.isFavorite(place)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  travel.toggleFavorite(place);
                },
              ),
            ),
            PositionedDirectional(
              bottom: 12,
              start: 12,
              end: 12,
              child: Text(
                travel.placeName(place),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
