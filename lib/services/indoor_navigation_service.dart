import 'package:flutter/material.dart';

import '../models/campus_floor.dart';
import '../models/campus_location.dart';
import '../models/campus_room.dart';
import '../models/indoor_navigation.dart';

/// Service for building walkable floor navigation graphs and computing node-based routes.
class IndoorNavigationService {
  static final IndoorNavigationService _instance =
      IndoorNavigationService._internal();
  factory IndoorNavigationService() => _instance;
  IndoorNavigationService._internal();

  /// Builds a walkable navigation graph for the given [floor].
  IndoorNavGraph buildGraphForFloor(CampusFloor floor) {
    final Map<String, IndoorNavNode> nodeMap = {};

    // 1. Fixed Core Hallway & Transit Nodes
    const entranceNode = IndoorNavNode(
      id: 'entrance_main',
      name: 'Main Entrance',
      type: IndoorNavNodeType.mainEntrance,
      normalizedX: 0.50,
      normalizedY: 0.90,
      connectedNodeIds: ['corridor_entrance'],
    );

    const entranceCorridorNode = IndoorNavNode(
      id: 'corridor_entrance',
      name: 'Entrance Foyer Walkway',
      type: IndoorNavNodeType.entranceCorridor,
      normalizedX: 0.50,
      normalizedY: 0.70,
      connectedNodeIds: ['entrance_main', 'junction_center'],
    );

    const junctionCenter = IndoorNavNode(
      id: 'junction_center',
      name: 'Central Corridor Junction',
      type: IndoorNavNodeType.corridorJunction,
      normalizedX: 0.50,
      normalizedY: 0.50,
      connectedNodeIds: ['corridor_entrance', 'junction_west', 'junction_east'],
    );

    const junctionTransit = IndoorNavNode(
      id: 'junction_transit',
      name: 'Transit Hall Junction',
      type: IndoorNavNodeType.corridorJunction,
      normalizedX: 0.88,
      normalizedY: 0.50,
      connectedNodeIds: ['junction_east', 'stairs_elevator'],
    );

    const stairsNode = IndoorNavNode(
      id: 'stairs_elevator',
      name: 'Stairs & Elevator',
      type: IndoorNavNodeType.stairsElevator,
      normalizedX: 0.88,
      normalizedY: 0.88,
      connectedNodeIds: ['junction_transit'],
    );

    nodeMap['entrance_main'] = entranceNode;
    nodeMap['corridor_entrance'] = entranceCorridorNode;
    nodeMap['junction_center'] = junctionCenter;
    nodeMap['junction_transit'] = junctionTransit;
    nodeMap['stairs_elevator'] = stairsNode;

    // 2. Room Nodes and Wing Junctions
    final rooms = floor.rooms;
    final half = (rooms.length / 2).ceil();
    final topRooms = rooms.take(half).toList();
    final bottomRooms = rooms.skip(half).toList();

    final westJunctionNeighbors = <String>['junction_center'];
    final eastJunctionNeighbors = <String>[
      'junction_center',
      'junction_transit',
    ];

    // Top Wing Rooms (North)
    for (int i = 0; i < topRooms.length; i++) {
      final room = topRooms[i];
      final isWest = i == 0;
      final posX = isWest ? 0.28 : 0.72;
      final doorId = 'door_${room.roomCode}';
      final destId = 'dest_${room.roomCode}';

      final doorNode = IndoorNavNode(
        id: doorId,
        name: '${room.roomCode} Entrance',
        type: IndoorNavNodeType.roomDoor,
        normalizedX: posX,
        normalizedY: 0.44,
        connectedNodeIds: [isWest ? 'junction_west' : 'junction_east', destId],
      );

      final destNode = IndoorNavNode(
        id: destId,
        name: room.name,
        type: IndoorNavNodeType.roomDestination,
        normalizedX: posX,
        normalizedY: 0.25,
        connectedNodeIds: [doorId],
      );

      nodeMap[doorId] = doorNode;
      nodeMap[destId] = destNode;

      if (isWest) {
        westJunctionNeighbors.add(doorId);
      } else {
        eastJunctionNeighbors.add(doorId);
      }
    }

    // Bottom Wing Rooms (South)
    for (int i = 0; i < bottomRooms.length; i++) {
      final room = bottomRooms[i];
      final isWest = i == 0;
      final posX = isWest ? 0.28 : 0.72;
      final doorId = 'door_${room.roomCode}';
      final destId = 'dest_${room.roomCode}';

      final doorNode = IndoorNavNode(
        id: doorId,
        name: '${room.roomCode} Entrance',
        type: IndoorNavNodeType.roomDoor,
        normalizedX: posX,
        normalizedY: 0.56,
        connectedNodeIds: [isWest ? 'junction_west' : 'junction_east', destId],
      );

      final destNode = IndoorNavNode(
        id: destId,
        name: room.name,
        type: IndoorNavNodeType.roomDestination,
        normalizedX: posX,
        normalizedY: 0.75,
        connectedNodeIds: [doorId],
      );

      nodeMap[doorId] = doorNode;
      nodeMap[destId] = destNode;

      if (isWest) {
        westJunctionNeighbors.add(doorId);
      } else {
        eastJunctionNeighbors.add(doorId);
      }
    }

    // Add West and East Corridor Junctions with dynamic connections
    nodeMap['junction_west'] = IndoorNavNode(
      id: 'junction_west',
      name: 'West Wing Corridor Junction',
      type: IndoorNavNodeType.corridorJunction,
      normalizedX: 0.28,
      normalizedY: 0.50,
      connectedNodeIds: westJunctionNeighbors,
    );

    nodeMap['junction_east'] = IndoorNavNode(
      id: 'junction_east',
      name: 'East Wing Corridor Junction',
      type: IndoorNavNodeType.corridorJunction,
      normalizedX: 0.72,
      normalizedY: 0.50,
      connectedNodeIds: eastJunctionNeighbors,
    );

    return IndoorNavGraph(nodes: nodeMap);
  }

