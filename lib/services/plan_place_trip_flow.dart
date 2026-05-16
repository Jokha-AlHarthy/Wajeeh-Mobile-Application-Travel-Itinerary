import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import '../utils/saved_trip_extensions.dart';
import 'itinerary_walkthrough.dart';

const _snackSuccessDuration = Duration(seconds: 4);
const _snackErrorDuration = Duration(seconds: 5);

void showPlanTripSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : null,
      duration: isError ? _snackErrorDuration : _snackSuccessDuration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String _travelErrorMessage(BuildContext context, TravelProvider travel) {
  final key = travel.error;
  travel.error = null;
  if (key == null || key.isEmpty) {
    return context.tr('error_generic');
  }
  return context.tr(key);
}

/// Entry point for the Display screen Plan button.
Future<void> runPlanPlaceToTripFlow(
  BuildContext context,
  Map<String, dynamic> place,
) async {
  final travel = context.read<TravelProvider>();
  final walkthrough = ItineraryWalkthroughController.instance;

  if (travel.tripPlanItineraryActive && travel.tripPlanDayCount > 0) {
    await _showDraftTripDaySheet(context, place);
    return;
  }

  await _showPlanDestinationSheet(context, place, walkthrough);
}

Future<void> _showPlanDestinationSheet(
  BuildContext context,
  Map<String, dynamic> place,
  ItineraryWalkthroughController walkthrough,
) async {
  final theme = Theme.of(context);
  final travel = context.read<TravelProvider>();
  final ongoing = travel.ongoingSavedTrips;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ctx.tr('plan_place_choose_option'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: ongoing.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showOngoingTripPicker(context, place);
                        },
                  child: Text(ctx.tr('plan_add_to_existing_trip')),
                ),
              ),
              if (ongoing.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ctx.tr('plan_no_ongoing_trips'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _navigateCreateNewTrip(context, place, walkthrough);
                  },
                  child: Text(ctx.tr('plan_create_new_trip')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _navigateCreateNewTrip(
  BuildContext context,
  Map<String, dynamic> place,
  ItineraryWalkthroughController walkthrough,
) async {
  final travel = context.read<TravelProvider>();
  travel.setPendingPlanPlace(place);

  final shouldStart = await walkthrough.shouldAutoStart(
    hasTripHistory: travel.savedTrips.isNotEmpty,
  );

  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/trip_planing',
    (route) => false,
    arguments: <String, dynamic>{
      if (shouldStart) 'startWalkthrough': true,
      'source': 'plan_create_new',
    },
  );

  walkthrough.pendingSnackBarMessage =
      context.tr('create_trip_first_snackbar');
}

Future<void> _showOngoingTripPicker(
  BuildContext context,
  Map<String, dynamic> place,
) async {
  final travel = context.read<TravelProvider>();
  final trips = travel.ongoingSavedTrips;
  if (trips.isEmpty) {
    showPlanTripSnackBar(context, context.tr('plan_no_ongoing_trips'));
    return;
  }

  final theme = Theme.of(context);

  final selectedTrip = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.55;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ctx.tr('plan_select_ongoing_trip'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: trips.length,
                  itemBuilder: (_, i) {
                    final trip = trips[i];
                    final name = (trip['tripName'] ?? trip['title'] ?? '')
                        .toString()
                        .trim();
                    final label =
                        name.isNotEmpty ? name : ctx.tr('your_trip');
                    return ListTile(
                      title: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: trip['dateText'] != null
                          ? Text(trip['dateText'].toString())
                          : null,
                      onTap: () => Navigator.pop(ctx, trip),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || selectedTrip == null) return;

  final tripId = selectedTrip['id']?.toString();
  if (tripId == null || tripId.isEmpty) {
    showPlanTripSnackBar(
      context,
      context.tr('trip_not_found'),
      isError: true,
    );
    return;
  }

  await _showOngoingTripDayAndTimeFlow(
    context,
    place: place,
    tripId: tripId,
    trip: selectedTrip,
  );
}

Future<void> _showOngoingTripDayAndTimeFlow(
  BuildContext context, {
  required Map<String, dynamic> place,
  required String tripId,
  required Map<String, dynamic> trip,
}) async {
  final dayCount = tripDaySelectorCount(trip);
  if (dayCount <= 0) return;

  final theme = Theme.of(context);
  int? selectedDay;

  final dayChosen = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (_, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctx.tr('choose_day_for_place'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(dayCount, (i) {
                    final day = i + 1;
                    return RadioListTile<int>(
                      value: day,
                      groupValue: selectedDay,
                      title: Text('${ctx.tr('day')} $day'),
                      onChanged: (v) => setModalState(() => selectedDay = v),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: selectedDay == null
                        ? null
                        : () => Navigator.pop(ctx, true),
                    child: Text(ctx.tr('continue')),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (!context.mounted || dayChosen != true || selectedDay == null) return;

  final travel = context.read<TravelProvider>();
  final isHotelPlace = travel.isHotel(place);

  if (isHotelPlace) {
    final ok = await travel.addPlaceToOngoingSavedTripDay(
      tripId: tripId,
      dayNumber: selectedDay!,
      place: place,
      hotelStayOnDay: true,
    );
    if (!context.mounted) return;
    if (ok) {
      showPlanTripSnackBar(
        context,
        context.tr('place_added_to_trip_success'),
      );
    } else {
      showPlanTripSnackBar(
        context,
        _travelErrorMessage(context, travel),
        isError: true,
      );
    }
    return;
  }

  final walkthrough = ItineraryWalkthroughController.instance;
  final picked = await walkthrough.runWithModalHidden(
    context,
    () => showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    ),
    restoreOverlay: false,
  );

  if (!context.mounted) return;
  if (picked == null) {
    showPlanTripSnackBar(
      context,
      context.tr('activity_time_required'),
      isError: true,
    );
    return;
  }

  final mins = picked.hour * 60 + picked.minute;
  final ok = await travel.addPlaceToOngoingSavedTripDay(
    tripId: tripId,
    dayNumber: selectedDay!,
    place: place,
    scheduledTimeMinutes: mins,
  );

  if (!context.mounted) return;
  if (ok) {
    showPlanTripSnackBar(
      context,
      context.tr('place_added_to_trip_success'),
    );
  } else {
    showPlanTripSnackBar(
      context,
      _travelErrorMessage(context, travel),
      isError: true,
    );
  }
}

Future<void> _showDraftTripDaySheet(
  BuildContext context,
  Map<String, dynamic> place,
) async {
  final travel = context.read<TravelProvider>();
  final theme = Theme.of(context);
  final walkthrough = ItineraryWalkthroughController.instance;

  walkthrough.hideOverlayForModal();
  walkthrough.onPlanSheetOpened();

  final daySelectorKey = GlobalKey();
  walkthrough.planSheetDaySelectorKey = daySelectorKey;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final selected = <int>{};

      return StatefulBuilder(
        builder: (_, setModalState) {
          final maxH = MediaQuery.sizeOf(ctx).height * 0.55;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ItineraryWalkthroughSheetBanner(),
                  Text(
                    ctx.tr('choose_days_for_place'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    key: daySelectorKey,
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: travel.tripPlanDayCount,
                      itemBuilder: (_, i) {
                        final day = i + 1;
                        final isOn = selected.contains(day);
                        return CheckboxListTile(
                          value: isOn,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.platform,
                          title: Text(
                            '${ctx.tr('day')} $day',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                selected.add(day);
                              } else {
                                selected.remove(day);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              final sorted = selected.toList()..sort();
                              walkthrough.hideOverlayForModal();
                              Navigator.pop(ctx);
                              await _addPlaceToDraftDays(
                                context,
                                place: place,
                                days: sorted,
                                walkthrough: walkthrough,
                              );
                            },
                      child: Text(
                        ctx.tr('save'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _addPlaceToDraftDays(
  BuildContext context, {
  required Map<String, dynamic> place,
  required List<int> days,
  required ItineraryWalkthroughController walkthrough,
}) async {
  final travel = context.read<TravelProvider>();
  var allSuccess = true;

  for (final d in days) {
    if (!context.mounted) return;

    final isHotelPlace = travel.isHotel(place);

    if (isHotelPlace) {
      final success = travel.addPlaceToTripDay(
        d,
        place,
        hotelStayOnDay: true,
      );
      if (!success) {
        allSuccess = false;
        showPlanTripSnackBar(
          context,
          _travelErrorMessage(context, travel),
          isError: true,
        );
        break;
      }
    } else {
      final picked = await walkthrough.runWithModalHidden(
        context,
        () => showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
        ),
        restoreOverlay: false,
      );

      if (!context.mounted) return;
      if (picked == null) {
        allSuccess = false;
        showPlanTripSnackBar(
          context,
          context.tr('activity_time_required'),
          isError: true,
        );
        break;
      }

      final mins = picked.hour * 60 + picked.minute;
      final success = travel.addPlaceToTripDay(
        d,
        place,
        scheduledTimeMinutes: mins,
      );

      if (!success) {
        allSuccess = false;
        showPlanTripSnackBar(
          context,
          _travelErrorMessage(context, travel),
          isError: true,
        );
        break;
      }
    }
  }

  if (!context.mounted || !allSuccess) return;

  await walkthrough.markCompleted();
  if (!context.mounted) return;

  walkthrough.onPlanSheetSaved();
  travel.disablePlanningMode();

  final everyDayFilled = travel.isTripPlanItineraryEveryDayFilled;
  final addedMsg = context.tr('place_added_success_snackbar');
  walkthrough.pendingSnackBarMessage = addedMsg;

  if (!everyDayFilled) {
    final requiredMsg = context.tr('place_added_each_day_required_snackbar');
    walkthrough.pendingSnackBarMessage = '$addedMsg\n$requiredMsg';
  }

  if (travel.pendingPlanPlace != null) {
    travel.clearPendingPlanPlace();
  }

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/trip_planing',
    (route) => false,
    arguments: const <String, dynamic>{'source': 'place_saved_return'},
  );
}

/// After creating an itinerary, add [pendingPlace] when the user picks day/time.
Future<void> runPendingPlanPlaceFlowIfNeeded(BuildContext context) async {
  final travel = context.read<TravelProvider>();
  final place = travel.pendingPlanPlace;
  if (place == null) return;
  if (!travel.tripPlanItineraryActive || travel.tripPlanDayCount <= 0) {
    return;
  }

  await _showDraftTripDaySheet(context, place);
}
