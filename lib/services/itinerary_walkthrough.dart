import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

/// Guided tour for itinerary creation (UI only — does not change trip logic).
class ItineraryWalkthroughController {
  static const prefsKeyCompleted = 'itinerary_walkthrough_completed';
  static const int totalSteps = 7;

  ItineraryWalkthroughController._();

  static final ItineraryWalkthroughController instance =
      ItineraryWalkthroughController._();

  final ValueNotifier<ItineraryWalkthroughStep?> _step =
      ValueNotifier<ItineraryWalkthroughStep?>(null);

  ItineraryWalkthroughStep? get step => _step.value;

  /// Listen for overlay rebuilds when the active step changes.
  Listenable get stepListenable => _step;

  int get currentStepIndex =>
      _step.value == null ? 0 : _step.value!.index + 1;

  // Targets (GlobalKeys assigned by screens).
  GlobalKey? startDateKey;
  GlobalKey? endDateKey;
  GlobalKey? createTripButtonKey;
  GlobalKey? exploreAddButtonKey;
  GlobalKey? saveItineraryButtonKey;
  GlobalKey? homeFirstPlaceArrowKey;
  GlobalKey? detailsPlanButtonKey;
  GlobalKey? planSheetDaySelectorKey;

  String? pendingSnackBarMessage;

