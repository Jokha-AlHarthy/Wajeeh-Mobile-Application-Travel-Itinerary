import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../localization/app_localizations.dart';
import '../services/full_trip_route_place_resolver.dart';
import '../utils/day_route_marker_bitmap.dart';

/// Map of the entire saved trip: each day has its own color, markers numbered per day.
class FullTripRouteMapScreen extends StatefulWidget {
  const FullTripRouteMapScreen({
    super.key,
    required this.title,
    required this.pins,
    required this.dayPolylines,
    this.skippedFromGeocode = 0,
  });

  final String title;
  final List<FullTripPin> pins;
  final List<FullTripDayPolyline> dayPolylines;
  final int skippedFromGeocode;

  @override
  State<FullTripRouteMapScreen> createState() => _FullTripRouteMapScreenState();
}

class _FullTripRouteMapScreenState extends State<FullTripRouteMapScreen> {
  GoogleMapController? _mapController;
  Map<MarkerId, Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _iconsLoaded = false;

  static const LatLng _fallbackCenter = LatLng(23.588, 58.3829);

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    if (widget.pins.isEmpty) {
      if (mounted) setState(() => _iconsLoaded = true);
      return;
    }
    final next = <MarkerId, Marker>{};
    for (final pin in widget.pins) {
      final icon = await numberedRouteMarkerBitmap(
        order: pin.orderInDay,
        fill: pin.color,
      );
      final snippet = _snippet(pin);
      next[MarkerId('d${pin.dayListIndex}_p${pin.orderInDay}')] = Marker(
        markerId: MarkerId('d${pin.dayListIndex}_p${pin.orderInDay}'),
        position: pin.position,
        icon: icon,
        infoWindow: InfoWindow(
          title: pin.name,
          snippet: snippet.isEmpty ? '' : snippet,
        ),
      );
    }
    if (!mounted) return;
    final lines = <Polyline>{};
    for (final seg in widget.dayPolylines) {
      lines.add(
        Polyline(
          polylineId: PolylineId('day_${seg.dayListIndex}'),
          points: seg.points,
          color: seg.color,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    setState(() {
      _markers = next;
      _polylines = lines;
      _iconsLoaded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  String _snippet(FullTripPin pin) {
    final parts = <String>[pin.dayHeading];
    if (pin.timeLabel.isNotEmpty) parts.add(pin.timeLabel);
    if (pin.activityLabel.isNotEmpty) parts.add(pin.activityLabel);
    return parts.join('\n');
  }

  Future<void> _fitCamera() async {
    final c = _mapController;
    if (c == null || !mounted) return;
    if (widget.pins.isEmpty) return;

    if (widget.pins.length == 1) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(widget.pins.first.position, 14),
      );
      return;
    }

    var minLat = widget.pins.first.position.latitude;
    var maxLat = minLat;
    var minLng = widget.pins.first.position.longitude;
    var maxLng = minLng;
    for (final p in widget.pins) {
      minLat = math.min(minLat, p.position.latitude);
      maxLat = math.max(maxLat, p.position.latitude);
      minLng = math.min(minLng, p.position.longitude);
      maxLng = math.max(maxLng, p.position.longitude);
    }
    const pad = 0.012;
    final sw = LatLng(minLat - pad, minLng - pad);
    final ne = LatLng(maxLat + pad, maxLng + pad);
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          72,
        ),
      );
    } catch (_) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          11,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = widget.pins.isNotEmpty
        ? widget.pins.first.position
        : _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (widget.skippedFromGeocode > 0)
            Material(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('map_locations_partial_fail'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: !_iconsLoaded
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initial,
                          zoom: widget.pins.length == 1 ? 14 : 10,
                        ),
                        markers: Set<Marker>.of(_markers.values),
                        polylines: _polylines,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitCamera();
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: math.max(24, constraints.maxHeight * 0.06),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