  /// Calculates a walkable indoor route through connected graph nodes.
  IndoorRoute calculateRoute({
    required CampusLocation building,
    required CampusRoom destinationRoom,
    int? currentFloorNumber,
    String? startPointOverride,
  }) {
    final startFloor = currentFloorNumber ?? destinationRoom.floor;
    final isDifferentFloor = startFloor != destinationRoom.floor;
    final startPointName =
        startPointOverride ??
        (startFloor == 0 ? 'Main Entrance' : 'Floor $startFloor Entrance');

    final activeFloor = building.floors.firstWhere(
      (f) => f.floorNumber == startFloor,
      orElse: () => building.floors.isNotEmpty
          ? building.floors.first
          : CampusFloor(
              floorNumber: startFloor,
              floorName: 'Floor $startFloor',
            ),
    );

    final graph = buildGraphForFloor(activeFloor);
    final targetNodeId = isDifferentFloor
        ? 'stairs_elevator'
        : 'dest_${destinationRoom.roomCode}';

    // Solve shortest walkable node path on graph
    List<IndoorNavNode> nodePath = graph.findPath(
      'entrance_main',
      targetNodeId,
    );

    if (nodePath.isEmpty) {
      // Fallback if target node ID is not directly in active floor
      nodePath = graph.findPath('entrance_main', 'junction_center');
    }

    // Generate Turn-by-turn navigation steps corresponding to graph transitions
    final List<NavigationStep> steps = [];

    steps.add(
      NavigationStep(
        stepNumber: 1,
        instruction: 'Start at $startPointName',
        detail: 'Proceed through the entrance foyer walkway.',
        icon: Icons.my_location_rounded,
        distanceMeters: 10,
      ),
    );

    if (!isDifferentFloor) {
      // Same-floor turn-by-turn guidance
      final isWestWing =
          destinationRoom.roomCode.endsWith('1') ||
          destinationRoom.roomCode.endsWith('3');

      steps.add(
        NavigationStep(
          stepNumber: 2,
          instruction: isWestWing
              ? 'Turn left at Central Junction into Main Corridor'
              : 'Turn right at Central Junction into Main Corridor',
          detail: isWestWing
              ? 'Follow the corridor towards the West Wing.'
              : 'Follow the corridor towards the East Wing.',
          icon: isWestWing ? Icons.turn_left_rounded : Icons.turn_right_rounded,
          distanceMeters: 25,
        ),
      );

      final isTopWing =
          destinationRoom.roomCode.endsWith('1') ||
          destinationRoom.roomCode.endsWith('2');

      steps.add(
        NavigationStep(
          stepNumber: 3,
          instruction: isTopWing
              ? 'Turn into ${destinationRoom.roomCode} entrance doorway'
              : 'Turn into ${destinationRoom.roomCode} entrance doorway',
          detail: 'Step into ${destinationRoom.name}.',
          icon: isTopWing
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          distanceMeters: 10,
        ),
      );

      steps.add(
        NavigationStep(
          stepNumber: 4,
          instruction: 'Arrived at ${destinationRoom.roomCode}',
          detail: destinationRoom.name,
          icon: Icons.location_on_rounded,
          distanceMeters: 5,
        ),
      );
    } else {
      // Multi-floor guidance to stairs/elevator
      steps.add(
        const NavigationStep(
          stepNumber: 2,
          instruction: 'Turn right at Central Junction to East Hall',
          detail: 'Follow corridor past the junction to the transit bay.',
          icon: Icons.turn_right_rounded,
          distanceMeters: 25,
        ),
      );

      steps.add(
        NavigationStep(
          stepNumber: 3,
          instruction:
              'Take Stairs or Elevator up to ${destinationRoom.floorDisplay}',
          detail:
              'Ascend to ${destinationRoom.floorDisplay} and proceed along the main corridor.',
          icon: Icons.stairs_outlined,
          distanceMeters: 20,
        ),
      );

      steps.add(
        NavigationStep(
          stepNumber: 4,
          instruction: 'Proceed to ${destinationRoom.roomCode}',
          detail:
              '${destinationRoom.name} is located on ${destinationRoom.floorDisplay}.',
          icon: Icons.location_on_rounded,
          distanceMeters: 10,
        ),
      );
    }

    final totalDistance = steps.fold<int>(
      0,
      (sum, step) => sum + step.distanceMeters,
    );
    final estimatedTime = (totalDistance / 60).ceil().clamp(1, 15);

    return IndoorRoute(
      startPointName: startPointName,
      destinationRoom: destinationRoom,
      isDifferentFloor: isDifferentFloor,
      sourceFloorNumber: startFloor,
      targetFloorNumber: destinationRoom.floor,
      distanceMeters: totalDistance,
      estimatedMinutes: estimatedTime,
      nodePath: nodePath,
      steps: steps,
    );
  }
}