  OverlayEntry? _overlayEntry;

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
    _step.value = ItineraryWalkthroughStep.tripStartDate;
  }

  void stop() {
    _step.value = null;
    _removeOverlay();
  }

  void replay() {
    stop();
    start();
  }

  void onDatesSelected({required bool hasStart, required bool hasEnd}) {
    final current = _step.value;
    if (current == ItineraryWalkthroughStep.tripStartDate && hasStart) {
      _goToStep(ItineraryWalkthroughStep.tripEndDate);
    } else if (current == ItineraryWalkthroughStep.tripEndDate && hasEnd) {
      _goToStep(ItineraryWalkthroughStep.createTrip);
    }
  }

  void onTripCreated() {
    if (_step.value != ItineraryWalkthroughStep.createTrip) return;
    _goToStep(ItineraryWalkthroughStep.exploreAdd);
  }

  void onExploreAddTapped() {
    if (_step.value != ItineraryWalkthroughStep.exploreAdd) return;
    _goToStep(ItineraryWalkthroughStep.homeOpenFirstPlace);
  }

  void onOpenedPlaceDetails() {
    if (_step.value != ItineraryWalkthroughStep.homeOpenFirstPlace) return;
    _goToStep(ItineraryWalkthroughStep.detailsPlan);
  }

  void onPlanSheetOpened() {
    if (_step.value != ItineraryWalkthroughStep.detailsPlan) return;
    _goToStep(
      ItineraryWalkthroughStep.planSheetChooseDays,
      refreshOverlay: false,
    );
  }

  void onPlanSheetSaved() {
    if (_step.value == ItineraryWalkthroughStep.planSheetChooseDays) {
      stop();
    }
  }

  // ---------------------------------------------------------------------------
  // Manual navigation (Back / Next / Skip / Finish on the tooltip card).
  // ---------------------------------------------------------------------------

  void goToPreviousStep() {
    final prev = _step.value?.previous;
    if (prev == null) return;
    _goToStep(prev);
  }

  void goToNextStep() {
    final current = _step.value;
    if (current == null) return;
    if (current == ItineraryWalkthroughStep.planSheetChooseDays) {
      finish();
      return;
    }
    final next = current.next;
    if (next == null) {
      finish();
    } else {
      _goToStep(next);
    }
  }

  void skip() {
    stop();
  }

  Future<void> finish() async {
    await markCompleted();
    stop();
  }

  void _goToStep(ItineraryWalkthroughStep step, {bool refreshOverlay = true}) {
    _step.value = step;
    if (refreshOverlay) _refreshOverlay();
  }

  // ---------------------------------------------------------------------------
  // Overlay
  // ---------------------------------------------------------------------------

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Hides the tour overlay so route modals (date/time pickers) are on top.
  void hideOverlayForModal() => _removeOverlay();

  /// Runs [showModal] while the overlay is hidden.
  ///
  /// Set [restoreOverlay] to false when opening pickers after the day sheet (step 7)
  /// so the tour card does not cover the time picker.
  Future<T?> runWithModalHidden<T>(
    BuildContext context,
    Future<T?> Function() showModal, {
    bool restoreOverlay = true,
  }) async {
    final tourActive = _step.value != null;
    if (tourActive) hideOverlayForModal();
    try {
      return await showModal();
    } finally {
      if (restoreOverlay &&
          tourActive &&
          context.mounted &&
          _step.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || _step.value == null) return;
          // Step 7 uses the inline sheet banner, not the root overlay.
          if (_step.value == ItineraryWalkthroughStep.planSheetChooseDays) {
            return;
          }
          showIfNeeded(context);
        });
      }
    }
  }

  void showIfNeeded(BuildContext context) {
    final s = _step.value;
    if (s == null) return;

    if (_overlayEntry != null) {
      _refreshOverlay();
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) =>
          _ItineraryWalkthroughOverlay(controller: this),
    );
    overlay.insert(_overlayEntry!);
    _refreshOverlay();
  }

  void _refreshOverlay() {
    _overlayEntry?.markNeedsBuild();
    unawaited(_scrollToCurrentTarget());
  }

  GlobalKey? _keyForStep(ItineraryWalkthroughStep step) {
    switch (step) {
      case ItineraryWalkthroughStep.tripStartDate:
        return startDateKey;
      case ItineraryWalkthroughStep.tripEndDate:
        return endDateKey;
      case ItineraryWalkthroughStep.createTrip:
        return createTripButtonKey;
      case ItineraryWalkthroughStep.exploreAdd:
        return exploreAddButtonKey;
      case ItineraryWalkthroughStep.homeOpenFirstPlace:
        return homeFirstPlaceArrowKey;
      case ItineraryWalkthroughStep.detailsPlan:
        return detailsPlanButtonKey;
      case ItineraryWalkthroughStep.planSheetChooseDays:
        return planSheetDaySelectorKey;
    }
  }

  Rect? targetRectInGlobal(ItineraryWalkthroughStep step) {
    final key = _keyForStep(step);
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    final offset = render.localToGlobal(Offset.zero);
    return offset & render.size;
  }

  Future<void> _scrollToCurrentTarget() async {
    final step = _step.value;
    if (step == null) return;
    final key = _keyForStep(step);
    final ctx = key?.currentContext;
    if (ctx == null) return;

    try {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 80));
    _overlayEntry?.markNeedsBuild();
  }

  _StepCopy stepCopy(BuildContext context, ItineraryWalkthroughStep step) {
    final n = step.index + 1;
    String bodyKey;
    switch (step) {
      case ItineraryWalkthroughStep.tripStartDate:
        bodyKey = 'walkthrough_step1_body';
        break;
      case ItineraryWalkthroughStep.tripEndDate:
        bodyKey = 'walkthrough_step2_body';
        break;
      case ItineraryWalkthroughStep.createTrip:
        bodyKey = 'walkthrough_step3_body';
        break;
      case ItineraryWalkthroughStep.exploreAdd:
        bodyKey = 'walkthrough_step4_body';
        break;
      case ItineraryWalkthroughStep.homeOpenFirstPlace:
        bodyKey = 'walkthrough_step5_body';
        break;
      case ItineraryWalkthroughStep.detailsPlan:
        bodyKey = 'walkthrough_step6_body';
        break;
      case ItineraryWalkthroughStep.planSheetChooseDays:
        bodyKey = 'walkthrough_step7_body';
        break;
    }

    return _StepCopy(
      progressLabel: _localizedStepOf(context, n, totalSteps),
      body: _localizedOrKey(context, bodyKey),
      fallbackHint: _localizedOrKey(context, 'walkthrough_fallback_step$n'),
      backLabel: _localizedOrKey(context, 'walkthrough_back'),
      skipLabel: _localizedOrKey(context, 'walkthrough_skip'),
      nextLabel: _localizedOrKey(context, 'walkthrough_next'),
      finishLabel: _localizedOrKey(context, 'walkthrough_finish'),
    );
  }

  /// Resolves [key] via [context.tr], with a readable fallback if assets are stale.
  String _localizedOrKey(BuildContext context, String key) {
    final value = context.tr(key);
    if (value == key) return _englishWalkthroughFallback(key);
    return value;
  }

  String _localizedStepOf(BuildContext context, int current, int total) {
    final value = context.tr('walkthrough_step_of', {
      'current': '$current',
      'total': '$total',
    });
    if (value == 'walkthrough_step_of' || value.contains('{current}')) {
      return 'Step $current of $total';
    }
    return value;
  }

  String _englishWalkthroughFallback(String key) {
    const map = <String, String>{
      'walkthrough_step1_body': 'Select your trip start date.',
      'walkthrough_step2_body': 'Select your trip ending date.',
      'walkthrough_step3_body': 'Tap to create your trip.',
      'walkthrough_step4_body':
          'Tap "Explore & Add" to find places for your trip.',
      'walkthrough_step5_body':
          'Open a place from the list by tapping the arrow to view its details.',
      'walkthrough_step6_body': 'Tap "Plan" to add this place to your trip.',
      'walkthrough_step7_body':
          'Select the day(s) you want to visit this place, tap Save, then choose the visit time if required.',
      'walkthrough_back': 'Back',
      'walkthrough_next': 'Next',
      'walkthrough_skip': 'Skip',
      'walkthrough_finish': 'Finish',
    };
    return map[key] ?? key;
  }
}

