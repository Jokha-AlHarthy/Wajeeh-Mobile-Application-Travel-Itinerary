import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/constants/place_category_options.dart';
import 'package:wajeeh/providers/travel_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Shopping filter (filter_shopping_souvenirs)', () {
    late TravelProvider travel;

    Map<String, dynamic> placeWithTypes(List<String> types, String name) => {
          'id': name,
          'displayName': {'text': name},
          'formattedAddress': 'Test Address',
          'types': types,
        };

    setUp(() {
      travel = TravelProvider();
    });

    test('substring shop is not inside restaurant type', () {
      expect('restaurant'.contains('shop'), isFalse);
      expect('restaurant'.contains('store'), isFalse);
    });

    test('preferenceInterestToFilterKey maps Shopping labels', () {
      expect(preferenceInterestToFilterKey('Shopping'), 'filter_shopping_souvenirs');
      expect(preferenceInterestToFilterKey('shopping'), 'filter_shopping_souvenirs');
      expect(preferenceInterestToFilterKey('interest_shopping'), 'filter_shopping_souvenirs');
      expect(
        preferenceInterestToFilterKey('filter_shopping_souvenirs'),
        'filter_shopping_souvenirs',
      );
    });

    test('filteredPlaces excludes pure restaurants for shopping filter', () {
      travel.homePlaces = [
        placeWithTypes(['shopping_mall'], 'City Mall'),
        placeWithTypes(['restaurant', 'food'], 'Bistro'),
        placeWithTypes(['department_store'], 'Dept Store'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_shopping_souvenirs'],
      );

      expect(out.map((e) => travel.placeName(e)).toSet(), {'City Mall', 'Dept Store'});
    });

    test('filteredPlaces excludes restaurant even with shopping_mall co-type', () {
      travel.homePlaces = [
        placeWithTypes(
          ['restaurant', 'food', 'shopping_mall'],
          'Mall Food Court',
        ),
        placeWithTypes(['shopping_mall', 'point_of_interest'], 'Grand Mall'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_shopping_souvenirs'],
      );

      expect(out.length, 1);
      expect(travel.placeName(out.single), 'Grand Mall');
    });

    test('filteredPlaces with display label Shopping uses shopping rules', () {
      travel.homePlaces = [
        placeWithTypes(['restaurant', 'food'], 'Bistro'),
        placeWithTypes(['shopping_mall'], 'Souq'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['Shopping'],
      );

      expect(out.length, 1);
      expect(travel.placeName(out.single), 'Souq');
    });

    test('filteredPlaces excludes sandwich_shop and coffee_shop', () {
      travel.homePlaces = [
        placeWithTypes(['sandwich_shop', 'meal_takeaway'], 'Sub Shop'),
        placeWithTypes(['coffee_shop', 'cafe'], 'Coffee House'),
        placeWithTypes(['shopping_mall'], 'Mall'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_shopping_souvenirs'],
      );

      expect(out.map((e) => travel.placeName(e)).toSet(), {'Mall'});
    });

    test('filteredPlaces with Firestore key shopping excludes restaurants', () {
      travel.homePlaces = [
        placeWithTypes(['restaurant', 'food'], 'Bistro'),
        placeWithTypes(['shopping_mall'], 'Mall'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['shopping'],
      );

      expect(out.length, 1);
      expect(travel.placeName(out.single), 'Mall');
    });

    test('filteredPlaces does not treat food filter as shopping', () {
      travel.homePlaces = [
        placeWithTypes(['restaurant', 'food'], 'Bistro'),
      ];

      final out = travel.filteredPlaces(
        query: '',
        filters: const ['filter_food_restaurants'],
      );

      expect(out.length, 1);
    });
  });
}
