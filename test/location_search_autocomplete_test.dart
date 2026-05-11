import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/localization/app_localizations.dart';
import 'package:wajeeh/pages/Location_page.dart';
import 'package:wajeeh/providers/travel_provider.dart';

import 'support/fake_google_maps_flutter_platform.dart';

Finder _locationSearchTextField() =>
    find.byType(TextField, skipOffstage: false);

/// [TravelProvider.autocompletePlaces] is overridden so tests do not call the
/// real Places API. Queries are recorded for assertions.
class AutocompleteStubTravelProvider extends TravelProvider {
  AutocompleteStubTravelProvider(this._onAutocomplete);

  final Future<List<Map<String, dynamic>>> Function(String query) _onAutocomplete;

  final List<String> autocompleteQueries = [];

  @override
  Future<List<Map<String, dynamic>>> autocompletePlaces(String query) async {
    autocompleteQueries.add(query);
    return _onAutocomplete(query);
  }
}

void _setupGeolocatorMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/geolocator'), (
    MethodCall call,
  ) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return true;
      case 'checkPermission':
        return 2;
      case 'requestPermission':
        return 2;
      case 'getCurrentPosition':
        return <String, dynamic>{
          'latitude': 23.5880,
          'longitude': 58.3829,
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

void _clearGeolocatorMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/geolocator'),
    null,
  );
}

Map<String, dynamic> _place(String name, double lat, double lng) {
  return <String, dynamic>{
    'displayName': <String, dynamic>{'text': name},
    'formattedAddress': 'Test street',
    'location': <String, dynamic>{'latitude': lat, 'longitude': lng},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleMapsFlutterPlatform.instance = FakeGoogleMapsFlutterPlatform();
    _setupGeolocatorMocks();
  });

  tearDownAll(() {
    _clearGeolocatorMocks();
    GoogleMapsFlutterPlatform.instance = MethodChannelGoogleMapsFlutter();
  });

  Widget wrapLocationPage(AutocompleteStubTravelProvider travel) {
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
        home: const LocationSelectionPage(),
      ),
    );
  }

  /// One [testWidgets] avoids flaky teardown between cases (maps + geolocator).
  testWidgets('Location search autocomplete', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpPage(AutocompleteStubTravelProvider travel) async {
      await tester.pumpWidget(wrapLocationPage(travel));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(_locationSearchTextField(), findsOneWidget);
    }

    Future<void> pumpPastSearchDebounce() async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    Future<void> enterSearch(String text) async {
      await tester.enterText(_locationSearchTextField(), text);
      await pumpPastSearchDebounce();
    }

    // Empty input: no suggestion rows, no autocomplete calls.
    final emptyTravel = AutocompleteStubTravelProvider((_) async => [
          _place('Hidden Place', 1, 2),
        ]);
    await pumpPage(emptyTravel);
    expect(find.byType(ListTile), findsNothing);
    expect(emptyTravel.autocompleteQueries, isEmpty);

    // Single character: provider is not queried (debounced path never fires).
    final shortQueryTravel = AutocompleteStubTravelProvider((_) async => [
          _place('Xy City', 1, 2),
        ]);
    await pumpPage(shortQueryTravel);
    await enterSearch('x');
    expect(shortQueryTravel.autocompleteQueries, isEmpty);
    expect(find.byType(ListTile), findsNothing);

    // Two+ characters: suggestions appear from stub provider.
    final twoResultsTravel = AutocompleteStubTravelProvider(
      (_) async => [
        _place('Dubai Autocomplete One', 25.2, 55.3),
        _place('Dubai Autocomplete Two', 25.3, 55.2),
      ],
    );
    await pumpPage(twoResultsTravel);
    await enterSearch('Du');
    expect(twoResultsTravel.autocompleteQueries, ['Du']);
    expect(find.text('Dubai Autocomplete One'), findsOneWidget);
    expect(find.text('Dubai Autocomplete Two'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));

    // Filtered list updates when the query changes (stub simulates server filter).
    final catalog = [
      _place('Cat Cafe', 1, 2),
      _place('Car Repair', 3, 4),
      _place('Cafe Mocha', 5, 6),
    ];
    Future<List<Map<String, dynamic>>> filterByName(String query) async {
      final q = query.toLowerCase();
      return catalog
          .where((p) {
            final dn = p['displayName'];
            if (dn is! Map) return false;
            final text = dn['text']?.toString().toLowerCase() ?? '';
            return text.contains(q);
          })
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final filterTravel = AutocompleteStubTravelProvider(filterByName);
    await pumpPage(filterTravel);
    await enterSearch('ca');
    expect(find.text('Cat Cafe'), findsOneWidget);
    expect(find.text('Car Repair'), findsOneWidget);
    expect(find.text('Cafe Mocha'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));

    // Use a substring unique to one catalog entry ('caf' would also match "Cat Cafe").
    await enterSearch('moch');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Cafe Mocha'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);

    // No matches: empty list, no tiles.
    final emptyResultsTravel = AutocompleteStubTravelProvider((_) async => []);
    await pumpPage(emptyResultsTravel);
    await enterSearch('zz');
    expect(emptyResultsTravel.autocompleteQueries, ['zz']);
    expect(find.byType(ListTile), findsNothing);

    // Selection: field shows chosen title and suggestions close.
    const chosen = 'Pick Me Place';
    final pickTravel = AutocompleteStubTravelProvider(
      (_) async => [
        _place(chosen, 25.0, 55.1),
        _place('Other Place', 25.1, 55.0),
      ],
    );
    await pumpPage(pickTravel);
    await enterSearch('pi');
    await tester.tap(find.text(chosen));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(_locationSearchTextField());
    expect(field.controller?.text, chosen);
    expect(find.byType(ListTile), findsNothing);
  });
}
