import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_campus_navigation/services/location_service.dart';

void main() {
  group('LocationService Permission & Configuration Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('Required user-friendly messages match requirements exactly', () {
      expect(
        LocationService.msgServiceDisabled,
        equals('Please enable location services.'),
      );
      expect(
        LocationService.msgPermissionDenied,
        equals('Location permission is required to find your position.'),
      );
      expect(
        LocationService.msgPermissionPermanentlyDenied,
        equals(
          'Location permission is permanently denied. Please enable it from Settings.',
        ),
      );
    });

    test('isLocationServiceEnabled returns boolean without throwing', () async {
      final isEnabled = await locationService.isLocationServiceEnabled();
      expect(isEnabled, isA<bool>());
    });

    test('checkLocationPermission returns valid LocationPermission', () async {
      final permission = await locationService.checkLocationPermission();
      expect(permission, isA<LocationPermission>());
    });

    test(
      'requestLocationPermission returns valid LocationPermission',
      () async {
        final permission = await locationService.requestLocationPermission();
        expect(permission, isA<LocationPermission>());
      },
    );

    test(
      'handleLocationPermissions returns LocationPermissionResult',
      () async {
        final result = await locationService.handleLocationPermissions();
        expect(result, isA<LocationPermissionResult>());
        expect(result.isGranted, isA<bool>());
        expect(result.isServiceEnabled, isA<bool>());
        expect(result.permission, isA<LocationPermission>());
        expect(result.message, isNotEmpty);
      },
    );

    test(
      'getCurrentDevicePosition returns non-null Position in test environment',
      () async {
        final position = await locationService.getCurrentDevicePosition(
          accuracy: LocationAccuracy.high,
        );
        expect(position, isNotNull);
        expect(position!.latitude, equals(11.2735));
        expect(position.longitude, equals(77.6068));
        expect(position.accuracy, equals(5.0));
      },
    );

    test('refreshCurrentLocation updates currentLocation and returns valid UserLocationData', () async {
      final userLoc = await locationService.refreshCurrentLocation();
      expect(userLoc, isNotNull);
      expect(userLoc.latitude, isNotNull);
      expect(userLoc.longitude, isNotNull);
      expect(userLoc.mapX, inInclusiveRange(0.12, 0.88));
      expect(userLoc.mapY, inInclusiveRange(0.12, 0.88));
      expect(locationService.currentLocation, equals(userLoc));
    });

    test('LocationService projects geographical coordinates accurately', () {
      final offset = LocationService.projectGpsToCanvas(13.0818, 80.2702);
      expect(offset.dx, inInclusiveRange(0.12, 0.88));
      expect(offset.dy, inInclusiveRange(0.12, 0.88));
    });

    test('LocationService calculates distance in meters correctly', () {
      final dist = LocationService.calculateStraightLineDistance(
        startLatitude: 13.0818,
        startLongitude: 80.2702,
        endLatitude: 13.0835,
        endLongitude: 80.2705,
      );
      expect(dist, greaterThan(100));
      expect(dist, lessThan(500));
    });
  });
}
