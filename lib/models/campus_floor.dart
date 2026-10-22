import 'campus_room.dart';

/// Data model representing a floor level inside a campus building.
class CampusFloor {
  final int floorNumber; // 0 for Ground, 1 for Floor 1, etc.
  final String floorName; // e.g., 'Ground Floor', 'Floor 1', 'Floor 2'
  final String? description;
  final List<CampusRoom> rooms;

  const CampusFloor({
    required this.floorNumber,
    required this.floorName,
    this.description,
    this.rooms = const [],
  });

  String get shortName => floorNumber == 0 ? 'Ground' : '$floorNumber';

  CampusFloor copyWith({
    int? floorNumber,
    String? floorName,
    String? description,
    List<CampusRoom>? rooms,
  }) {
    return CampusFloor(
      floorNumber: floorNumber ?? this.floorNumber,
      floorName: floorName ?? this.floorName,
      description: description ?? this.description,
      rooms: rooms ?? this.rooms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floorNumber': floorNumber,
      'floorName': floorName,
      'description': description,
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
  }

  factory CampusFloor.fromJson(Map<String, dynamic> json) {
    return CampusFloor(
      floorNumber: json['floorNumber'] as int? ?? 0,
      floorName: json['floorName'] as String? ?? 'Floor',
      description: json['description'] as String?,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => CampusRoom.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
