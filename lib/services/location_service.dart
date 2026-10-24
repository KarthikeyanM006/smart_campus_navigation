import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Status of the device GPS and location permissions.
enum LocationServiceStatus {
  initial,
  loading,
  active,
  serviceDisabled,
  permissionDenied,
  permissionDeniedPermanently,
  mockFallback,
  error,
}

/// Result object for location permission evaluations and status checks.
class LocationPermissionResult {
  final bool isGranted;
  final bool isServiceEnabled;
  final LocationPermission permission;
  final String message;

  const LocationPermissionResult({
    required this.isGranted,
    required this.isServiceEnabled,
    required this.permission,
    required this.message,
  });
}

/// Represents real-time user location with GPS coordinates and projected 2D map position.
class UserLocationData {
  final double latitude;
  final double longitude;
  final double mapX; // Projected normalized canvas coordinate (0.0 to 1.0)
  final double mapY; // Projected normalized canvas coordinate (0.0 to 1.0)
  final double accuracy; // Accuracy radius in meters
  final bool isMock; // True if using development fallback mock location
  final LocationServiceStatus status;
  final String? statusMessage;
  final DateTime timestamp;

  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.mapX,
    required this.mapY,
    required this.accuracy,
    required this.isMock,
    required this.status,
    this.statusMessage,
    required this.timestamp,
  });

  /// Default development mock location positioned near Campus Plaza.
  factory UserLocationData.developmentMock({
    LocationServiceStatus status = LocationServiceStatus.mockFallback,
    String? message = 'Development Mock (Plaza)',
  }) {
    return UserLocationData(
      latitude: 11.2735,
      longitude: 77.6068,
      mapX: 0.50,
      mapY: 0.50,
      accuracy: 5.0,
      isMock: true,
      status: status,
      statusMessage: message,
      timestamp: DateTime.now(),
    );
  }
}

