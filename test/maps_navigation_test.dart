import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/localization/app_localizations.dart';
import 'package:wajeeh/pages/Location_page.dart';
import 'package:wajeeh/providers/travel_provider.dart';

import 'support/fake_google_maps_flutter_platform.dart';

/// Counts camera animation calls routed through the maps platform (see
/// `Location_page` `_initLocation` and suggestion `onTap`).
class RecordingFakeMaps extends FakeGoogleMapsFlutterPlatform {
  int animateCameraCalls = 0;

  void resetCounts() {
    animateCameraCalls = 0;
  }

  void fullReset() {
    resetCounts();
    resetTestState();
  }

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {
    animateCameraCalls++;
  }

  @override
  Future<void> animateCameraWithConfiguration(
    CameraUpdate cameraUpdate,
    CameraUpdateAnimationConfiguration configuration, {
    required int mapId,
  }) async {
    animateCameraCalls++;
  }
}

final RecordingFakeMaps _recordingMaps = RecordingFakeMaps();

void _setGeolocatorMock({
  bool serviceEnabled = true,
  int checkPermission = 2,
  int requestPermission = 2,
  bool throwOnPosition = false,
  double latitude = 23.5880,
  double longitude = 58.3829,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/geolocator'), (
    MethodCall call,
  ) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return serviceEnabled;
      case 'checkPermission':
        return checkPermission;
      case 'requestPermission':
        return requestPermission;
      case 'getCurrentPosition':
        if (throwOnPosition) {
          throw PlatformException(code: 'TEST', message: 'position_unavailable');
        }
        return <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': 5.0,
          'altitude': 0.0,
          'altitude_accuracy': 0.0,
          'heading': 0.0,
          'heading_accuracy': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
        };
      default:
        return null;
    }
  });
}

void _clearGeolocatorMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/geolocator'),
    null,
  );
}

Finder _locationSearchField() => find.byType(TextField, skipOffstage: false);

const int _kDenied = 0;
const int _kWhileInUse = 2;

class _StubTravelForMaps extends TravelProvider {
  _StubTravelForMaps(this._autocomplete);

  final Future<List<Map<String, dynamic>>> Function(String query) _autocomplete;

  @override
  Future<List<Map<String, dynamic>>> autocompletePlaces(String query) async {
    return _autocomplete(query);
  }
}

Map<String, dynamic> _place(String name, double lat, double lng) {
  return <String, dynamic>{
    'displayName': <String, dynamic>{'text': name},
    'formattedAddress': 'Test address',
    'location': <String, dynamic>{'latitude': lat, 'longitude': lng},
  };
}

GoogleMap _googleMapWidget(WidgetTester tester) =>
    tester.widget<GoogleMap>(find.byType(GoogleMap));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var previousOnError = FlutterError.onError;

  setUp(() {
    previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('google_fonts') ||
          message.contains('GoogleFonts') ||
          message.contains('Failed to load font')) {
        return;
      }
      previousOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
  });

  setUpAll(() {
    GoogleMapsFlutterPlatform.instance = _recordingMaps;
  });

  tearDownAll(() {
    _clearGeolocatorMock();
    GoogleMapsFlutterPlatform.instance = MethodChannelGoogleMapsFlutter();
  });

  group('Maps & navigation (LocationSelectionPage)', () {
    /// One [testWidgets]: fake map view IDs must be cleared between each new
    /// [LocationSelectionPage] mount (see [FakeGoogleMapsFlutterPlatform.resetTestState]).
    testWidgets(
      'GoogleMap load, camera, markers, my location, loading, errors, place selection',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var locationMountId = 0;

        Widget wrap(TravelProvider travel) {
          locationMountId++;
          return ChangeNotifierProvider<TravelProvider>.value(
            value: travel,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: LocationSelectionPage(
                key: ValueKey<String>('location_$locationMountId'),
              ),
            ),
          );
        }

        Future<void> pumpLocation(TravelProvider travel) async {
          _recordingMaps.fullReset();
          await tester.pumpWidget(wrap(travel));
          await tester.pump();
        }

        Future<void> settle(
            {Duration timeout = const Duration(seconds: 6)}) async {
          await tester.pumpAndSettle(timeout);
        }

        final emptyTravel = _StubTravelForMaps((_) async => []);

        // --- Services off: default camera, no markers (fresh State via [ValueKey]) ---
        _setGeolocatorMock(serviceEnabled: false);
        await pumpLocation(emptyTravel);
        await settle();
        var map = _googleMapWidget(tester);
        expect(find.byType(GoogleMap), findsOneWidget);
        expect(map.initialCameraPosition.target.latitude, closeTo(23.5880, 0.0001));
        expect(map.initialCameraPosition.target.longitude, closeTo(58.3829, 0.0001));
        expect(map.markers, isEmpty);
        expect(map.myLocationEnabled, isFalse);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // --- GPS success: current marker, my location, camera animation ---
        _setGeolocatorMock(
          serviceEnabled: true,
          checkPermission: _kWhileInUse,
          requestPermission: _kWhileInUse,
          latitude: 25.2048,
          longitude: 55.2708,
        );
        await pumpLocation(emptyTravel);
        await settle();
        map = _googleMapWidget(tester);
        expect(map.myLocationEnabled, isTrue);
        expect(map.markers, hasLength(1));
        expect(map.markers.single.markerId, const MarkerId('current'));
        expect(map.markers.single.position.latitude, closeTo(25.2048, 0.0001));
        expect(map.markers.single.position.longitude, closeTo(55.2708, 0.0001));
        expect(_recordingMaps.animateCameraCalls, greaterThanOrEqualTo(1));

        // --- Place search selection -> selected marker + camera ---
        _setGeolocatorMock(
          serviceEnabled: true,
          checkPermission: _kWhileInUse,
          requestPermission: _kWhileInUse,
          latitude: 25.2048,
          longitude: 55.2708,
        );
        final suggestTravel = _StubTravelForMaps(
          (_) async => [
            _place('Map Test Plaza', 25.1972, 55.2744),
          ],
        );
        await pumpLocation(suggestTravel);
        await settle();
        final animAfterGpsOnSuggestPage = _recordingMaps.animateCameraCalls;

        await tester.enterText(_locationSearchField(), 'ma');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await settle();
        expect(find.text('Map Test Plaza'), findsOneWidget);
        await tester.tap(find.text('Map Test Plaza'));
        await settle();
        map = _googleMapWidget(tester);
        expect(map.markers, hasLength(1));
        expect(map.markers.single.markerId, const MarkerId('selected'));
        expect(map.markers.single.position.latitude, closeTo(25.1972, 0.0001));
        expect(map.markers.single.position.longitude, closeTo(55.2744, 0.0001));
        expect(
          _recordingMaps.animateCameraCalls,
          greaterThan(animAfterGpsOnSuggestPage),
        );

        // --- getCurrentPosition failure ---
        _setGeolocatorMock(
          serviceEnabled: true,
          checkPermission: _kWhileInUse,
          requestPermission: _kWhileInUse,
          throwOnPosition: true,
        );
        await pumpLocation(emptyTravel);
        await settle();
        map = _googleMapWidget(tester);
        expect(map.markers, isEmpty);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // --- Permission denied (last: may cache denied for rest of isolate) ---
        _setGeolocatorMock(
          serviceEnabled: true,
          checkPermission: _kDenied,
          requestPermission: _kDenied,
        );
        await pumpLocation(emptyTravel);
        await settle();
        map = _googleMapWidget(tester);
        expect(map.myLocationEnabled, isFalse);
        expect(map.markers, isEmpty);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}

