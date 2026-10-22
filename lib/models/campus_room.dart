import 'location_category.dart';

/// Data model representing a specific room, lab, classroom, or office inside a building.
class CampusRoom {
  final String id;
  final String roomCode; // e.g., 'ITP201'
  final String name; // e.g., 'Advanced Computing & AI Lab'
  final String buildingId; // e.g., 'loc_it_park'
  final String buildingName; // e.g., 'IT Park'
  final int floor; // e.g., 2
  final LocationCategory category;
  final String description;
  final String operatingHours;
  final bool isSaved;
  final List<String> tags;
  final String? department; // e.g., 'CSE'
  final String? className; // e.g., 'CSE-A'
  final String? roomType; // e.g., 'Classroom', 'Laboratory', 'Faculty Office'
  final double? latitude;
  final double? longitude;

  const CampusRoom({
    required this.id,
    required this.roomCode,
    required this.name,
    required this.buildingId,
    required this.buildingName,
    required this.floor,
    required this.category,
    required this.description,
    required this.operatingHours,
    this.isSaved = false,
    this.tags = const [],
    this.department,
    this.className,
    this.roomType,
    this.latitude,
    this.longitude,
  });

  String get floorDisplay => floor == 0 ? 'Ground Level' : 'Floor $floor';

  String get effectiveRoomType => roomType ?? category.displayName;

  CampusRoom copyWith({
    String? id,
    String? roomCode,
    String? name,
    String? buildingId,
    String? buildingName,
    int? floor,
    LocationCategory? category,
    String? description,
    String? operatingHours,
    bool? isSaved,
    List<String>? tags,
    String? department,
    String? className,
    String? roomType,
    double? latitude,
    double? longitude,
  }) {
    return CampusRoom(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      name: name ?? this.name,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      floor: floor ?? this.floor,
      category: category ?? this.category,
      description: description ?? this.description,
      operatingHours: operatingHours ?? this.operatingHours,
      isSaved: isSaved ?? this.isSaved,
      tags: tags ?? this.tags,
      department: department ?? this.department,
      className: className ?? this.className,
      roomType: roomType ?? this.roomType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'name': name,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'floor': floor,
      'category': category.name,
      'description': description,
      'operatingHours': operatingHours,
      'isSaved': isSaved,
      'tags': tags,
      'department': department,
      'className': className,
      'roomType': roomType,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CampusRoom.fromJson(Map<String, dynamic> json) {
    return CampusRoom(
      id: json['id'] as String? ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      roomCode: json['roomCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      category: LocationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => LocationCategory.academic,
      ),
      description: json['description'] as String? ?? '',
      operatingHours: json['operatingHours'] as String? ?? '08:00 AM - 05:00 PM',
      isSaved: json['isSaved'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      department: json['department'] as String?,
      className: json['className'] as String?,
      roomType: json['roomType'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
