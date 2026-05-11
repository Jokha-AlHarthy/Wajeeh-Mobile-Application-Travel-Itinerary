// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// A minimal fake implementation of the Google Maps platform interface for
// widget tests. It returns a simple Container for the platform view so tests
// don't require native map rendering.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

Stream<T> _eventsOfType<T extends MapEvent<dynamic>>(
  StreamController<MapEvent<dynamic>> controller,
) {
  return controller.stream.where((e) => e is T).cast<T>();
}

class FakeGoogleMapsFlutterPlatform extends GoogleMapsFlutterPlatform {
  /// Whether `dispose` has been called.
  bool disposed = false;

  /// Tracks view creation IDs to avoid completing the same future twice.
  final Set<int> _createdViewIds = <int>{};

  /// Stream controller to inject events for testing.
  final StreamController<MapEvent<dynamic>> mapEventStreamController =
      StreamController<MapEvent<dynamic>>.broadcast();

  @override
  Future<void> init(int mapId) async {}

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateHeatmaps(
    HeatmapUpdates heatmapUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> clearTileCache(
    TileOverlayId tileOverlayId, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCameraWithConfiguration(
    CameraUpdate cameraUpdate,
    CameraUpdateAnimationConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> setMapStyle(String? mapStyle, {required int mapId}) async {}

  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async {
    return LatLngBounds(
      southwest: const LatLng(0, 0),
      northeast: const LatLng(0, 0),
    );
  }

  @override
  Future<ScreenCoordinate> getScreenCoordinate(
    LatLng latLng, {
    required int mapId,
  }) async {
    return const ScreenCoordinate(x: 0, y: 0);
  }

  @override
  Future<LatLng> getLatLng(
    ScreenCoordinate screenCoordinate, {
    required int mapId,
  }) async {
    return const LatLng(0, 0);
  }

  @override
  Future<void> showMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {}

  @override
  Future<void> hideMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {}

  @override
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) async {
    return false;
  }

  @override
  Future<double> getZoomLevel({required int mapId}) async {
    return 0.0;
  }

  @override
  Future<Uint8List?> takeSnapshot({required int mapId}) async {
    return null;
  }

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) {
    return _eventsOfType<CameraMoveStartedEvent>(mapEventStreamController);
  }

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) {
    return _eventsOfType<CameraMoveEvent>(mapEventStreamController);
  }

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) {
    return _eventsOfType<CameraIdleEvent>(mapEventStreamController);
  }

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) {
    return _eventsOfType<MarkerTapEvent>(mapEventStreamController);
  }

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) {
    return _eventsOfType<InfoWindowTapEvent>(mapEventStreamController);
  }

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) {
    return _eventsOfType<MarkerDragStartEvent>(mapEventStreamController);
  }

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) {
    return _eventsOfType<MarkerDragEvent>(mapEventStreamController);
  }

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) {
    return _eventsOfType<MarkerDragEndEvent>(mapEventStreamController);
  }

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) {
    return _eventsOfType<PolylineTapEvent>(mapEventStreamController);
  }

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) {
    return _eventsOfType<PolygonTapEvent>(mapEventStreamController);
  }

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) {
    return _eventsOfType<CircleTapEvent>(mapEventStreamController);
  }

  @override
  Stream<MapTapEvent> onTap({required int mapId}) {
    return _eventsOfType<MapTapEvent>(mapEventStreamController);
  }

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) {
    return _eventsOfType<MapLongPressEvent>(mapEventStreamController);
  }

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) {
    return _eventsOfType<ClusterTapEvent>(mapEventStreamController);
  }

  @override
  Stream<GroundOverlayTapEvent> onGroundOverlayTap({required int mapId}) {
    return _eventsOfType<GroundOverlayTapEvent>(mapEventStreamController);
  }

  @override
  void dispose({required int mapId}) {
    disposed = true;
  }

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    MapConfiguration mapConfiguration = const MapConfiguration(),
  }) {
    // GoogleMap completes an internal completer in onPlatformViewCreated; only
    // call it once per creationId.
    if (_createdViewIds.add(creationId)) {
      onPlatformViewCreated(creationId);
    }
    return const SizedBox.shrink();
  }
}

