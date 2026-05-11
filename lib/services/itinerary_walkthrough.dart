import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../localization/app_localizations.dart';

/// Guided coach mark walkthrough for itinerary creation.
///
/// This controller is intentionally lightweight:
/// - Each page decides when the relevant target exists and calls [showIfNeeded].
/// - State advances only when the user completes the expected action.
class ItineraryWalkthroughController {
  static const prefsKeyCompleted = 'itinerary_walkthrough_completed';

  ItineraryWalkthroughController._();

  static final ItineraryWalkthroughController instance =
      ItineraryWalkthroughController._();

  final ValueNotifier<ItineraryWalkthroughStep?> _step =
      ValueNotifier<ItineraryWalkthroughStep?>(null);

  ItineraryWalkthroughStep? get step => _step.value;

  // Targets (provided by screens via GlobalKeys).
  GlobalKey? startDateKey;
  GlobalKey? endDateKey;
  GlobalKey? createTripButtonKey;
  GlobalKey? exploreAddButtonKey;
  GlobalKey? saveItineraryButtonKey;

  GlobalKey? homeFirstPlaceArrowKey;
  GlobalKey? detailsPlanButtonKey;

  GlobalKey? planSheetDaySelectorKey;
  GlobalKey? planSheetSaveButtonKey;

  // One-shot UI messages to show after navigation.
  String? pendingSnackBarMessage;

