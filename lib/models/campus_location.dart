import 'campus_floor.dart';
import 'location_category.dart';

/// Data model representing a physical building or landmark on campus.
class CampusLocation {
  final String id;
  final String name;
  final String shortCode;
  final LocationCategory category;
  final String description;
  final int floorCount;
  final List<String> departments;
  final String operatingHours;
  final double latitude;
  final double longitude;
  final double mapX; // Normalized X position on prototype map (0.0 to 1.0)
  final double mapY; // Normalized Y position on prototype map (0.0 to 1.0)
  final bool isSaved;
  final List<String> tags;
  final List<CampusFloor> floors;
  final double? entranceLatitude;
  final double? entranceLongitude;
  final bool hasIndoorMap;
  final String? buildingType;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.category,
    required this.description,
    required this.floorCount,
    required this.departments,
    required this.operatingHours,
    required this.latitude,
    required this.longitude,
    this.mapX = 0.5,
    this.mapY = 0.5,
    this.isSaved = false,
    this.tags = const [],
    this.floors = const [],
    this.entranceLatitude,
    this.entranceLongitude,
    this.hasIndoorMap = true,
    this.buildingType,
  });

  /// Effective entrance latitude (falls back to building latitude if not specified)
  double get effectiveEntranceLatitude => entranceLatitude ?? latitude;

  /// Effective entrance longitude (falls back to building longitude if not specified)
  double get effectiveEntranceLongitude => entranceLongitude ?? longitude;

  /// Effective building type name
  String get effectiveBuildingType => buildingType ?? category.displayName;

  CampusLocation copyWith({
    String? id,
    String? name,
    String? shortCode,
    LocationCategory? category,
    String? description,
    int? floorCount,
    List<String>? departments,
    String? operatingHours,
    double? latitude,
    double? longitude,
    double? mapX,
    double? mapY,
    bool? isSaved,
    List<String>? tags,
    List<CampusFloor>? floors,
    double? entranceLatitude,
    double? entranceLongitude,
    bool? hasIndoorMap,
    String? buildingType,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      category: category ?? this.category,
      description: description ?? this.description,
      floorCount: floorCount ?? this.floorCount,
      departments: departments ?? this.departments,
      operatingHours: operatingHours ?? this.operatingHours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      isSaved: isSaved ?? this.isSaved,
      tags: tags ?? this.tags,
      floors: floors ?? this.floors,
      entranceLatitude: entranceLatitude ?? this.entranceLatitude,
      entranceLongitude: entranceLongitude ?? this.entranceLongitude,
      hasIndoorMap: hasIndoorMap ?? this.hasIndoorMap,
      buildingType: buildingType ?? this.buildingType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
      'category': category.name,
      'description': description,
      'floorCount': floorCount,
      'departments': departments,
      'operatingHours': operatingHours,
      'latitude': latitude,
      'longitude': longitude,
      'mapX': mapX,
      'mapY': mapY,
      'isSaved': isSaved,
      'tags': tags,
      'floors': floors.map((f) => f.toJson()).toList(),
      'entranceLatitude': entranceLatitude,
      'entranceLongitude': entranceLongitude,
      'hasIndoorMap': hasIndoorMap,
      'buildingType': buildingType,
    };
  }

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'] as String? ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      shortCode: json['shortCode'] as String? ?? '',
      category: LocationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => LocationCategory.academic,
      ),
      description: json['description'] as String? ?? '',
      floorCount: json['floorCount'] as int? ?? 1,
      departments: (json['departments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      operatingHours: json['operatingHours'] as String? ?? '08:00 AM - 06:00 PM',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 11.2735,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.6068,
      mapX: (json['mapX'] as num?)?.toDouble() ?? 0.5,
      mapY: (json['mapY'] as num?)?.toDouble() ?? 0.5,
      isSaved: json['isSaved'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      floors: (json['floors'] as List<dynamic>?)
              ?.map((e) => CampusFloor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      entranceLatitude: (json['entranceLatitude'] as num?)?.toDouble(),
      entranceLongitude: (json['entranceLongitude'] as num?)?.toDouble(),
      hasIndoorMap: json['hasIndoorMap'] as bool? ?? true,
      buildingType: json['buildingType'] as String?,
    );
  }
}
