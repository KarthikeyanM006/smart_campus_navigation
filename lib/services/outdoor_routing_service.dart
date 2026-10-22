import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/campus_location.dart';
import 'location_service.dart';

/// Navigation origin mode: live GPS position or a selected campus building entrance
enum NavigationStartType {
  currentLocation,
  selectedBuilding,
}

/// Single outdoor turn-by-turn walking maneuver step.
class OutdoorRouteStep {
  final int stepNumber;
  final String instruction;
  final String roadOrPathName;
  final int distanceMeters;
  final IconData icon;

  const OutdoorRouteStep({
    required this.stepNumber,
    required this.instruction,
    required this.roadOrPathName,
    required this.distanceMeters,
    required this.icon,
  });
}

/// Result of an outdoor walking route calculation between user GPS / building entrance and destination.
class OutdoorRouteResult {
  final LatLng startPoint;
  final LatLng destinationPoint;
  final CampusLocation? startBuilding;
  final CampusLocation destinationBuilding;
  final NavigationStartType startType;
  final List<LatLng> polylinePoints;
  final int distanceMeters;
  final int estimatedMinutes;
  final List<OutdoorRouteStep> steps;
  final bool isFallback;
  final String? fallbackReason;

  const OutdoorRouteResult({
    required this.startPoint,
    required this.destinationPoint,
    this.startBuilding,
    required this.destinationBuilding,
    this.startType = NavigationStartType.currentLocation,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.steps,
    this.isFallback = false,
    this.fallbackReason,
  });

  /// Readable origin name (e.g. "IT Park Entrance" or "Current GPS Location")
  String get originDisplayName {
    if (startType == NavigationStartType.selectedBuilding && startBuilding != null) {
      return '${startBuilding!.name} (Entrance)';
    }
    return 'My Current Location (GPS)';
  }

  /// Readable destination name
  String get destinationDisplayName => '${destinationBuilding.name} (Entrance)';

  /// User-friendly distance label (e.g., "180 m" or "1.2 km")
  String get distanceDisplay {
    if (distanceMeters >= 1000) {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      return '$km km';
    }
    return '$distanceMeters m';
  }

  /// User-friendly time estimate (e.g., "~3 min walk")
  String get durationDisplay {
    if (estimatedMinutes <= 1) {
      return '~1 min walk';
    }
    return '~$estimatedMinutes min walk';
  }
}

/// Dedicated service for computing real outdoor pedestrian walking routes on campus using OSRM.
/// Supports both live GPS navigation and building-to-building entrance routing.
class OutdoorRoutingService {
  static final OutdoorRoutingService _instance =
      OutdoorRoutingService._internal();
  factory OutdoorRoutingService() => _instance;
  OutdoorRoutingService._internal();

