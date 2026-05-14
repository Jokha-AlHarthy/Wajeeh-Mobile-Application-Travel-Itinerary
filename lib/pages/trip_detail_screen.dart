import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import '../utils/ai_trip_plan_markdown_parser.dart';
import '../utils/pdf_download.dart';
import '../utils/trip_detail_shared_text.dart';
import '../utils/trip_pdf_export.dart';
import 'notifications_screen.dart';
import 'rate_screen.dart';

/// Saved itinerary detail (from trip history): real [days] activities, package line, status.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({
    super.key,
    required this.trip,
    /// Optional day index (0-based) for callers that open a specific day; reserved for future UI.
    this.initialDayIndex,
    /// When true, this trip was opened from the user's shared-inbox list (not their own history).
    this.isSharedInboxEntry = false,
  });

  final Map<String, dynamic> trip;
  final int? initialDayIndex;
  final bool isSharedInboxEntry;

  static const double _leadW = 115;
  static const double _leadH = 95;

  static bool _tripEndIsBeforeToday(Map<String, dynamic> trip) {
    final endStr = trip['endDate']?.toString();
    if (endStr == null || endStr.isEmpty) return false;
    final end = DateTime.tryParse(endStr);
    if (end == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return endOnly.isBefore(today);
  }

  Widget _tripLeadImage(BuildContext context, String src) {
    final theme = Theme.of(context);
    final placeholder = theme.brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: _leadW,
        height: _leadH,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: _leadW,
          height: _leadH,
          color: placeholder,
          child: Icon(Icons.image_not_supported_outlined, color: iconColor),
        ),
      );
    }
    if (src.isEmpty) {
      return Container(
        width: _leadW,
        height: _leadH,
        color: placeholder,
        child: Icon(Icons.image_not_supported_outlined, color: iconColor),
      );
    }
    return Image.asset(
      src,
      width: _leadW,
      height: _leadH,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: _leadW,
        height: _leadH,
        color: placeholder,
        child: Icon(Icons.broken_image_outlined, color: iconColor),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _detailColumn(context, label1, value1, null),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _detailColumn(context, label2, value2, null),
        ),
      ],
    );
  }

  Widget _detailColumn(
    BuildContext context,
    String label,
    String value,
    Color? color,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }


  /// App-style itinerary row: optional category, place title, price on the right,
  /// date/schedule as subtle caption (no markdown, no bullet columns).
  Widget _itineraryDetailRow(
    BuildContext context,
    TravelProvider travel,
    Map<String, dynamic> place,
    String dateStr,
    int dayNumber,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rawName = travel.placeName(place);
    final stripped =
        AiTripPlanMarkdownParser.stripItineraryMarkdownForDisplay(rawName);
    final row = tripItineraryRowText(
      context,
      travel,
      place,
      dateStr,
      dayNumber,
    );
    final category = row.category.isNotEmpty ? row.category : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                category,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: scheme.primary,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.activityTitle.isEmpty ? stripped : row.activityTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.35,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (row.price.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  row.price,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ),
          if (row.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                row.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  height: 1.3,
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _roundedButton(
    BuildContext context,
    String text,
    Color background, {
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onPrimary;
    return Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: background,
            foregroundColor: labelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed ?? () {},
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSaveOfflinePressed(BuildContext context) async {
    final travel = context.read<TravelProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(ctx.tr('saving_itinerary_offline'))),
          ],
        ),
      ),
    );

    final ok = await travel.saveItineraryOffline(trip);

    if (!context.mounted) return;
    navigator.pop(); // close loading dialog

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.tr('itinerary_saved_offline_success')
              : context.tr('itinerary_saved_offline_failed'),
        ),
      ),
    );
  }

  Future<void> _onDeleteItineraryPressed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('delete_itinerary')),
        content: Text(ctx.tr('delete_itinerary_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(ctx.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final travel = context.read<TravelProvider>();
    final removed = await travel.deleteSavedTrip(trip);

    if (!context.mounted) return;

    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('itinerary_deleted_success'))),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('itinerary_delete_failed'))),
      );
    }
  }

  void _onReuseItineraryPressed(BuildContext context) {
    final travel = context.read<TravelProvider>();
    final tripForPlanner = travel.prepareTripSnapshotForPlannerReuse(trip);
    travel.loadSavedTripIntoPlanner(tripForPlanner);
    Navigator.pushNamed(
      context,
      '/trip_planing',
      arguments: <String, dynamic>{'trip': tripForPlanner},
    );
  }

  void _showShareItineraryDialog(
    BuildContext context,
    Map<String, dynamic> tripMap,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ShareItineraryDialog(trip: tripMap),
    );
  }

  List<Widget> _buildActivityBlocks(
    BuildContext context,
    TravelProvider travel,
  ) {
    final theme = Theme.of(context);
    final blocks = <Widget>[];
    final daysRaw = trip['days'];
    if (daysRaw is! List || daysRaw.isEmpty) {
      blocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            context.tr('no_activities_scheduled'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
      return blocks;
    }

    for (final raw in daysRaw) {
      if (raw is! Map) continue;
      final dayMap = Map<String, dynamic>.from(raw);
      final dn = dayMap['dayNumber'];
      final dayNumber = dn is int ? dn : int.tryParse(dn.toString()) ?? 0;
      final dateStr = dayMap['date']?.toString() ?? '';
      final placesRaw = dayMap['places'];
      final places = <Map<String, dynamic>>[];
      if (placesRaw is List) {
        for (final p in placesRaw) {
          if (p is Map<String, dynamic>) {
            places.add(p);
          } else if (p is Map) {
            places.add(Map<String, dynamic>.from(p));
          }
        }
      }

      blocks.add(
        Text(
          tripDetailDayTitle(context, dayNumber, dateStr, trip),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
      blocks.add(const SizedBox(height: 8));

      if (tripDetailPlacesUseStructuredLayout(places)) {
        final ordered = List<Map<String, dynamic>>.from(places);
        ordered.sort(
          (a, b) => AiTripPlanMarkdownParser.slotOrderForCategoryKey(
                a['itineraryCategoryKey']?.toString(),
              )
              .compareTo(
                AiTripPlanMarkdownParser.slotOrderForCategoryKey(
                  b['itineraryCategoryKey']?.toString(),
                ),
              ),
        );
        for (final place in ordered) {
          blocks.add(
            _itineraryDetailRow(context, travel, place, dateStr, dayNumber),
          );
        }
        blocks.add(const SizedBox(height: 12));
        continue;
      }

      void addSection(String title, List<Map<String, dynamic>> list) {
        if (list.isEmpty) return;

        blocks.add(
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.primary,
            ),
          ),
        );

        for (final place in list) {
          blocks.add(
            _itineraryDetailRow(context, travel, place, dateStr, dayNumber),
          );
        }

        blocks.add(const SizedBox(height: 10));
      }

      if (places.isEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              context.tr('no_activities_scheduled'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        );
        continue;
      }

      final hotels = <Map<String, dynamic>>[];
      final timed = <Map<String, dynamic>>[];

      for (final place in places) {
        if (travel.placeIsHotelStayInTrip(place)) {
          hotels.add(place);
        } else {
          timed.add(place);
        }
      }

      timed.sort(
        (a, b) => tripDetailMinutesForSort(travel, a)
            .compareTo(tripDetailMinutesForSort(travel, b)),
      );

      if (hotels.isNotEmpty) {
        addSection(context.tr('hotel_stays_section'), hotels);
      }

      final morning = <Map<String, dynamic>>[];
      final afternoon = <Map<String, dynamic>>[];
      final evening = <Map<String, dynamic>>[];

      for (final place in timed) {
        final mins = travel.scheduledTimeMinutesFromTripPlace(place) ?? 12 * 60;
        final hour = mins ~/ 60;

        if (hour < 12) {
          morning.add(place);
        } else if (hour < 17) {
          afternoon.add(place);
        } else {
          evening.add(place);
        }
      }

      addSection(context.tr('morning'), morning);
      addSection(context.tr('afternoon'), afternoon);
      addSection(context.tr('evening'), evening);

      blocks.add(const SizedBox(height: 12));
    }

    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travel = context.read<TravelProvider>();
    final loc = travel.historyLocationLinesForTrip(trip);
    final tripName = trip['tripName']?.toString().trim() ?? '';
    final title = tripName.isNotEmpty ? tripName : (loc['cities'] ?? '');
    final country = loc['countries'] ?? '';
    final dates = trip['dateText']?.toString() ?? '';
    final image = trip['image']?.toString() ?? '';
    final rating =
        double.tryParse(trip['rating']?.toString() ?? '4.5') ?? 4.5;

    final packageKeys = travel.packageIncludeKeysForTrip(trip);
    var packageLabel = packageKeys.map((k) => context.tr(k)).join(', ');
    if (packageLabel.isEmpty) {
      packageLabel = context.tr('package_includes_default');
    }

    final isPast = _tripEndIsBeforeToday(trip);
    final statusLabel =
        isPast ? context.tr('completed') : context.tr('on_going');
    final statusColor = isPast
        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
        : Colors.green.shade700;

    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.dividerTheme.color ??
        (theme.brightness == Brightness.dark
            ? Colors.white24
            : Colors.black87);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(color: theme.colorScheme.onSurface),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('images/logo.png', height: 55),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications,
                    size: 28,
                    color: theme.colorScheme.onSurface,
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              context.tr('detail_my_trip'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _tripLeadImage(context, image),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.87),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        country,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    Text(
                                      rating.toString(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _detailRow(
                        context,
                        context.tr('date_booking'),
                        dates,
                        context.tr('package_includes'),
                        packageLabel,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _detailColumn(
                          context,
                          context.tr('status'),
                          statusLabel,
                          statusColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSharedInboxEntry)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _onReuseItineraryPressed(context),
                            child: Text(
                              context.tr('reuse_itinerary'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else if (firebase_auth.FirebaseAuth.instance.currentUser !=
                          null)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _showShareItineraryDialog(context, trip),
                            child: Text(
                              context.tr('share_itinerary'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        color: theme.dividerTheme.color ?? borderColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('activities'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildActivityBlocks(context, travel),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _roundedButton(
                            context,
                            context.tr('save_itinerary_offline'),
                            theme.colorScheme.primary,
                            onPressed: () => _onSaveOfflinePressed(context),
                          ),
                          const SizedBox(width: 8),
                          _roundedButton(
                            context,
                            context.tr('download_pdf'),
                            theme.colorScheme.primary,
                            onPressed: () => _downloadTripPdf(context, trip),
                          ),
                          if (!isSharedInboxEntry) ...[
                            const SizedBox(width: 8),
                            _roundedButton(
                              context,
                              context.tr('delete_itinerary'),
                              theme.colorScheme.error,
                              onPressed: () =>
                                  _onDeleteItineraryPressed(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        RateScreen(
                      placeTitle: title,
                      country: country,
                      rating: rating,
                      image: image,
                    ),
                  ),
                );
              },
              child: Text(
                context.tr('done_now_judge_us'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 1),
    );
  }
}

class _ShareItineraryDialog extends StatefulWidget {
  const _ShareItineraryDialog({required this.trip});

  final Map<String, dynamic> trip;

  @override
  State<_ShareItineraryDialog> createState() => _ShareItineraryDialogState();
}

class _ShareItineraryDialogState extends State<_ShareItineraryDialog> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSharePressed() async {
    if (_saving) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('share_invalid_email'))),
      );
      return;
    }

    setState(() => _saving = true);

    final travel = context.read<TravelProvider>();
    final err =
        await travel.shareItineraryWithUserByEmail(email, widget.trip);

    if (!mounted) return;
    setState(() => _saving = false);

    if (err == null) {
      final messenger = ScaffoldMessenger.of(context);
      final msg = context.tr('share_itinerary_success');
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(err))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.tr('share_itinerary_dialog_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('share_itinerary_dialog_body'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: context.tr('email'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(
                    context.tr('cancel'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _saving ? null : _onSharePressed,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.tr('share_itinerary_dialog_share'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _downloadTripPdf(
  BuildContext context,
  Map<String, dynamic> trip,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final travel = context.read<TravelProvider>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(ctx.tr('download_pdf'))),
        ],
      ),
    ),
  );

  try {
    final bytes = await buildTripDetailPdfBytes(
      context: context,
      travel: travel,
      trip: trip,
    );
    final loc = travel.historyLocationLinesForTrip(trip);
    final tripName = trip['tripName']?.toString().trim() ?? '';
    final base =
        tripName.isNotEmpty ? tripName : (loc['cities'] ?? 'trip_itinerary');

    final outcome = await savePdfToDevice(base, bytes);

    if (!context.mounted) return;
    switch (outcome) {
      case PdfSaveOutcome.savedToChosenPath:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('pdf_saved'))),
        );
        break;
      case PdfSaveOutcome.cancelledByUser:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('pdf_save_cancelled'))),
        );
        break;
      case PdfSaveOutcome.presentedShareSheet:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('pdf_share_pick_destination'))),
        );
        break;
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('pdf_save_failed'))),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
