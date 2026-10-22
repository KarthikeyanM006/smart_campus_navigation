import 'dart:collection';

import 'package:flutter/material.dart';

import 'campus_room.dart';

/// Categories of indoor navigation graph nodes.
enum IndoorNavNodeType {
  mainEntrance,
  entranceCorridor,
  corridorJunction,
  roomDoor,
  roomDestination,
  stairsElevator,
}

/// An individual waypoint node in the indoor walkable graph.
class IndoorNavNode {
  final String id;
  final String name;
  final IndoorNavNodeType type;
  final double normalizedX; // 0.0 to 1.0
  final double normalizedY; // 0.0 to 1.0
  final List<String> connectedNodeIds;

  const IndoorNavNode({
    required this.id,
    required this.name,
    required this.type,
    required this.normalizedX,
    required this.normalizedY,
    this.connectedNodeIds = const [],
  });

  IndoorNavNode copyWith({
    String? id,
    String? name,
    IndoorNavNodeType? type,
    double? normalizedX,
    double? normalizedY,
    List<String>? connectedNodeIds,
  }) {
    return IndoorNavNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      connectedNodeIds: connectedNodeIds ?? this.connectedNodeIds,
    );
  }
}

/// Indoor navigation topology graph representing walkable corridors and room connections.
class IndoorNavGraph {
  final Map<String, IndoorNavNode> nodes;

  const IndoorNavGraph({required this.nodes});

  /// Finds the shortest walkable node sequence between [startNodeId] and [targetNodeId] via BFS.
  List<IndoorNavNode> findPath(String startNodeId, String targetNodeId) {
    if (!nodes.containsKey(startNodeId) || !nodes.containsKey(targetNodeId)) {
      return [];
    }

    if (startNodeId == targetNodeId) {
      return [nodes[startNodeId]!];
    }

    final queue = Queue<List<String>>();
    final visited = <String>{startNodeId};

    queue.add([startNodeId]);

    while (queue.isNotEmpty) {
      final currentPath = queue.removeFirst();
      final currentId = currentPath.last;

      if (currentId == targetNodeId) {
        return currentPath.map((id) => nodes[id]!).toList();
      }

      final currentNode = nodes[currentId];
      if (currentNode != null) {
        for (final neighborId in currentNode.connectedNodeIds) {
          if (!visited.contains(neighborId) && nodes.containsKey(neighborId)) {
            visited.add(neighborId);
            queue.add([...currentPath, neighborId]);
          }
        }
      }
    }

    return [];
  }
}

/// Single turn-by-turn navigation directive.
class NavigationStep {
  final int stepNumber;
  final String instruction;
  final String detail;
  final IconData icon;
  final int distanceMeters;

  const NavigationStep({
    required this.stepNumber,
    required this.instruction,
    required this.detail,
    required this.icon,
    required this.distanceMeters,
  });
}

/// Computed indoor route containing graph node sequence, steps, distance, and duration.
class IndoorRoute {
  final String startPointName;
  final CampusRoom destinationRoom;
  final bool isDifferentFloor;
  final int sourceFloorNumber;
  final int targetFloorNumber;
  final int distanceMeters;
  final int estimatedMinutes;
  final List<IndoorNavNode> nodePath;
  final List<NavigationStep> steps;

  const IndoorRoute({
    required this.startPointName,
    required this.destinationRoom,
    required this.isDifferentFloor,
    required this.sourceFloorNumber,
    required this.targetFloorNumber,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.nodePath,
    required this.steps,
  });
}