  /// Calculates a walking route from [start] (or [startBuilding] entrance) to [destination] entrance.
  Future<OutdoorRouteResult> calculateWalkingRoute({
    required LatLng start,
    required CampusLocation destination,
    CampusLocation? startBuilding,
    NavigationStartType startType = NavigationStartType.currentLocation,
  }) async {
    // If navigating building-to-building, use the exact entrance coordinates of the start building
    final effectiveStartLatLng = (startType == NavigationStartType.selectedBuilding && startBuilding != null)
        ? LatLng(
            startBuilding.effectiveEntranceLatitude,
            startBuilding.effectiveEntranceLongitude,
          )
        : start;

    final destinationLatLng = LatLng(
      destination.effectiveEntranceLatitude,
      destination.effectiveEntranceLongitude,
    );

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '${effectiveStartLatLng.longitude},${effectiveStartLatLng.latitude};'
        '${destinationLatLng.longitude},${destinationLatLng.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'SmartCampusNavigation/1.0 (com.example.smart_campus_navigation)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final routeData =
              (data['routes'] as List).first as Map<String, dynamic>;
          final double distMetersDouble =
              (routeData['distance'] as num?)?.toDouble() ?? 0.0;
          final double durSecondsDouble =
              (routeData['duration'] as num?)?.toDouble() ?? 0.0;

          final int distanceMeters = distMetersDouble.round().clamp(10, 50000);
          final int estimatedMinutes = (durSecondsDouble / 60).ceil().clamp(
            1,
            120,
          );

          // Parse GeoJSON coordinates
          final polylinePoints = <LatLng>[];
          final geometry = routeData['geometry'] as Map<String, dynamic>?;
          if (geometry != null && geometry['coordinates'] is List) {
            for (final coord in geometry['coordinates'] as List) {
              if (coord is List && coord.length >= 2) {
                final lng = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                polylinePoints.add(LatLng(lat, lng));
              }
            }
          }

          // Ensure start and destination are part of polyline
          if (polylinePoints.isEmpty) {
            polylinePoints.addAll([effectiveStartLatLng, destinationLatLng]);
          }

          // Parse turn-by-turn walking steps
          final steps = <OutdoorRouteStep>[];
          final legs = routeData['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            final legData = legs.first as Map<String, dynamic>;
            final rawSteps = legData['steps'] as List?;
            if (rawSteps != null) {
              int stepNum = 1;
              for (final rawStep in rawSteps) {
                final stepMap = rawStep as Map<String, dynamic>;
                final maneuver = stepMap['maneuver'] as Map<String, dynamic>?;
                final maneuverType = maneuver?['type'] as String? ?? 'step';
                final modifier = maneuver?['modifier'] as String? ?? '';
                final name = (stepMap['name'] as String?)?.trim();
                final pathName = (name == null || name.isEmpty)
                    ? 'Campus Walkway'
                    : name;
                final stepDist = (stepMap['distance'] as num?)?.round() ?? 0;

                final instruction = _buildStepInstruction(
                  maneuverType: maneuverType,
                  modifier: modifier,
                  startBuilding: startBuilding,
                  destinationName: destination.name,
                  pathName: pathName,
                  isFirst: stepNum == 1,
                  isLast: stepNum == rawSteps.length,
                );

                final icon = _resolveManeuverIcon(maneuverType, modifier);

                steps.add(
                  OutdoorRouteStep(
                    stepNumber: stepNum++,
                    instruction: instruction,
                    roadOrPathName: pathName,
                    distanceMeters: stepDist,
                    icon: icon,
                  ),
                );
              }
            }
          }

          if (steps.isEmpty) {
            steps.addAll(_createBasicSteps(
              startBuilding: startBuilding,
              destination: destination,
              totalDistance: distanceMeters,
              startType: startType,
            ));
          }

          return OutdoorRouteResult(
            startPoint: effectiveStartLatLng,
            destinationPoint: destinationLatLng,
            startBuilding: startBuilding,
            destinationBuilding: destination,
            startType: startType,
            polylinePoints: polylinePoints,
            distanceMeters: distanceMeters,
            estimatedMinutes: estimatedMinutes,
            steps: steps,
            isFallback: false,
          );
        }
      }
    } catch (_) {
      // Fallback on timeout or network issue
    }

    // Graceful Offline / Fallback Route
    return _buildFallbackRoute(
      effectiveStartLatLng,
      destination,
      startBuilding: startBuilding,
      startType: startType,
    );
  }

  /// Builds a straight-line fallback route when live routing service is offline or times out.
  OutdoorRouteResult _buildFallbackRoute(
    LatLng start,
    CampusLocation destination, {
    CampusLocation? startBuilding,
    NavigationStartType startType = NavigationStartType.currentLocation,
  }) {
    final destinationLatLng = LatLng(
      destination.effectiveEntranceLatitude,
      destination.effectiveEntranceLongitude,
    );

    final straightDist = LocationService.calculateStraightLineDistance(
      startLatitude: start.latitude,
      startLongitude: start.longitude,
      endLatitude: destinationLatLng.latitude,
      endLongitude: destinationLatLng.longitude,
    );

    final estimatedDistMeters = (straightDist * 1.25).round().clamp(20, 50000);
    final estimatedMinutes = (estimatedDistMeters / 75).ceil().clamp(1, 120);

    final steps = _createBasicSteps(
      startBuilding: startBuilding,
      destination: destination,
      totalDistance: estimatedDistMeters,
      startType: startType,
    );

    return OutdoorRouteResult(
      startPoint: start,
      destinationPoint: destinationLatLng,
      startBuilding: startBuilding,
      destinationBuilding: destination,
      startType: startType,
      polylinePoints: [start, destinationLatLng],
      distanceMeters: estimatedDistMeters,
      estimatedMinutes: estimatedMinutes,
      steps: steps,
      isFallback: true,
      fallbackReason:
          'Offline mode: Displaying approximate straight-line direction.',
    );
  }

  List<OutdoorRouteStep> _createBasicSteps({
    CampusLocation? startBuilding,
    required CampusLocation destination,
    required int totalDistance,
    required NavigationStartType startType,
  }) {
    final startDesc = (startType == NavigationStartType.selectedBuilding && startBuilding != null)
        ? 'Depart from ${startBuilding.name} Main Entrance'
        : 'Depart from current GPS location';

    return [
      OutdoorRouteStep(
        stepNumber: 1,
        instruction: startDesc,
        roadOrPathName: 'Campus Pathway',
        distanceMeters: 30,
        icon: startBuilding != null ? Icons.domain_rounded : Icons.directions_walk_rounded,
      ),
      OutdoorRouteStep(
        stepNumber: 2,
        instruction: 'Walk along paved walkway towards ${destination.name}',
        roadOrPathName: 'Paved Walkway',
        distanceMeters: (totalDistance - 40).clamp(10, 50000),
        icon: Icons.navigation_rounded,
      ),
      OutdoorRouteStep(
        stepNumber: 3,
        instruction: 'Arrive at ${destination.name} Entrance',
        roadOrPathName: 'Building Entrance',
        distanceMeters: 10,
        icon: Icons.domain_rounded,
      ),
    ];
  }

  String _buildStepInstruction({
    required String maneuverType,
    required String modifier,
    CampusLocation? startBuilding,
    required String destinationName,
    required String pathName,
    required bool isFirst,
    required bool isLast,
  }) {
    if (isLast || maneuverType == 'arrive') {
      return 'Arrive at $destinationName Entrance';
    }
    if (isFirst || maneuverType == 'depart') {
      if (startBuilding != null) {
        return 'Depart from ${startBuilding.name} Entrance along $pathName';
      }
      return 'Depart along $pathName';
    }
    if (maneuverType == 'turn') {
      if (modifier.contains('left')) {
        return 'Turn left onto $pathName';
      } else if (modifier.contains('right')) {
        return 'Turn right onto $pathName';
      } else {
        return 'Turn towards $pathName';
      }
    }
    if (maneuverType == 'fork' || maneuverType == 'end of road') {
      if (modifier.contains('left')) {
        return 'Keep left onto $pathName';
      } else if (modifier.contains('right')) {
        return 'Keep right onto $pathName';
      }
    }
    if (maneuverType == 'roundabout' || maneuverType == 'rotary') {
      return 'Enter rotary and take exit onto $pathName';
    }
    return 'Continue on $pathName';
  }

  IconData _resolveManeuverIcon(String maneuverType, String modifier) {
    if (maneuverType == 'arrive') {
      return Icons.domain_rounded;
    }
    if (maneuverType == 'depart') {
      return Icons.directions_walk_rounded;
    }
    if (modifier.contains('left')) {
      if (modifier.contains('slight')) return Icons.turn_slight_left_rounded;
      if (modifier.contains('sharp')) return Icons.turn_sharp_left_rounded;
      return Icons.turn_left_rounded;
    }
    if (modifier.contains('right')) {
      if (modifier.contains('slight')) return Icons.turn_slight_right_rounded;
      if (modifier.contains('sharp')) return Icons.turn_sharp_right_rounded;
      return Icons.turn_right_rounded;
    }
    if (modifier.contains('straight')) {
      return Icons.straight_rounded;
    }
    return Icons.navigation_rounded;
  }
}