enum ItineraryWalkthroughStep {
  tripStartDate,
  tripEndDate,
  createTrip,
  exploreAdd,
  homeOpenFirstPlace,
  detailsPlan,
  planSheetChooseDays,
}

extension _ItineraryWalkthroughStepNav on ItineraryWalkthroughStep {
  int get index => ItineraryWalkthroughStep.values.indexOf(this);

  ItineraryWalkthroughStep? get previous =>
      index > 0 ? ItineraryWalkthroughStep.values[index - 1] : null;

  ItineraryWalkthroughStep? get next =>
      index < ItineraryWalkthroughStep.values.length - 1
          ? ItineraryWalkthroughStep.values[index + 1]
          : null;
}

class _StepCopy {
  final String progressLabel;
  final String body;
  final String fallbackHint;
  final String backLabel;
  final String skipLabel;
  final String nextLabel;
  final String finishLabel;

  const _StepCopy({
    required this.progressLabel,
    required this.body,
    required this.fallbackHint,
    required this.backLabel,
    required this.skipLabel,
    required this.nextLabel,
    required this.finishLabel,
  });
}

// -----------------------------------------------------------------------------
// Full-screen overlay: dimmer with cut-out, scrollable card, nav buttons.
// -----------------------------------------------------------------------------

class _ItineraryWalkthroughOverlay extends StatefulWidget {
  final ItineraryWalkthroughController controller;

  const _ItineraryWalkthroughOverlay({required this.controller});

  @override
  State<_ItineraryWalkthroughOverlay> createState() =>
      _ItineraryWalkthroughOverlayState();
}

class _ItineraryWalkthroughOverlayState
    extends State<_ItineraryWalkthroughOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.stepListenable.addListener(_onStepChanged);
  }

  @override
  void dispose() {
    widget.controller.stepListenable.removeListener(_onStepChanged);
    super.dispose();
  }

  void _onStepChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.controller._scrollToCurrentTarget());
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final activeStep = c.step;
    if (activeStep == null) return const SizedBox.shrink();
    final copy = c.stepCopy(context, activeStep);
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final targetRect = c.targetRectInGlobal(activeStep);
    final hole = targetRect != null
        ? targetRect.inflate(10)
        : null;

    final cardLayout = _computeCardPosition(
      screen: screen,
      padding: padding,
      hole: hole,
    );

    final card = _WalkthroughCard(
      copy: copy,
      stepIndex: activeStep.index,
      totalSteps: ItineraryWalkthroughController.totalSteps,
      isLastStep: activeStep == ItineraryWalkthroughStep.planSheetChooseDays,
      showTargetMissing: hole == null,
      onBack: c.goToPreviousStep,
      onNext: c.goToNextStep,
      onSkip: c.skip,
      onFinish: () => unawaited(c.finish()),
    );

    // Full-screen stack without Material — transparent Material blocked all hits.
    // Card uses top OR bottom only so the hole stays tappable.
    return SizedBox.expand(
      child: Stack(
        children: [
          if (hole != null)
            _DimAroundHole(hole: hole, screen: screen)
          else
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.72),
              child: const SizedBox.expand(),
            ),
          if (hole != null)
            Positioned.fromRect(
              rect: hole,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary, width: 2.5),
                  ),
                ),
              ),
            ),
          _positionedWalkthroughCard(cardLayout, card),
        ],
      ),
    );
  }
}

