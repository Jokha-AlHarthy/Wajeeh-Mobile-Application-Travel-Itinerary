import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import 'trip_detail_screen.dart';

class SavedItineraryScreen extends StatefulWidget {
  const SavedItineraryScreen({
    super.key,
    this.startedOffline = false,
  });

  final bool startedOffline;

  @override
  State<SavedItineraryScreen> createState() => _SavedItineraryScreenState();
}

class _SavedItineraryScreenState extends State<SavedItineraryScreen> {
  bool _kickstartedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_kickstartedLoad) return;
    _kickstartedLoad = true;

    // Ensure TravelProvider loads the correct scoped saved trips.
    // When offline this will fall back to SharedPreferences.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    unawaited(context.read<TravelProvider>().setStorageUserId(uid));
  }

  void _openTripDetail(BuildContext context, Map<String, dynamic> t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travel = context.watch<TravelProvider>();
    final trips = travel.offlineSavedTrips;

    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.dividerTheme.color ??
        (theme.brightness == Brightness.dark ? Colors.white24 : Colors.black87);
    final placeholderFill = theme.brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final onSurface = theme.colorScheme.onSurface;
    final mutedText = onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: const BackButton(),
        centerTitle: true,
        title: Text(
          context.tr('saved_itinerary'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: trips.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 44,
                        color: mutedText,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('saved_itinerary_empty_title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.startedOffline
                            ? context.tr('saved_itinerary_empty_offline_body')
                            : context.tr('saved_itinerary_empty_body'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = trips[index];
                  final image = t['image']?.toString() ?? '';
                  final dateLine = t['dateText']?.toString() ?? '';
                  final loc = travel.historyLocationLinesForTrip(t);
                  final cityLine = loc['cities'] ?? '';
                  final countryLine = loc['countries'] ?? '';
                  final rawName = t['tripName']?.toString().trim() ?? '';
                  final tripTitle = rawName.isNotEmpty ? rawName : cityLine;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openTripDetail(context, t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.65)
                            : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      color: placeholderFill,
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: mutedText,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 72,
                                    height: 72,
                                    color: placeholderFill,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: mutedText,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tripTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    if (dateLine.isNotEmpty)
                                      Text(
                                        dateLine,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: mutedText,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (countryLine.isNotEmpty)
                                  Text(
                                    countryLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mutedText,
                                      height: 1.2,
                                    ),
                                  ),
                                if (cityLine.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    cityLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mutedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