  bool _isShowingCoachMark = false;
  TutorialCoachMark? _coachMark;

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKeyCompleted) == true;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKeyCompleted, true);
  }

  Future<bool> shouldAutoStart({required bool hasTripHistory}) async {
    if (hasTripHistory) return false;
    return !(await isCompleted());
  }

  void start() {
    _step.value = ItineraryWalkthroughStep.tripDates;
  }

  void stop() {
    _step.value = null;
    _hide();
  }

  void replay() {
    stop();
    start();
  }

  void onDatesSelected({required bool hasStart, required bool hasEnd}) {
    if (_step.value != ItineraryWalkthroughStep.tripDates) return;
    if (hasStart && hasEnd) {
      _step.value = ItineraryWalkthroughStep.createTrip;
    }
  }

  void onTripCreated() {
    if (_step.value != ItineraryWalkthroughStep.createTrip) return;
    _step.value = ItineraryWalkthroughStep.exploreAdd;
  }

  void onExploreAddTapped() {
    if (_step.value != ItineraryWalkthroughStep.exploreAdd) return;
    _step.value = ItineraryWalkthroughStep.homeOpenFirstPlace;
  }

  void onOpenedPlaceDetails() {
    if (_step.value != ItineraryWalkthroughStep.homeOpenFirstPlace) return;
    _step.value = ItineraryWalkthroughStep.detailsPlan;
  }

  void onPlanSheetOpened() {
    if (_step.value != ItineraryWalkthroughStep.detailsPlan) return;
    _step.value = ItineraryWalkthroughStep.planSheetChooseDayTime;
  }

  /// Final step in the simplified guide: after saving a place, return to Trip Plan
  /// and end the walkthrough.
  void onPlanSheetSaved() {
    if (_step.value != ItineraryWalkthroughStep.planSheetChooseDayTime) return;
    stop();
  }

  // ---------------------------------------------------------------------------
  // Coach mark rendering
  // ---------------------------------------------------------------------------

  void _hide() {
    _coachMark?.finish();
    _coachMark = null;
    _isShowingCoachMark = false;
  }

  void showIfNeeded(BuildContext context) {
    final s = _step.value;
    if (s == null) return;
    if (_isShowingCoachMark) return;

    final targets = _targetsForStep(context, s);
    if (targets.isEmpty) return;

    _isShowingCoachMark = true;
    _coachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withValues(alpha: 0.75),
      hideSkip: false,
      opacityShadow: 0.75,
      onFinish: () {
        _isShowingCoachMark = false;
        _coachMark = null;
      },
      onSkip: () {
        _isShowingCoachMark = false;
        _coachMark = null;
        stop();
        return true;
      },
    )..show(context: context);
  }

  List<TargetFocus> _targetsForStep(
    BuildContext context,
    ItineraryWalkthroughStep step,
  ) {
    TargetFocus? t(GlobalKey? key, String title, String body) {
      if (key == null) return null;
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final render = ctx.findRenderObject();
      if (render is! RenderBox) return null;

      final offset = render.localToGlobal(Offset.zero);
      final size = render.size;
      final rect = offset & size;

      final screen = MediaQuery.sizeOf(context);
      final safe = MediaQuery.paddingOf(context);

      // If target is near the bottom, show the text ABOVE it; otherwise BELOW.
      final showAbove = rect.center.dy > screen.height * 0.60;

      // Content position in screen coordinates with safe-area constraints.
      final topMin = safe.top + 12;
      final bottomMin = safe.bottom + 12;

      final customPosition = showAbove
          ? CustomTargetContentPosition(
              // Place the bottom of the content above the target.
              bottom: (screen.height - rect.top) + 12,
            )
          : CustomTargetContentPosition(
              // Place the top of the content below the target.
              top: (rect.bottom + 12).clamp(topMin, screen.height - bottomMin),
            );

      return TargetFocus(
        identify: '${step.name}_${key.hashCode}',
        keyTarget: key,
        // Force the user to interact with the highlighted widget.
        enableOverlayTab: false,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        paddingFocus: 10,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: customPosition,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            builder: (context, controller) => _CoachMarkCard(
              title: title,
              body: body,
              // Add a little bottom padding so the card never hugs the nav bar.
              extraBottomPadding: bottomMin,
            ),
          ),
        ],
      );
    }

    switch (step) {
      case ItineraryWalkthroughStep.tripDates:
        final out = <TargetFocus>[];
        final a = t(
          startDateKey,
          context.tr('walkthrough_step1_title'),
          '${context.tr('walkthrough_step1_title')}: ${context.tr('walkthrough_step1_body')}',
        );
        final b = t(
          endDateKey,
          context.tr('walkthrough_step1_title'),
          '${context.tr('walkthrough_step1_title')}: ${context.tr('walkthrough_step1_body')}',
        );
        if (a != null) out.add(a);
        if (b != null) out.add(b);
        if (out.isEmpty) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step1');
        }
        return out;

      case ItineraryWalkthroughStep.createTrip:
        final x = t(
          createTripButtonKey,
          context.tr('walkthrough_step2_title'),
          '${context.tr('walkthrough_step2_title')}: ${context.tr('walkthrough_step2_body')}',
        );
        if (x == null) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step2');
          return const [];
        }
        return [x];

      case ItineraryWalkthroughStep.exploreAdd:
        final x = t(
          exploreAddButtonKey,
          context.tr('walkthrough_step3_title'),
          '${context.tr('walkthrough_step3_title')}: ${context.tr('walkthrough_step3_body')}',
        );
        if (x == null) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step3');
          return const [];
        }
        return [x];

      case ItineraryWalkthroughStep.homeOpenFirstPlace:
        final x = t(
          homeFirstPlaceArrowKey,
          context.tr('walkthrough_step4_title'),
          '${context.tr('walkthrough_step4_title')}: ${context.tr('walkthrough_step4_body')}',
        );
        if (x == null) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step4');
          return const [];
        }
        return [x];

      case ItineraryWalkthroughStep.detailsPlan:
        final x = t(
          detailsPlanButtonKey,
          context.tr('walkthrough_step5_title'),
          '${context.tr('walkthrough_step5_title')}: ${context.tr('walkthrough_step5_body')}',
        );
        if (x == null) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step5');
          return const [];
        }
        return [x];

      case ItineraryWalkthroughStep.planSheetChooseDayTime:
        final out = <TargetFocus>[];
        final a = t(
          planSheetDaySelectorKey,
          context.tr('walkthrough_step6_title'),
          '${context.tr('walkthrough_step6_title')}: ${context.tr('walkthrough_step6_body')}',
        );
        final b = t(
          planSheetSaveButtonKey,
          context.tr('walkthrough_save_title'),
          context.tr('walkthrough_save_body'),
        );
        if (a != null) out.add(a);
        if (b != null) out.add(b);
        if (out.isEmpty) {
          pendingSnackBarMessage = context.tr('walkthrough_fallback_step6');
        }
        return out;
    }
  }
}

enum ItineraryWalkthroughStep {
  tripDates,
  createTrip,
  exploreAdd,
  homeOpenFirstPlace,
  detailsPlan,
  planSheetChooseDayTime,
}

class _CoachMarkCard extends StatelessWidget {
  final String title;
  final String body;
  final double extraBottomPadding;

  const _CoachMarkCard({
    required this.title,
    required this.body,
    this.extraBottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: extraBottomPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium ??
                TextStyle(color: theme.colorScheme.onSurface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