/// Service managing device GPS location acquisition, permission lifecycle, and campus coordinate projection.
///
/// Designed exclusively for outdoor campus navigation using [LocationAccuracy.high].
/// Indoor GPS tracking and background location tracking are intentionally not used.
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal() {
    _currentLocation = UserLocationData.developmentMock(
      status: LocationServiceStatus.initial,
      message: 'Location ready',
    );
  }

  // Standard user-friendly error and status messages
  static const String msgServiceDisabled = 'Please enable location services.';
  static const String msgTurnOnLocation = 'Please turn on Location.';
  static const String msgPermissionDenied =
      'Location permission is required to find your position.';
  static const String msgPermissionRequired =
      'Location permission is required.';
  static const String msgPermissionPermanentlyDenied =
      'Location permission is permanently denied. Please enable it from Settings.';
  static const String msgLocationUnavailable =
      'Unable to get your location. Try moving outdoors and try again.';
  static const String msgGpsTimeout =
      'GPS request timed out. Please try again.';
  static const String msgFindingLocation = 'Finding your location...';

  // Campus geographical bounding box for projecting GPS coordinates
  static const double _campusMinLat = 11.2700;
  static const double _campusMaxLat = 11.2770;
  static const double _campusMinLng = 77.6045;
  static const double _campusMaxLng = 77.6090;

  late UserLocationData _currentLocation;
  StreamSubscription<Position>? _positionStreamSub;
  final StreamController<UserLocationData> _locationStreamController =
      StreamController<UserLocationData>.broadcast();
  bool _isRequestingLocation = false;

  UserLocationData get currentLocation => _currentLocation;
  Stream<UserLocationData> get locationStream =>
      _locationStreamController.stream;
  bool get isRequestingLocation => _isRequestingLocation;

  bool get _isTestOrWeb {
    try {
      return kIsWeb || Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return true;
    }
  }

  // ==========================================
  // LOCATION PERMISSION & GPS LIFECYCLE METHODS
  // ==========================================

  /// Checks whether GPS / location service is enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    if (_isTestOrWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current location permission state.
  Future<LocationPermission> checkLocationPermission() async {
    if (_isTestOrWeb) return LocationPermission.whileInUse;
    return await Geolocator.checkPermission();
  }

  /// Requests foreground location permission from the user (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION).
  /// Background location permission is not requested.
  Future<LocationPermission> requestLocationPermission() async {
    if (_isTestOrWeb) return LocationPermission.whileInUse;
    return await Geolocator.requestPermission();
  }

  /// Opens the device App Settings screen if permission is permanently denied.
  Future<bool> openAppSettings() async {
    if (_isTestOrWeb) return true;
    return await Geolocator.openAppSettings();
  }

  /// Opens the device Location Settings screen if GPS service is disabled.
  Future<bool> openLocationSettings() async {
    if (_isTestOrWeb) return true;
    return await Geolocator.openLocationSettings();
  }

  /// Handles checking GPS service and permission state.
  /// Handles disabled GPS, denied permissions, and permanently denied permissions.
  Future<LocationPermissionResult> handleLocationPermissions() async {
    // 1. Check if GPS / Location services are enabled on device
    final bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationPermissionResult(
        isGranted: false,
        isServiceEnabled: false,
        permission: LocationPermission.denied,
        message: msgServiceDisabled,
      );
    }

    // 2. Check current permission status
    LocationPermission permission = await checkLocationPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await requestLocationPermission();
      if (permission == LocationPermission.denied) {
        return const LocationPermissionResult(
          isGranted: false,
          isServiceEnabled: true,
          permission: LocationPermission.denied,
          message: msgPermissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionResult(
        isGranted: false,
        isServiceEnabled: true,
        permission: LocationPermission.deniedForever,
        message: msgPermissionPermanentlyDenied,
      );
    }

    return const LocationPermissionResult(
      isGranted: true,
      isServiceEnabled: true,
      permission: LocationPermission.whileInUse,
      message: 'Location permission granted.',
    );
  }

  /// Builds appropriate LocationSettings for the platform with configurable timeout.
  LocationSettings _buildLocationSettings({
    required LocationAccuracy accuracy,
    required Duration timeLimit,
    int distanceFilter = 0,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  /// Gets the current device position using [LocationAccuracy.high] for outdoor campus positioning.
  /// Returns null if GPS service is disabled or permission is denied.
  Future<Position?> getCurrentDevicePosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 25),
  }) async {
    if (_isTestOrWeb) {
      return Position(
        longitude: 77.6068,
        latitude: 11.2735,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
    }

    final permissionResult = await handleLocationPermissions();
    if (!permissionResult.isGranted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      // Attempt fallback with medium accuracy (cell / Wi-Fi)
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: _buildLocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Requests device location permissions and acquires the current GPS position,
  /// updating the service state and notifying UI listeners.
  Future<UserLocationData> refreshCurrentLocation({
    bool forceGps = true,
  }) async {
    _isRequestingLocation = true;
    notifyListeners();

    try {
      if (_isTestOrWeb) {
        _currentLocation = UserLocationData.developmentMock(
          status: LocationServiceStatus.mockFallback,
          message: 'Development Mode (Mock Location)',
        );
        _isRequestingLocation = false;
        notifyListeners();
        return _currentLocation;
      }

      // Check GPS service status and permissions
      final permissionResult = await handleLocationPermissions();
      if (!permissionResult.isServiceEnabled) {
        _currentLocation = UserLocationData.developmentMock(
          status: LocationServiceStatus.serviceDisabled,
          message: msgTurnOnLocation,
        );
        _isRequestingLocation = false;
        notifyListeners();
        return _currentLocation;
      }

      if (!permissionResult.isGranted) {
        if (permissionResult.permission == LocationPermission.deniedForever) {
          _currentLocation = UserLocationData.developmentMock(
            status: LocationServiceStatus.permissionDeniedPermanently,
            message: msgPermissionPermanentlyDenied,
          );
        } else {
          _currentLocation = UserLocationData.developmentMock(
            status: LocationServiceStatus.permissionDenied,
            message: msgPermissionDenied,
          );
        }
        _isRequestingLocation = false;
        notifyListeners();
        return _currentLocation;
      }

      // Fetch last known position in advance as a potential instant fallback
      Position? position;
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // Acquire position with 25s timeout for high accuracy GPS fix
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: _buildLocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 25),
          ),
        );
      } on TimeoutException {
        // Fallback Step 1: Try medium accuracy with a 10s timeout
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: _buildLocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
            ),
          );
        } on TimeoutException {
          // Fallback Step 2: Use last known position if available
          if (lastKnown != null) {
            position = lastKnown;
          } else {
            _currentLocation = UserLocationData.developmentMock(
              status: LocationServiceStatus.error,
              message: msgGpsTimeout,
            );
            _isRequestingLocation = false;
            _locationStreamController.add(_currentLocation);
            notifyListeners();
            return _currentLocation;
          }
        }
      } on LocationServiceDisabledException {
        _currentLocation = UserLocationData.developmentMock(
          status: LocationServiceStatus.serviceDisabled,
          message: msgTurnOnLocation,
        );
        _isRequestingLocation = false;
        _locationStreamController.add(_currentLocation);
        notifyListeners();
        return _currentLocation;
      } on PermissionDeniedException {
        _currentLocation = UserLocationData.developmentMock(
          status: LocationServiceStatus.permissionDenied,
          message: msgPermissionRequired,
        );
        _isRequestingLocation = false;
        _locationStreamController.add(_currentLocation);
        notifyListeners();
        return _currentLocation;
      }

      final resolvedPosition = position;

      final canvasPos = projectGpsToCanvas(
        resolvedPosition.latitude,
        resolvedPosition.longitude,
      );

      _currentLocation = UserLocationData(
        latitude: resolvedPosition.latitude,
        longitude: resolvedPosition.longitude,
        mapX: canvasPos.dx,
        mapY: canvasPos.dy,
        accuracy: resolvedPosition.accuracy,
        isMock: false,
        status: LocationServiceStatus.active,
        statusMessage:
            'Real GPS Active (±${resolvedPosition.accuracy.round()}m)',
        timestamp: resolvedPosition.timestamp,
      );

      _isRequestingLocation = false;
      _locationStreamController.add(_currentLocation);
      notifyListeners();
      return _currentLocation;
    } catch (e) {
      _currentLocation = UserLocationData.developmentMock(
        status: LocationServiceStatus.error,
        message: e is TimeoutException ? msgGpsTimeout : msgLocationUnavailable,
      );
      _isRequestingLocation = false;
      _locationStreamController.add(_currentLocation);
      notifyListeners();
      return _currentLocation;
    }
  }

  /// Starts listening to real-time GPS location updates with high accuracy.
  void startLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 3,
  }) {
    if (_isTestOrWeb) return;
    _positionStreamSub?.cancel();

    try {
      _positionStreamSub =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: accuracy,
              distanceFilter: distanceFilter,
            ),
          ).listen(
            (position) {
              final canvasPos = projectGpsToCanvas(
                position.latitude,
                position.longitude,
              );
              _currentLocation = UserLocationData(
                latitude: position.latitude,
                longitude: position.longitude,
                mapX: canvasPos.dx,
                mapY: canvasPos.dy,
                accuracy: position.accuracy,
                isMock: false,
                status: LocationServiceStatus.active,
                statusMessage:
                    'Live GPS (${position.accuracy.round()}m accuracy)',
                timestamp: position.timestamp,
              );
              _locationStreamController.add(_currentLocation);
              notifyListeners();
            },
            onError: (err) {
              _currentLocation = UserLocationData.developmentMock(
                status: LocationServiceStatus.error,
                message: 'Location stream error: $err',
              );
              _locationStreamController.add(_currentLocation);
              notifyListeners();
            },
          );
    } catch (_) {}
  }

  /// Stops listening to real-time GPS updates.
  void stopLocationStream() {
    try {
      _positionStreamSub?.cancel();
    } catch (_) {}
    _positionStreamSub = null;
  }

  // ==========================================
  // CAMPUS VECTOR PROJECTION & DISTANCE HELPERS
  // ==========================================

  /// Projects real-world (Lat, Lng) into normalized canvas position (0.0 - 1.0).
  static Offset projectGpsToCanvas(double lat, double lng) {
    final double normalizedX =
        ((lng - _campusMinLng) / (_campusMaxLng - _campusMinLng)).clamp(
          0.12,
          0.88,
        );
    // Invert Y axis because higher latitude is North (towards top of canvas)
    final double normalizedY =
        (1.0 - ((lat - _campusMinLat) / (_campusMaxLat - _campusMinLat))).clamp(
          0.12,
          0.88,
        );

    return Offset(normalizedX, normalizedY);
  }

  /// Calculates straight-line distance in meters between two geographical coordinates.
  static double calculateStraightLineDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      // Fallback Haversine formula if native method fails
      const earthRadius = 6371000.0;
      final dLat = _degToRad(endLatitude - startLatitude);
      final dLng = _degToRad(endLongitude - startLongitude);
      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_degToRad(startLatitude)) *
              math.cos(_degToRad(endLatitude)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadius * c;
    }
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  @override
  void dispose() {
    stopLocationStream();
    super.dispose();
  }
}
