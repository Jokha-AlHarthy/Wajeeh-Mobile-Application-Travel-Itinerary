import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';

import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../services/itinerary_walkthrough.dart';

class TripPlanScreen extends StatefulWidget {
  const TripPlanScreen({super.key});

  @override
  State<TripPlanScreen> createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showItinerary = false;
  final TextEditingController _tripNameController = TextEditingController();

  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();
  final _createTripKey = GlobalKey();
  final _exploreAddKey = GlobalKey();
  final _saveItineraryKey = GlobalKey();

  final _helpKey = GlobalKey();

  DateTime _todayDateOnly() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final travel = context.read<TravelProvider>();
      final walkthrough = ItineraryWalkthroughController.instance;
      final args = ModalRoute.of(context)?.settings.arguments;

      walkthrough.startDateKey = _startDateKey;
      walkthrough.endDateKey = _endDateKey;
      walkthrough.createTripButtonKey = _createTripKey;
      walkthrough.exploreAddButtonKey = _exploreAddKey;
      // Guide stops after saving a place; we keep this key for potential future steps.
      walkthrough.saveItineraryButtonKey = _saveItineraryKey;

      if (args is Map && args['trip'] is Map) {
        travel.loadSavedTripIntoPlanner(
          Map<String, dynamic>.from(args['trip'] as Map),
          listIndex: args['index'] is int ? args['index'] as int : null,
        );
      } else {
        travel.clearEditingSavedTripTarget();
      }

      final wantsWalkthrough =
          args is Map && args['startWalkthrough'] == true;
      if (wantsWalkthrough) {
        walkthrough.start();
      }

      if (travel.tripPlanStart != null && travel.tripPlanEnd != null) {
        final today = _todayDateOnly();
        var start = travel.tripPlanStart!;
        var end = travel.tripPlanEnd!;
        final openedFromHistory = args is Map && args['trip'] is Map;

        if (!openedFromHistory && start.isBefore(today)) {
          start = today;
          if (end.isBefore(start)) end = start;
          travel.updateTripPlanDraftDates(start, end);
        }

        setState(() {
          _startDate = start;
          _endDate = end;
          _showItinerary = travel.tripPlanItineraryActive;
          _tripNameController.text = travel.tripPlanTripName;
        });
      }

