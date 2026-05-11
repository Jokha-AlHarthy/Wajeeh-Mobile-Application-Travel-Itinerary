import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/providers/travel_provider.dart';

/// Tests for hotel-related selection: [TravelProvider.isHotel] and
/// [TravelProvider.filteredPlaces] with [filter_hotels_stays] (Home filter sheet).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Hotel filtering (filter_hotels_stays / isHotel)', () {
    late TravelProvider travel;

    Map<String, dynamic> placeWithTypes(List<String> types, String name) => {
          'id': name,
          'displayName': {'text': name},
          'formattedAddress': 'Test Address',
          'types': types,
        };

    setUp(() {
      travel = TravelProvider();
      travel.homePlaces = [];
      travel.searchPlaces = [];
    });

    test('isHotel is true for hotel, lodging, resort, guest_house types', () {
      expect(travel.isHotel(placeWithTypes(['lodging'], 'Lodging')), isTrue);
      expect(travel.isHotel(placeWithTypes(['hotel'], 'Hotel')), isTrue);
      expect(travel.isHotel(placeWithTypes(['resort_hotel'], 'Resort')), isTrue);
      expect(travel.isHotel(placeWithTypes(['guest_house'], 'Guest')), isTrue);
    });

    test('isHotel matches substring (e.g. extended_place_type hotel)', () {
      expect(
        travel.isHotel(placeWithTypes(['extended_stay_hotel'], 'Apt Hotel')),
        isTrue,
      );
    });

    test('isHotel is false for restaurant, museum, cafe', () {
      expect(
        travel.isHotel(placeWithTypes(['restaurant', 'food'], 'Bistro')),
        isFalse,
      );
      expect(travel.isHotel(placeWithTypes(['museum'], 'National Museum')), isFalse);
      expect(travel.isHotel(placeWithTypes(['cafe'], 'Coffee Shop')), isFalse);
    });

    test('isHotel is false when types list is empty', () {
      expect(travel.isHotel(placeWithTypes([], 'Unknown')), isFalse);
    });

    test(
      'filteredPlaces with filter_hotels_stays returns only lodging-like places',
      () {
        travel.homePlaces = [
          placeWithTypes(['hotel'], 'Grand Hotel'),
          placeWithTypes(['restaurant'], 'Bistro'),
          placeWithTypes(['lodging'], 'City Inn'),
        ];

        final out = travel.filteredPlaces(
          query: '',
          filters: const ['filter_hotels_stays'],
          maxPrice: 200,
        );

        expect(out.length, 2);
        expect(
          out.map((e) => travel.placeName(e)).toSet(),
          {'Grand Hotel', 'City Inn'},
        );
      },
    );

    test('filteredPlaces filter_hotels_stays excludes non-hotels only', () {
      travel.homePlaces = [
        placeWithTypes(['shopping_mall'], 'Mega Mall'),
        placeWithTypes(['airport'], 'International Airport'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_hotels_stays'],
        maxPrice: 200,
      );

      expect(out, isEmpty);
    });

    test('filteredPlaces with empty filters does not apply hotel-only filter', () {
      travel.homePlaces = [
        placeWithTypes(['hotel'], 'H'),
        placeWithTypes(['museum'], 'M'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const [],
        maxPrice: 200,
      );

      expect(out.length, 2);
    });

    test('filter_hotels_stays respects maxPrice (mapped default within range)', () {
      travel.homePlaces = [
        placeWithTypes(['hotel'], 'Cheap'),
        placeWithTypes(['hotel'], 'Luxury'),
      ];
      travel.homePlaces[0]['priceLevel'] = 'PRICE_LEVEL_INEXPENSIVE';
      travel.homePlaces[1]['priceLevel'] = 'PRICE_LEVEL_VERY_EXPENSIVE';

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_hotels_stays'],
        maxPrice: 100,
      );

      expect(out.length, 1);
      expect(travel.placeName(out.single), 'Cheap');
    });
  });
}
