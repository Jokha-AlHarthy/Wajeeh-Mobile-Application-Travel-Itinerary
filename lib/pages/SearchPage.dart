import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import 'DisplayResultScreen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

/// Category chips only (aligned with home / trip packages).
const List<String> _placeCategoryFilterKeys = [
  'filter_culture_heritage',
  'filter_transportation',
  'filter_shopping_souvenirs',
  'filter_hotels_stays',
  'filter_food_restaurants',
];

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _filterDebounce;

  List<String> selectedFilters = [];

  /// Last query we ran against the API (lowercase). Avoids mixing home list + search text.
  String _lastSubmittedQueryKey = '';

  /// Avoid re-running [TravelProvider.filteredPlaces] on every rebuild (e.g. while scrolling).
  int? _placesMemoKey;
  List<Map<String, dynamic>> _placesMemoList = const [];

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _memoizedFilteredPlaces({
    required TravelProvider travel,
    required String q,
    required String qKey,
  }) {
    final List<dynamic> searchSource;
    if (q.isEmpty) {
      searchSource = travel.homePlaces;
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
    _placesMemoList = travel.filteredPlaces(
      query: q,
      filters: selectedFilters,
      maxPrice: null,
      sourceOverride: searchSource,
    );
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
        travel.loading && q.isNotEmpty && qKey == _lastSubmittedQueryKey;

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardFill = theme.cardTheme.color ?? theme.colorScheme.surface;

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
                    end: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "3",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    context.tr('gcc_explorer_tagline'),
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
                      onChanged: (_) {
                        _filterDebounce?.cancel();
                        _filterDebounce = Timer(
                          const Duration(milliseconds: 320),
                          () {
                            if (mounted) setState(() {});
                          },
                        );
                      },
                      onSubmitted: (value) async {
                        _filterDebounce?.cancel();
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
                for (final item in travel.searchHistory)
                  GestureDetector(
                    onTap: () async {
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
                if (travel.searchHistory.isEmpty)
                  ...travel.homePlaces
                      .take(5)
                      .map(
                        (e) => travel.placeName(e as Map<String, dynamic>),
                      )
                      .map((label) => _chip(context, label)),
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
          if (travel.recentlyViewed.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = travel.homePlaces[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _placeRow(
                      context,
                      Map<String, dynamic>.from(place as Map),
                    ),
                  );
                },
                childCount: travel.homePlaces.length >= 2 ? 2 : travel.homePlaces.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = travel.recentlyViewed[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _placeRow(context, place),
                  );
                },
                childCount: travel.recentlyViewed.length >= 3
                    ? 3
                    : travel.recentlyViewed.length,
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
                children: travel.homePlaces.take(6).map((place) {
                  return _popularCard(
                    context,
                    Map<String, dynamic>.from(place as Map),
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
          if (waitingForSubmit)
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
                    children: _placeCategoryFilterKeys.map((key) {
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
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border, size: 18),
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
