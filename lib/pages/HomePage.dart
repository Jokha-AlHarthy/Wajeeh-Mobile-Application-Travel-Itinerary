import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import 'package:wajeeh/widgets/place_list_card.dart';
import 'SearchPage.dart';
import '../constants/place_category_options.dart';
import '../services/itinerary_walkthrough.dart';
import 'my_preference_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  List<String> filterOptions = [];

  List<String> selectedFilters = [];
  String? priceSortBy;
  String? ratingSortBy;

  final _firstPlaceArrowKey = GlobalKey();

  bool _homeLoadScheduledForFrame = false;

  /// Last home city we already requested [TravelProvider.loadHome] for (avoids duplicate calls on unrelated rebuilds).
  String? _lastHomeCitySentToProvider;

  bool _preferencePromptChecked = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().loadUserProfile();
      await _loadFiltersOnce();
      if (!mounted) return;
      setState(() {});
      _maybeShowPreferencePrompt();
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadFiltersOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content')
          .doc('data')
          .collection('filters')
          .get();
      if (!mounted) return;
      final loaded = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        filterOptions = loaded.isNotEmpty
            ? loaded
            : List<String>.from(placeCategoryFilterKeys);
      });
    } catch (_) {
      if (!mounted) return;
      if (filterOptions.isEmpty) {
        setState(() {
          filterOptions = List<String>.from(placeCategoryFilterKeys);
        });
      }
    }
  }

  Future<void> _maybeShowPreferencePrompt() async {
    if (_preferencePromptChecked || !mounted) return;
    _preferencePromptChecked = true;

    final auth = context.read<AuthProvider>();
    if (auth.isAdmin || !auth.shouldShowPreferencePrompt) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.tr('preferences')),
          content: Text(dialogContext.tr('preference_prompt_message')),
          actions: [
            TextButton(
              onPressed: () async {
                await auth.markPreferencePromptSkipped();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(dialogContext.tr('skip_for_now')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyPreferencePage(),
                  ),
                );
              },
              child: Text(dialogContext.tr('set_preferences')),
            ),
          ],
        );
      },
    );
  }

  void _loadPlaces() {
    final auth = context.read<AuthProvider>();
    final loc = auth.locationText?.trim();
    final city = (loc == null || loc.isEmpty) ? 'Oman' : loc;
    _lastHomeCitySentToProvider = city;
    context.read<TravelProvider>().loadHome(city, forceRefresh: true);
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      context.tr('filter_service'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    context.tr('popular_filters'),
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
                    children: filterOptions.map((key) {
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
                  const SizedBox(height: 20),
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
                      onPressed: () async {
                        final travel = context.read<TravelProvider>();
                        final auth = context.read<AuthProvider>();
                        setState(() {
                          selectedFilters = tempFilters;
                        });
                        Navigator.pop(context);
                        final loc = auth.locationText?.trim();
                        final city =
                            (loc == null || loc.isEmpty) ? 'Oman' : loc;
                        await travel.syncHomeFilterSupplement(
                          city,
                          selectedFilters,
                          priceSortBy: priceSortBy,
                          ratingSortBy: ratingSortBy,
                        );
                      },
                      child: Text(
                        context.tr('apply_filter'),
                        style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final travel = context.watch<TravelProvider>();
    final theme = Theme.of(context);

    if (!_homeLoadScheduledForFrame) {
      _homeLoadScheduledForFrame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homeLoadScheduledForFrame = false;
        if (!mounted) return;
        final loc = context.read<AuthProvider>().locationText?.trim();
        final city = (loc == null || loc.isEmpty) ? 'Oman' : loc;
        if (_lastHomeCitySentToProvider == city) return;
        _lastHomeCitySentToProvider = city;
        context.read<TravelProvider>().loadHome(city);
      });
    }

    final name = auth.fullName ?? context.tr('user');
    final location = auth.locationText;

    final visiblePlaces = travel.filteredPlaces(
      query: '',
      filters: selectedFilters,
      maxPrice: null,
      priceSortBy: priceSortBy,
      ratingSortBy: ratingSortBy,
      sourceOverride: travel.homeMergedSourceForFilters(),
    );

    final accentColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = ItineraryWalkthroughController.instance;

      w.homeFirstPlaceArrowKey = _firstPlaceArrowKey;

      // Only attempt to show this coach mark after places exist.
      if (w.step == ItineraryWalkthroughStep.homeOpenFirstPlace &&
          visiblePlaces.isNotEmpty) {
        w.showIfNeeded(context);
      }
    });

    final headerSliver = SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (travel.planningModeActive)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.dividerTheme.color ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                context.tr('planning_banner'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final img =
                  (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                      ? NetworkImage(auth.photoUrl!)
                      : const AssetImage("images/defaultUserProfile.png")
                  as ImageProvider;

                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: cardColor,
                    backgroundImage: img,
                  );
                },
              ),
              Image.asset("images/logo.png", height: 40),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications,
                      size: 28,
                      color: accentColor,
                    ),
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
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  context.tr('hi_user', {'name': name}),
                  style: TextStyle(
                    fontSize: 18,
                    color:
                    theme.textTheme.bodySmall?.color ??
                        Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                if (location != null)
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('search_location'),
                      style: TextStyle(color: Colors.grey),
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
          const SizedBox(height: 20),
          _SortSection(
            priceSortBy: priceSortBy,
            ratingSortBy: ratingSortBy,
            onPriceSortChanged: (value) => setState(() => priceSortBy = value),
            onRatingSortChanged: (value) => setState(() => ratingSortBy = value),
            accentColor: accentColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    Widget listSliver;
    if (travel.homeCategoryFallbackLoading &&
        selectedFilters.isNotEmpty &&
        visiblePlaces.isEmpty) {
      listSliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (travel.loading && travel.homePlaces.isEmpty) {
      listSliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (travel.error != null && travel.homePlaces.isEmpty) {
      listSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('places_connection_error'),
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadPlaces,
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    } else if (visiblePlaces.isEmpty) {
      final filterErr = selectedFilters.isNotEmpty &&
          travel.homeCategoryFallbackErrorKey != null;
      listSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            filterErr
                ? context.tr(travel.homeCategoryFallbackErrorKey!)
                : (travel.lastHomeLoadFilteredByInterests &&
                        travel.homePlaces.isEmpty
                    ? context.tr('no_places_match_interests')
                    : context.tr('no_places_found')),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    } else {
      listSliver = SliverList.separated(
        itemCount: visiblePlaces.length,
        itemBuilder: (context, index) {
          final w = ItineraryWalkthroughController.instance;
          final isFirst = index == 0;
          return PlaceListCard(
            place: visiblePlaces[index],
            accentColor: accentColor,
            cardColor: cardColor,
            detailsButtonKey: (isFirst &&
                    w.step == ItineraryWalkthroughStep.homeOpenFirstPlace)
                ? _firstPlaceArrowKey
                : null,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadPlaces(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: headerSliver,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: listSliver,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 0),
    );
  }
}

class _SortSection extends StatelessWidget {
  final String? priceSortBy;
  final String? ratingSortBy;
  final ValueChanged<String?> onPriceSortChanged;
  final ValueChanged<String?> onRatingSortChanged;
  final Color accentColor;
  final Color cardColor;

  const _SortSection({
    required this.priceSortBy,
    required this.ratingSortBy,
    required this.onPriceSortChanged,
    required this.onRatingSortChanged,
    required this.accentColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 58),
      child: Row(
        children: [
          Expanded(
            child: _SortDropdownButton(
              label: context.tr('price'),
              icon: Icons.payments_outlined,
              options: [
                ('price_desc', context.tr('sort_high_to_low')),
                ('price_asc', context.tr('sort_low_to_high')),
              ],
              selectedValue: priceSortBy,
              accentColor: accentColor,
              onSelected: onPriceSortChanged,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: _SortDropdownButton(
              label: context.tr('rate'),
              icon: Icons.star_outline_rounded,
              options: [
                ('rating_desc', context.tr('sort_high_to_low')),
                ('rating_asc', context.tr('sort_low_to_high')),
              ],
              selectedValue: ratingSortBy,
              accentColor: accentColor,
              onSelected: onRatingSortChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdownButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<(String, String)> options;
  final String? selectedValue;
  final Color accentColor;
  final ValueChanged<String?> onSelected;

  const _SortDropdownButton({
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedValue,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor,
          width: 1.1,
        ),
      ),
      child: PopupMenuButton<String?>(
        onSelected: (value) => onSelected(value == selectedValue ? null : value),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        elevation: 6,
        padding: EdgeInsets.zero,
        offset: const Offset(0, 38),
        itemBuilder: (context) => options
            .map(
              (o) => PopupMenuItem<String?>(
            value: o.$1,
            child: Row(
              children: [
                Text(o.$2),
                if (selectedValue == o.$1) ...[
                  const Spacer(),
                  Icon(Icons.check, color: accentColor, size: 18),
                ],
              ],
            ),
          ),
        )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: accentColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