/// Places the tooltip without a full-height [Positioned] (that blocked the hole).
Widget _positionedWalkthroughCard(_CardLayout layout, Widget card) {
  const horizontal = 16.0;
  if (layout.top != null) {
    return Positioned(
      left: horizontal,
      right: horizontal,
      top: layout.top,
      child: card,
    );
  }
  return Positioned(
    left: horizontal,
    right: horizontal,
    bottom: layout.bottom!,
    child: card,
  );
}

class _CardLayout {
  final double? top;
  final double? bottom;

  const _CardLayout({this.top, this.bottom})
      : assert(top == null || bottom == null, 'Use top or bottom, not both');
}

_CardLayout _computeCardPosition({
  required Size screen,
  required EdgeInsets padding,
  required Rect? hole,
}) {
  const gap = 14.0;
  const estimatedCardHeight = 280.0;
  final topSafe = padding.top + 12;
  final bottomSafe = padding.bottom + 12;

  double centeredTop() {
    return ((screen.height - estimatedCardHeight) / 2).clamp(
      topSafe,
      screen.height - bottomSafe - estimatedCardHeight,
    );
  }

  if (hole == null) {
    return _CardLayout(top: centeredTop());
  }

  final spaceBelow = screen.height - hole.bottom - bottomSafe;
  final spaceAbove = hole.top - topSafe;

  if (spaceBelow >= estimatedCardHeight + gap) {
    return _CardLayout(
      top: (hole.bottom + gap).clamp(topSafe, screen.height),
    );
  }

  if (spaceAbove >= estimatedCardHeight + gap) {
    return _CardLayout(
      bottom: (screen.height - hole.top + gap).clamp(bottomSafe, screen.height),
    );
  }

  return _CardLayout(top: centeredTop());
}

/// Four dim panels around [hole] so the target stays tappable.
class _DimAroundHole extends StatelessWidget {
  final Rect hole;
  final Size screen;

  const _DimAroundHole({required this.hole, required this.screen});

  @override
  Widget build(BuildContext context) {
    final color = Colors.black.withValues(alpha: 0.72);

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: hole.top.clamp(0.0, screen.height),
          child: ColoredBox(color: color),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: hole.bottom,
          bottom: 0,
          child: ColoredBox(color: color),
        ),
        Positioned(
          left: 0,
          top: hole.top,
          width: hole.left.clamp(0.0, screen.width),
          height: hole.height,
          child: ColoredBox(color: color),
        ),
        Positioned(
          left: hole.right,
          top: hole.top,
          right: 0,
          height: hole.height,
          child: ColoredBox(color: color),
        ),
      ],
    );
  }
}

class _WalkthroughCard extends StatelessWidget {
  final _StepCopy copy;
  final int stepIndex;
  final int totalSteps;
  final bool isLastStep;
  final bool showTargetMissing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  const _WalkthroughCard({
    required this.copy,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLastStep,
    required this.showTargetMissing,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final maxCardHeight = MediaQuery.sizeOf(context).height * 0.42;

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: maxCardHeight,
      ),
      child: Material(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        color: theme.cardTheme.color ?? Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.progressLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              _ProgressDots(
                currentIndex: stepIndex,
                total: totalSteps,
                activeColor: primary,
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxCardHeight - 130,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (showTargetMissing) ...[
                        const SizedBox(height: 10),
                        Text(
                          copy.fallbackHint,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: stepIndex > 0 ? onBack : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        copy.backLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        copy.skipLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: isLastStep ? onFinish : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isLastStep ? copy.finishLabel : copy.nextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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

class _ProgressDots extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Color activeColor;

  const _ProgressDots({
    required this.currentIndex,
    required this.total,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == currentIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? activeColor
                  : activeColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Compact step card shown inside the plan day bottom sheet (step 7).
class ItineraryWalkthroughSheetBanner extends StatelessWidget {
  const ItineraryWalkthroughSheetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ItineraryWalkthroughController.instance;

    return ListenableBuilder(
      listenable: controller.stepListenable,
      builder: (context, _) {
        final step = controller.step;
        if (step != ItineraryWalkthroughStep.planSheetChooseDays) {
          return const SizedBox.shrink();
        }

        final activeStep = step!;
        final copy = controller.stepCopy(context, activeStep);
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.progressLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              _ProgressDots(
                currentIndex: activeStep.index,
                total: ItineraryWalkthroughController.totalSteps,
                activeColor: primary,
              ),
              const SizedBox(height: 10),
              Text(
                copy.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.skip,
                  child: Text(copy.skipLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
