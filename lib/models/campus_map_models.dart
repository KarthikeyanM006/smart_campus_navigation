import 'package:flutter/material.dart';

import 'campus_location.dart';

/// Represents geographical coordinates and normalized 2D map canvas position.
class CampusCoordinates {
  final double latitude;
  final double longitude;
  final double mapX; // Normalized X on canvas (0.0 to 1.0)
  final double mapY; // Normalized Y on canvas (0.0 to 1.0)

  const CampusCoordinates({
    required this.latitude,
    required this.longitude,
    required this.mapX,
    required this.mapY,
  });
}

/// Model for the user's current location (mock/prototype).
class MockUserLocation {
  final String label;
  final String description;
  final double latitude;
  final double longitude;
  final double mapX;
  final double mapY;

  const MockUserLocation({
    this.label = 'Campus Plaza (You are here)',
    this.description = 'Central campus walkway near Food Court & Library',
    this.latitude = 13.0818,
    this.longitude = 80.2702,
    this.mapX = 0.50,
    this.mapY = 0.65,
  });

  Offset get offset => Offset(mapX, mapY);
}

/// Model for outdoor navigation route between current location and building entrance.
class OutdoorRoute {
  final String startLocationName;
  final CampusLocation destination;
  final int distanceMeters;
  final int estimatedMinutes;
  final List<Offset>
  waypoints; // Normalized coordinates along campus road network

  const OutdoorRoute({
    required this.startLocationName,
    required this.destination,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.waypoints,
  });
}