      if (walkthrough.pendingSnackBarMessage != null) {
        final msg = walkthrough.pendingSnackBarMessage!;
        walkthrough.pendingSnackBarMessage = null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final w = ItineraryWalkthroughController.instance;
        w.showIfNeeded(context);
      });
    });
  }

  Future<void> _pickStartDate() async {
    final today = _todayDateOnly();
    final initial = _startDate != null && !_startDate!.isBefore(today)
        ? _startDate!
        : today;

    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }

        _showItinerary = false;
      });

      if (!mounted) return;

      context.read<TravelProvider>().updateTripPlanDraftDates(
            _startDate,
            _endDate,
          );

      final walkthrough = ItineraryWalkthroughController.instance;
      walkthrough.onDatesSelected(
        hasStart: _startDate != null,
        hasEnd: _endDate != null,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        walkthrough.showIfNeeded(context);
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_start_date_first'))),
      );
      return;
    }

    final today = _todayDateOnly();
    final firstAllowed = _startDate!.isBefore(today) ? today : _startDate!;
    final initial = _endDate != null && !_endDate!.isBefore(firstAllowed)
        ? _endDate!
        : firstAllowed;

    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _showItinerary = false;
      });

      if (!mounted) return;

      context.read<TravelProvider>().updateTripPlanDraftDates(
            _startDate,
            _endDate,
          );

      final walkthrough = ItineraryWalkthroughController.instance;
      walkthrough.onDatesSelected(
        hasStart: _startDate != null,
        hasEnd: _endDate != null,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        walkthrough.showIfNeeded(context);
      });
    }
  }

  int get _tripDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  void _createItinerary() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_trip_dates'))),
      );
      return;
    }

    final today = _todayDateOnly();

    if (_startDate!.isBefore(today) || _endDate!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_trip_dates'))),
      );
      return;
    }

    final travel = context.read<TravelProvider>();
    travel.updateTripPlanDraftDates(_startDate!, _endDate!);
    travel.activateTripPlanItinerary();

    setState(() {
      _showItinerary = true;
    });

    final walkthrough = ItineraryWalkthroughController.instance;
    walkthrough.onTripCreated();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      walkthrough.showIfNeeded(context);
    });
  }

  void _goToHomeAndSelectAttraction() {
    final walkthrough = ItineraryWalkthroughController.instance;
    walkthrough.onExploreAddTapped();

    context.read<TravelProvider>().enablePlanningMode();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_place_from_search'))),
      );
    });
  }

  String _formatDateField(BuildContext context, DateTime? date) {
    if (date == null) return '';

    final lang = Localizations.localeOf(context).languageCode;

    if (lang == 'ar') {
      return DateFormat('d MMMM y', 'ar').format(date);
    }

    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatDayDate(BuildContext context, DateTime date) {
    final lang = Localizations.localeOf(context).languageCode;

    if (lang == 'ar') {
      return DateFormat('EEEE، d MMMM y', 'ar').format(date);
    }

    return DateFormat('EEEE, MMMM d, y', 'en').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (travel.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(travel.error!)),
            backgroundColor: Colors.red,
          ),
        );

        travel.error = null;
      }
    });

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final titleColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    final dayCardBg = isDark
        ? (theme.cardTheme.color ?? theme.colorScheme.surface)
        : const Color(0xFF66728A);

    final dayCardOnColor = isDark ? theme.colorScheme.onSurface : Colors.white;

    final activityChipBg = isDark ? const Color(0xFFF0F0F0) : Colors.white;
    final activityChipFg = const Color(0xFF1A2B49);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 10),
                    _buildHeader(
                      context,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      titleColor: titleColor,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      context.tr('select_trip_date'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            context,
                            key: _startDateKey,
                            label: context.tr('starting_date'),
                            value: _formatDateField(context, _startDate),
                            onTap: _pickStartDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            context,
                            key: _endDateKey,
                            label: context.tr('ending_date'),
                            value: _formatDateField(context, _endDate),
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        key: _createTripKey,
                        onPressed: _createItinerary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          context.tr('create_trip'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_showItinerary && _tripDays > 0) ...[
                      Text(
                        context.tr('trip_name_label'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tripNameController,
                        onChanged: (v) =>
                            context.read<TravelProvider>().setTripPlanTripName(v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          hintText: context.tr('trip_name_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Consumer<TravelProvider>(
                        builder: (context, travel, _) {
                          return Column(
                            children: [
                              for (int index = 0;
                                  index < _tripDays;
                                  index++) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildDayCard(
                                    context,
                                    travel,
                                    dayCardBg: dayCardBg,
                                    dayCardOnColor: dayCardOnColor,
                                    activityChipBg: activityChipBg,
                                    activityChipFg: activityChipFg,
                                    dayNumber: index + 1,
                                    dateText: _formatDayDate(
                                      context,
                                      _startDate!.add(Duration(days: index)),
                                    ),
                                    places: travel.placesForTripDay(index + 1),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildBottomButtons(
                        context,
                        primaryColor: accentColor,
                        destructiveColor: theme.colorScheme.error,
                        labelColor: theme.colorScheme.onPrimary,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 2),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(Icons.arrow_back, color: onSurface, size: 24),
        ),
        Expanded(
          child: Center(
            child: Image.asset('images/logo.png', height: 40),
          ),
        ),
        IconButton(
          key: _helpKey,
          tooltip: context.tr('show_guide_again'),
          onPressed: () {
            final w = ItineraryWalkthroughController.instance;
            w.replay();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              w.showIfNeeded(context);
            });
          },
          icon: Icon(Icons.help_outline, color: onSurface, size: 22),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color accentColor,
    required Color cardColor,
    required Color titleColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final img = (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                    ? NetworkImage(auth.photoUrl!)
                    : const AssetImage('images/defaultUserProfile.png')
                        as ImageProvider;

                return CircleAvatar(
                  radius: 22,
                  backgroundColor: cardColor,
                  backgroundImage: img,
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Text(
            context.tr('your_trip_plan'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications,
                    size: 28,
                    color: accentColor,
                  ),
                  PositionedDirectional(
                    end: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
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
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    Key? key,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final fill = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.dividerTheme.color ??
        (theme.brightness == Brightness.dark
            ? Colors.white24
            : const Color(0xFFD6D6D6));

    final labelColor = theme.colorScheme.primary;
    final valueColor = theme.colorScheme.onSurface.withValues(alpha: 0.87);

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: value.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 13,
                            color: valueColor,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_month, size: 18, color: labelColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    TravelProvider travel, {
    required Color dayCardBg,
    required Color dayCardOnColor,
    required Color activityChipBg,
    required Color activityChipFg,
    required int dayNumber,
    required String dateText,
    required List<Map<String, dynamic>> places,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dayCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('day')} $dayNumber',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: dayCardOnColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 13,
              color: dayCardOnColor,
            ),
          ),
          if (places.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (int i = 0; i < places.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildActivityChip(
                context,
                travel,
                chipBg: activityChipBg,
                chipFg: activityChipFg,
                dayNumber: dayNumber,
                index: i,
                place: places[i],
              ),
            ],
          ],
          if (places.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.tr('no_places_added'),
              style: TextStyle(
                color: dayCardOnColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityChip(
    BuildContext context,
    TravelProvider travel, {
    required Color chipBg,
    required Color chipFg,
    required int dayNumber,
    required int index,
    required Map<String, dynamic> place,
  }) {
    final title = travel.placeName(place);
    final lang = Localizations.localeOf(context).languageCode;
    String timeLine;

    if (travel.placeIsHotelStayInTrip(place)) {
      timeLine = context.tr('hotel_checkin_day_line', {
        'day': dayNumber.toString(),
      });
    } else {
      final mins = travel.scheduledTimeMinutesFromTripPlace(place);

      if (mins != null) {
        final dt = DateTime(2000, 1, 1, mins ~/ 60, mins % 60);
        timeLine = lang == 'ar'
            ? DateFormat.jm('ar').format(dt)
            : DateFormat.jm('en').format(dt);
      } else {
        timeLine = '';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (timeLine.isNotEmpty)
                    Text(
                      timeLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: chipFg.withValues(alpha: 0.85),
                      ),
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: chipFg,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_upward, size: 18, color: chipFg),
            onPressed: index == 0
                ? null
                : () {
                    travel.movePlaceInTripDay(dayNumber, index, index - 1);
                  },
          ),
          IconButton(
            icon: Icon(Icons.arrow_downward, size: 18, color: chipFg),
            onPressed: () {
              travel.movePlaceInTripDay(dayNumber, index, index + 1);
            },
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: chipFg),
            onPressed: () {
              travel.removePlaceFromTripDay(dayNumber, index);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('place_removed'))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context, {
    required Color primaryColor,
    required Color destructiveColor,
    required Color labelColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            key: _exploreAddKey,
            label: context.tr('explore_add'),
            backgroundColor: primaryColor,
            labelColor: labelColor,
            onTap: _goToHomeAndSelectAttraction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            key: _saveItineraryKey,
            label: context.tr('save_itinerary'),
            backgroundColor: primaryColor,
            labelColor: labelColor,
            onTap: () async {
              final travel = context.read<TravelProvider>();

              if (travel.tripPlanPlacesByDay.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('add_places_first'))),
                );
                return;
              }

              if (_startDate == null || _endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('select_trip_dates'))),
                );
                return;
              }

              if (!travel.isTripPlanItineraryEveryDayFilled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('itinerary_each_day_needs_place'),
                    ),
                  ),
                );
                return;
              }

              travel.setTripPlanTripName(_tripNameController.text);

              final ok = await travel.saveCurrentItinerary();

              if (!context.mounted) return;

              if (!ok) {
                final msg = travel.error != null
                    ? context.tr(travel.error!)
                    : context.tr('error_generic');
                travel.error = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await ItineraryWalkthroughController.instance.markCompleted();
              ItineraryWalkthroughController.instance.stop();

              setState(() {
                _startDate = travel.tripPlanStart;
                _endDate = travel.tripPlanEnd;
                _showItinerary = travel.tripPlanItineraryActive;
                _tripNameController.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('itinerary_saved_success_title'))),
              );

              if (!mounted) return;

              showModalBottomSheet<void>(
                context: context,
                backgroundColor:
                    Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('itinerary_saved_success_title'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(ctx).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pushNamed(context, '/trip_history');
                                  },
                                  child: Text(context.tr('view_trip_history')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(context.tr('stay_here')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: context.tr('cancel'),
            backgroundColor: destructiveColor,
            labelColor: labelColor,
            onTap: () {
              context.read<TravelProvider>().deactivateTripPlanItinerary();

              setState(() {
                _showItinerary = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    Key? key,
    required String label,
    required Color backgroundColor,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        key: key,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: labelColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
