/// Data model representing dynamic mapping between an Academic Class/Section and a Physical Campus Room.
/// E.g.: CSE-A -> IT Park -> Floor 1 -> Room ITP001
class ClassMapping {
  final String id;
  final String department; // e.g., 'CSE'
  final String className; // e.g., 'CSE-A', 'CSE-B', 'IT-A'
  final String buildingId; // e.g., 'loc_it_park'
  final String buildingName; // e.g., 'IT Park'
  final int floor; // e.g., 1
  final String roomId; // e.g., 'room_itp_101'
  final String roomNumber; // e.g., 'ITP101'
  final String roomName; // e.g., 'Software Systems Lab'
  final String roomType; // e.g., 'Classroom', 'Laboratory'
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;

  ClassMapping({
    required this.id,
    required this.department,
    required this.className,
    required this.buildingId,
    required this.buildingName,
    required this.floor,
    required this.roomId,
    required this.roomNumber,
    required this.roomName,
    this.roomType = 'Classroom',
    this.description = '',
    this.latitude,
    this.longitude,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get floorDisplay => floor == 0 ? 'Ground Floor' : 'Floor $floor';

  String get fullDisplayString =>
      '$className → $buildingName → $floorDisplay → Room $roomNumber';

  ClassMapping copyWith({
    String? id,
    String? department,
    String? className,
    String? buildingId,
    String? buildingName,
    int? floor,
    String? roomId,
    String? roomNumber,
    String? roomName,
    String? roomType,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return ClassMapping(
      id: id ?? this.id,
      department: department ?? this.department,
      className: className ?? this.className,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      floor: floor ?? this.floor,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomName: roomName ?? this.roomName,
      roomType: roomType ?? this.roomType,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department': department,
      'className': className,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'floor': floor,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomName': roomName,
      'roomType': roomType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClassMapping.fromJson(Map<String, dynamic> json) {
    return ClassMapping(
      id: json['id'] as String? ?? 'map_${DateTime.now().millisecondsSinceEpoch}',
      department: json['department'] as String? ?? 'General',
      className: json['className'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      roomId: json['roomId'] as String? ?? '',
      roomNumber: json['roomNumber'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      roomType: json['roomType'] as String? ?? 'Classroom',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
