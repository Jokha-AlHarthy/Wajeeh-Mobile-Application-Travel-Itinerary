import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/place_review_preview.dart';
import '../providers/travel_provider.dart';
import '../services/itinerary_walkthrough.dart';
import '../services/plan_place_trip_flow.dart';
import '../services/user_location_helper.dart';
import '../utils/gmail_compose.dart';
import '../utils/haversine_km.dart';
import '../utils/pdf_download.dart';
import '../utils/trip_pdf_export.dart';

class DisplayResultScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const DisplayResultScreen({
    super.key,
    required this.place,
  });

  @override
  State<DisplayResultScreen> createState() => _DisplayResultScreenState();
}

class _DisplayResultScreenState extends State<DisplayResultScreen> {
  final GlobalKey _planButtonKey = GlobalKey();

  /// Resolved line for the distance row (localized). Empty while loading.
  String _distanceLine = '';
  bool _distanceLoading = true;

  /// Up to five review rows (API or rating-based fallbacks).
  List<PlaceReviewPreview> _reviewCards = const [];

  bool _reviewsResolved = false;

  @override
  void initState() {
    super.initState();
    final w = ItineraryWalkthroughController.instance;
    w.detailsPlanButtonKey = _planButtonKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDistanceAndReviews();
      if (w.step == ItineraryWalkthroughStep.detailsPlan) {
        // Ensure the Plan button is visible (overlay blocks manual scrolling).
        final ctx = _planButtonKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 1.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        w.showIfNeeded(context);
      }
    });
  }

  /// When [assets/lang/*.json] is stale (e.g. hot reload), [context.tr] can
  /// return the key unchanged — still show a real km estimate.
  String _approxDistanceFromYouLine(BuildContext context, double km) {
    final kmStr = formatApproxKm(km);
    final localized = context.tr('approx_distance_from_you', {'km': kmStr});
    if (localized != 'approx_distance_from_you' &&
        !localized.contains('{km}')) {
      return localized;
    }
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return 'المسافة التقريبية: $kmStr كم من موقعك';
    }
    return 'Approx. distance: $kmStr km from you';
  }

  Future<void> _loadDistanceAndReviews() async {
    try {
      if (!mounted) return;
      final travel = context.read<TravelProvider>();
      final ll = _extractLatLng(widget.place);

      if (ll.lat == null || ll.lng == null) {
        if (!mounted) return;
        final unavailable = context.tr('distance_not_available');
        setState(() {
          _distanceLoading = false;
          _distanceLine = unavailable;
        });
      } else {
        final pos = await UserLocationHelper.tryGetEstimatedPosition();
        if (!mounted) return;
        if (pos != null) {
          final km = haversineKm(
            pos.latitude,
            pos.longitude,
            ll.lat!,
            ll.lng!,
          );
          if (!mounted) return;
          final line = _approxDistanceFromYouLine(context, km);
          setState(() {
            _distanceLoading = false;
            _distanceLine = line;
          });
        } else {
          final perm = await Geolocator.checkPermission();
          if (!mounted) return;
          final denied = perm == LocationPermission.denied ||
              perm == LocationPermission.deniedForever;
          final line = denied
              ? context.tr('enable_location_for_distance')
              : context.tr('distance_not_available');
          setState(() {
            _distanceLoading = false;
            _distanceLine = line;
          });
        }
      }

      if (!mounted) return;
      var cards = _parseReviewsFromPlace(widget.place['reviews']);
      final suffix = _placesApiPlaceIdSuffix(widget.place);
      if (cards.length < 5 && suffix != null && suffix.isNotEmpty) {
        try {
          final details = await travel.getDetails(suffix);
          if (!mounted) return;
          final fromApi = _parseReviewsFromPlace(details['reviews']);
          if (fromApi.length > cards.length) {
            cards = fromApi;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      cards = cards.take(5).toList();
      if (cards.isEmpty) {
        cards = _syntheticReviewCards(context, travel, widget.place);
      }
      if (!mounted) return;
      final resolvedCards = cards.take(5).toList();
      setState(() {
        _reviewCards = resolvedCards;
        _reviewsResolved = true;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = context.tr('distance_not_available');
      setState(() {
        _reviewsResolved = true;
        _distanceLoading = false;
        if (_distanceLine.isEmpty) {
          _distanceLine = fallback;
        }
      });
    }
  }

  static String? _placesApiPlaceIdSuffix(Map<String, dynamic> place) {
    final name = place['name']?.toString().trim() ?? '';
    const prefix = 'places/';
    if (name.startsWith(prefix) && name.length > prefix.length) {
      return name.substring(prefix.length);
    }
    final id = place['id']?.toString().trim() ?? '';
    if (id.startsWith(prefix) && id.length > prefix.length) {
      return id.substring(prefix.length);
    }
    if (id.isNotEmpty) return id;
    return null;
  }

  static List<PlaceReviewPreview> _parseReviewsFromPlace(dynamic raw) {
    if (raw is! List || raw.isEmpty) return [];
    final out = <PlaceReviewPreview>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final p = PlaceReviewPreview.tryParse(Map<String, dynamic>.from(e));
      if (p != null) out.add(p);
    }
    return out;
  }

  List<PlaceReviewPreview> _syntheticReviewCards(
    BuildContext context,
    TravelProvider travel,
    Map<String, dynamic> place,
  ) {
    final rating = (place['rating'] as num?)?.toDouble();
    final count = (place['userRatingCount'] as num?)?.toInt() ?? 0;
    final desc = travel.placeDescription(place).trim();
    final out = <PlaceReviewPreview>[];

    if (rating != null && rating > 0) {
      final body = count > 0
          ? context.tr('review_aggregate_body', {
              'rating': rating.toStringAsFixed(1),
              'count': count.toString(),
            })
          : rating.toStringAsFixed(1);
      out.add(
        PlaceReviewPreview(
          authorName: context.tr('review_visitors_label'),
          rating: rating,
          text: body,
        ),
      );
    }

    if (desc.isNotEmpty) {
      final preview = desc.length > 140 ? '${desc.substring(0, 137)}...' : desc;
      final rVal = (rating != null && rating > 0) ? rating : 0.0;
      out.add(
        PlaceReviewPreview(
          authorName: context.tr('review_about_place'),
          rating: rVal,
          text: preview,
        ),
      );
    }

    return out.take(5).toList();
  }

  static const Color _starYellow = Color(0xFFF4B400);
  static const Color _shareOrange = Color(0xFFF5A623);

  static ({double? lat, double? lng}) _extractLatLng(Map<String, dynamic> place) {
    final loc = place['location'];
    if (loc is Map) {
      final lat = loc['latitude'];
      final lng = loc['longitude'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
    }

    // Fallback shapes (some APIs use geometry/location).
    final geometry = place['geometry'];
    if (geometry is Map) {
      final gLoc = geometry['location'];
      if (gLoc is Map) {
        final lat = gLoc['lat'] ?? gLoc['latitude'];
        final lng = gLoc['lng'] ?? gLoc['longitude'];
        if (lat is num && lng is num) {
          return (lat: lat.toDouble(), lng: lng.toDouble());
        }
      }
    }

    return (lat: null, lng: null);
  }

  static Future<void> _openDirectionsInGoogleMaps(
    BuildContext context, {
    required String title,
    required String address,
    required Map<String, dynamic> place,
  }) async {
    final ll = _extractLatLng(place);
    final hasLatLng = ll.lat != null && ll.lng != null;

    // Leave origin empty: Google Maps uses the user's current location.
    final destinationText = hasLatLng
        ? '${ll.lat},${ll.lng}'
        : (address.trim().isNotEmpty ? address.trim() : title.trim());

    // Prefer opening the Google Maps app; then fall back to browser.
    // - Android app deep link: google.navigation:q=...
    // - iOS app deep link: comgooglemaps://?daddr=...
    final appUri = hasLatLng
        ? Uri.parse('google.navigation:q=$destinationText&mode=d')
        : Uri.parse('google.navigation:q=${Uri.encodeComponent(destinationText)}&mode=d');

    final iosAppUri = hasLatLng
        ? Uri.parse('comgooglemaps://?daddr=$destinationText&directionsmode=driving')
        : Uri.parse(
            'comgooglemaps://?daddr=${Uri.encodeComponent(destinationText)}&directionsmode=driving',
          );

    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destinationText)}&travelmode=driving',
    );

    try {
      final launched = (await canLaunchUrl(appUri) &&
              await launchUrl(appUri, mode: LaunchMode.externalApplication)) ||
          (await canLaunchUrl(iosAppUri) &&
              await launchUrl(iosAppUri, mode: LaunchMode.externalApplication)) ||
          (await launchUrl(webUri, mode: LaunchMode.externalApplication));

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('could_not_open_maps'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('could_not_open_maps'))),
        );
      }
    }
  }

  static void _openGalleryViewer(
    BuildContext context, {
    required List<String> imageUrls,
    required int initialIndex,
  }) {
    if (imageUrls.isEmpty) return;
    final startIndex = initialIndex.clamp(0, imageUrls.length - 1);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          final controller = PageController(initialPage: startIndex);
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final url = imageUrls[index];
                      return Center(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) {
                              return const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 48,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travel = context.read<TravelProvider>();
    final title = travel.placeName(widget.place);
    final address = travel.placeAddress(widget.place);
    final description = travel.placeDescription(widget.place);
    final ratingText = travel.placeRatingText(widget.place);
    final link = travel.placeLink(widget.place);
    final photos = travel.photoUrls(widget.place);
    final coverImage = travel.firstPhotoUrl(widget.place) ??
        "https://via.placeholder.com/900x600?text=No+Image";
    final showPriceRow = travel.placePriceShowInDetail(widget.place);
    final priceDisplayText = travel.placePriceDisplayText(widget.place);
    final showStartFrom = travel.placePriceShowStartFrom(widget.place);
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final mutedLabel = theme.brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF7A7A7A);
    final backBubbleColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.9);
    final placeCoords = _extractLatLng(widget.place);
    final placeHasCoords = placeCoords.lat != null && placeCoords.lng != null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  PositionedDirectional(
                    top: 14,
                    start: 14,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: backBubbleColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 18,
                        color: onSurface,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                color: scaffoldBg,
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: onSurface,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: _starYellow,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ratingText,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showPriceRow) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: onSurface,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        showStartFrom
                                            ? context.tr('approx_per_night')
                                            : context.tr('budget'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: mutedLabel,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        priceDisplayText,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: onSurface,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _distanceLoading && placeHasCoords
                                    ? Text(
                                        '…',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: mutedLabel,
                                        ),
                                      )
                                    : Text(
                                        _distanceLine.isNotEmpty
                                            ? _distanceLine
                                            : context.tr(
                                                'distance_not_available',
                                              ),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: context.tr('open_in_google_maps'),
                            icon: const Icon(Icons.map_outlined, size: 22),
                            color: theme.colorScheme.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: () => _openDirectionsInGoogleMaps(
                              context,
                              title: title,
                              address: address,
                              place: widget.place,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("details"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr("galleries"),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: (photos.isEmpty ? [coverImage] : photos)
                              .asMap()
                              .entries
                              .map(
                                (e) => _galleryImageNetwork(
                                  e.value,
                                  theme,
                                  onTap: () => _openGalleryViewer(
                                    context,
                                    imageUrls:
                                        (photos.isEmpty ? [coverImage] : photos),
                                    initialIndex: e.key,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: _starYellow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('reviews_section_title'),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!_reviewsResolved)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      else if (_reviewCards.isEmpty)
                        Text(
                          context.tr('no_reviews_available_yet'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: mutedLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        ..._reviewCards.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _reviewPreviewCard(theme, r, onSurface),
                          ),
                        ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 360;

                          final shareBg = theme.brightness == Brightness.light
                              ? _shareOrange
                              : theme.colorScheme.primary;

                          final priceWidget = showStartFrom
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr("approx_per_night"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: mutedLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      priceDisplayText.isNotEmpty
                                          ? priceDisplayText
                                          : context.tr("omr_dash"),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink();

                          final buttonsWidget = Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    key: _planButtonKey,
                                    onPressed: () async =>
                                        handlePlanTap(context, widget.place),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: Text(
                                      context.tr("plan"),
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => _openShareSheet(
                                      context,
                                      title: title,
                                      address: address,
                                      description: description,
                                      ratingText: ratingText,
                                      imageUrl: coverImage,
                                      link: link,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: shareBg,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: Text(
                                      context.tr("share"),
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (isSmallScreen) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                priceWidget,
                                if (showStartFrom) const SizedBox(height: 18),
                                buttonsWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: priceWidget),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: buttonsWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewPreviewCard(
    ThemeData theme,
    PlaceReviewPreview r,
    Color onSurface,
  ) {
    final borderColor = theme.dividerTheme.color ??
        onSurface.withValues(alpha: 0.14);
    final fill = theme.brightness == Brightness.dark
        ? onSurface.withValues(alpha: 0.06)
        : onSurface.withValues(alpha: 0.04);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.authorName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
              if (r.rating > 0) ...[
                const Icon(Icons.star_rounded, size: 16, color: _starYellow),
                const SizedBox(width: 2),
                Text(
                  r.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ],
            ],
          ),
          if (r.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: onSurface.withValues(alpha: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _openShareSheet(
    BuildContext parentContext, {
    required String title,
    required String address,
    required String description,
    required String ratingText,
    required String imageUrl,
    required String link,
  }) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor:
          Theme.of(parentContext).cardTheme.color ??
              Theme.of(parentContext).colorScheme.surface,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final onSurface = sheetTheme.colorScheme.onSurface;
        final fieldFill = sheetTheme.brightness == Brightness.dark
            ? const Color(0xFF4A5D7A)
            : const Color(0xFFF3F4F6);
        final copyBtnBg =
            sheetTheme.cardTheme.color ?? sheetTheme.colorScheme.surface;

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetContext.tr("share_this_destination"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: sheetTheme.dividerTheme.color ??
                    onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: onSurface,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_border_rounded,
                              size: 16,
                              color: _starYellow,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ratingText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                initialValue: link,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: copyBtnBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(sheetContext.tr("link_copied"))),
                        );
                      },
                      child: Text(
                        sheetContext.tr("copy"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sheetTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shareIcon(
                    sheetContext,
                    'images/gmail.png',
                    sheetContext.tr('gmail'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _runPlaceGmailShare(
                        parentContext,
                        title: title,
                        description: description,
                        link: link,
                      );
                    },
                  ),
                  _shareIcon(
                    sheetContext,
                    'images/instagram.png',
                    sheetContext.tr('instagram'),
                  ),
                  _shareIcon(
                    sheetContext,
                    'images/whatsapp.png',
                    sheetContext.tr('whatsapp'),
                  ),
                  _shareIcon(
                    sheetContext,
                    'images/download.png',
                    sheetContext.tr('download'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _runPlacePdfDownload(
                        parentContext,
                        title: title,
                        description: description,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _galleryImageNetwork(
    String url,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    final borderColor = theme.dividerTheme.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.15);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 10),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  static Widget _shareIcon(
    BuildContext context,
    String assetPath,
    String label, {
    VoidCallback? onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return column;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: column,
        ),
      ),
    );
  }
}

Future<void> _runPlaceGmailShare(
  BuildContext context, {
  required String title,
  required String description,
  required String link,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  var body = '$title\n\n${description.trim()}\n\n$link';
  if (body.length > 12000) {
    body = '${body.substring(0, 12000)}\n…';
  }
  final ok = await openGmailCompose(subject: title, body: body);
  if (!context.mounted) return;
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(content: Text(context.tr('gmail_open_failed'))),
    );
  }
}

Future<void> _runPlacePdfDownload(
  BuildContext context, {
  required String title,
  required String description,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildPlaceSharePdfBytes(
      title: title,
      description: description,
    );
    final outcome = await savePdfToDevice(title, bytes);
    if (!context.mounted) return;
    switch (outcome) {
      case PdfSaveOutcome.savedToChosenPath:
      case PdfSaveOutcome.presentedShareSheet:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('pdf_downloaded_successfully'))),
        );
        break;
      case PdfSaveOutcome.cancelledByUser:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr('pdf_save_cancelled'))),
        );
        break;
    }
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.tr('pdf_save_failed'))),
    );
  }
}

/// Plan button: draft trip → day/time sheet; otherwise existing vs new trip flow.
Future<void> handlePlanTap(
  BuildContext screenContext,
  Map<String, dynamic> place,
) async {
  await runPlanPlaceToTripFlow(screenContext, place);
}
