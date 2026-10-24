import 'package:flutter/material.dart';

import '../core/constants/mock_campus_data.dart';
import '../models/campus_floor.dart';
import '../models/campus_location.dart';
import '../models/campus_map_models.dart';
import '../models/campus_room.dart';
import '../models/class_mapping.dart';
import '../models/location_category.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// Centralized service managing campus data state:
/// Buildings, Floors, Rooms, Dynamic Class Mappings, Search, Navigation routing, and Bookmarks.
class CampusLocationService extends ChangeNotifier {
  static final CampusLocationService _instance =
      CampusLocationService._internal();
  factory CampusLocationService() => _instance;

  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  late List<CampusLocation> _locations;
  late List<CampusRoom> _rooms;
  late List<ClassMapping> _classMappings;

  String _searchQuery = '';
  LocationCategory _selectedCategory = LocationCategory.all;

  CampusLocationService._internal() {
    _initData();
    // Listen to auth changes so bookmarks and permissions update dynamically
    _authService.addListener(() {
      notifyListeners();
    });
  }

  void _initData() {
    _locations = List<CampusLocation>.from(MockCampusData.initialLocations);
    _rooms = List<CampusRoom>.from(MockCampusData.initialRooms);

    // Initial classroom mappings (e.g. CSE-A -> IT Park -> Floor 1 -> Room ITP001)
    _classMappings = [
      ClassMapping(
        id: 'map_cse_a',
        department: 'CSE',
        className: 'CSE-A',
        buildingId: 'loc_it_park',
        buildingName: 'IT Park',
        floor: 1,
        roomId: 'room_itp_101',
        roomNumber: 'ITP001',
        roomName: 'Main Foyer & Class Section A',
        roomType: 'Classroom',
        description: 'Primary lecture hall and tutorial section for CSE Semester IV Section A.',
      ),
      ClassMapping(
        id: 'map_cse_b',
        department: 'CSE',
        className: 'CSE-B',
        buildingId: 'loc_it_park',
        buildingName: 'IT Park',
        floor: 1,
        roomId: 'room_itp_102',
        roomNumber: 'ITP002',
        roomName: 'Data Structures Lab & Section B',
        roomType: 'Classroom',
        description: 'Undergraduate theory and lab session room for CSE Section B.',
      ),
      ClassMapping(
        id: 'map_cse_c',
        department: 'CSE',
        className: 'CSE-C',
        buildingId: 'loc_it_park',
        buildingName: 'IT Park',
        floor: 2,
        roomId: 'room_itp_201',
        roomNumber: 'ITP201',
        roomName: 'Advanced Computing & AI Lab',
        roomType: 'Classroom / Lab',
        description: 'High-performance AI workstation classroom for CSE Section C.',
      ),
      ClassMapping(
        id: 'map_it_a',
        department: 'IT',
        className: 'IT-A',
        buildingId: 'loc_it_park',
        buildingName: 'IT Park',
        floor: 2,
        roomId: 'room_itp_202',
        roomNumber: 'ITP202',
        roomName: 'Cloud Computing & DevOps Lab',
        roomType: 'Classroom / Lab',
        description: 'Virtualization & Cloud engineering laboratory for IT Section A.',
      ),
      ClassMapping(
        id: 'map_ece_a',
        department: 'ECE',
        className: 'ECE-A',
        buildingId: 'loc_ece_block',
        buildingName: 'ECE Block',
        floor: 0,
        roomId: 'room_ece_001',
        roomNumber: 'ECE101',
        roomName: 'VLSI & Digital Signal Processing Center',
        roomType: 'Classroom',
        description: 'Department of Electronics & Communication Section A lecture hall.',
      ),
      ClassMapping(
        id: 'map_eee_a',
        department: 'EEE',
        className: 'EEE-A',
        buildingId: 'loc_eie_eee_block',
        buildingName: 'EIE & EEE Block',
        floor: 0,
        roomId: 'room_eee_001',
        roomNumber: 'EEE001',
        roomName: 'Heavy Electrical Machines Lab',
        roomType: 'Classroom / Lab',
        description: 'Electrical machines and drives practical theory room for EEE Section A.',
      ),
      ClassMapping(
        id: 'map_sh_freshmen',
        department: 'S&H',
        className: 'SH-CHEM',
        buildingId: 'loc_sh_block',
        buildingName: 'S&H Block',
        floor: 0,
        roomId: 'room_sh_001',
        roomNumber: 'SH001',
        roomName: 'Engineering Chemistry Lab',
        roomType: 'Laboratory',
        description: 'First year engineering chemistry and polymer lab.',
      ),
    ];
  }

  String? _currentBuildingId;
  String? get currentBuildingId => _currentBuildingId;
  CampusLocation? get currentBuilding =>
      _currentBuildingId != null ? getLocationById(_currentBuildingId!) : null;

  void setCurrentBuilding(String? buildingId) {
    if (_currentBuildingId != buildingId) {
      _currentBuildingId = buildingId;
      notifyListeners();
    }
  }

  void clearCurrentBuilding() {
    if (_currentBuildingId != null) {
      _currentBuildingId = null;
      notifyListeners();
    }
  }

  // Getters
  List<CampusLocation> get allLocations => List.unmodifiable(_locations);
  List<CampusRoom> get allRooms => List.unmodifiable(_rooms);
  List<ClassMapping> get allClassMappings => List.unmodifiable(_classMappings);
  String get searchQuery => _searchQuery;
  LocationCategory get selectedCategory => _selectedCategory;
  LocationService get locationService => _locationService;
  AuthService get authService => _authService;
  MockUserLocation get userLocation => const MockUserLocation();

  /// Student Bookmarked Locations (Isolated per logged-in student)
  List<CampusLocation> get savedLocations {
    if (!_authService.isStudent) return const [];
    final savedIds = _authService.studentSavedLocationIds;
    return _locations.where((loc) => savedIds.contains(loc.id)).toList();
  }

  /// Student Bookmarked Rooms (Isolated per logged-in student)
  List<CampusRoom> get savedRooms {
    if (!_authService.isStudent) return const [];
    final savedIds = _authService.studentSavedRoomIds;
    return _rooms.where((room) => savedIds.contains(room.id)).toList();
  }

  bool isLocationBookmarked(String locationId) {
    if (!_authService.isStudent) return false;
    return _authService.isLocationSaved(locationId);
  }

  bool isRoomBookmarked(String roomId) {
    if (!_authService.isStudent) return false;
    return _authService.isRoomSaved(roomId);
  }

  /// Filtered Buildings based on Category & Search Query
  List<CampusLocation> get filteredLocations {
    return _locations.where((loc) {
      final matchesCategory =
          _selectedCategory == LocationCategory.all ||
          loc.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return matchesCategory;

      final matchesQuery =
          loc.name.toLowerCase().contains(query) ||
          loc.shortCode.toLowerCase().contains(query) ||
          loc.description.toLowerCase().contains(query) ||
          loc.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          loc.departments.any((dept) => dept.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Filtered Rooms based on Category & Search Query
  List<CampusRoom> get filteredRooms {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return _rooms.where((room) {
      final matchesCategory =
          _selectedCategory == LocationCategory.all ||
          room.category == _selectedCategory;

      final matchesQuery =
          room.roomCode.toLowerCase().contains(query) ||
          room.name.toLowerCase().contains(query) ||
          room.buildingName.toLowerCase().contains(query) ||
          room.description.toLowerCase().contains(query) ||
          (room.department != null && room.department!.toLowerCase().contains(query)) ||
          (room.className != null && room.className!.toLowerCase().contains(query)) ||
          'floor ${room.floor}'.contains(query) ||
          room.tags.any((tag) => tag.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Filtered Class Mappings based on Search Query (e.g. "CSE-A", "CSE", "ITP001", "Floor 1")
  List<ClassMapping> get filteredClassMappings {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return _classMappings.where((map) {
      return map.className.toLowerCase().contains(query) ||
          map.department.toLowerCase().contains(query) ||
          map.roomNumber.toLowerCase().contains(query) ||
          map.roomName.toLowerCase().contains(query) ||
          map.buildingName.toLowerCase().contains(query) ||
          'floor ${map.floor}'.contains(query) ||
          map.description.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  void setCategory(LocationCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Bookmark toggle for buildings (Checks student role via AuthService)
  bool toggleSaved(String locationId, {String? locationName}) {
    if (_authService.isStudent) {
      final name = locationName ?? getLocationById(locationId)?.name ?? '';
      final res = _authService.toggleBookmark(
        locationId,
        isRoom: false,
        locationName: name,
        locationType: 'building',
      );
      notifyListeners();
      return res;
    }

    // If guest
    return false;
  }

  /// Bookmark removal for buildings
  bool removeSaved(String locationId) {
    if (_authService.isStudent) {
      final res = _authService.removeBookmark(locationId, isRoom: false);
      notifyListeners();
      return res;
    }
    return false;
  }

  /// Bookmark toggle for rooms (Checks student role via AuthService)
  bool toggleRoomSaved(String roomId, {String? roomName}) {
    if (_authService.isStudent) {
      final name = roomName ?? getRoomById(roomId)?.name ?? '';
      final res = _authService.toggleBookmark(
        roomId,
        isRoom: true,
        locationName: name,
        locationType: 'room',
      );
      notifyListeners();
      return res;
    }

    // If guest
    return false;
  }

  /// Bookmark removal for rooms
  bool removeRoomSaved(String roomId) {
    if (_authService.isStudent) {
      final res = _authService.removeBookmark(roomId, isRoom: true);
      notifyListeners();
      return res;
    }
    return false;
  }

  CampusLocation? getLocationById(String id) {
    try {
      return _locations.firstWhere((loc) => loc.id == id);
    } catch (_) {
      return null;
    }
  }

  CampusRoom? getRoomById(String id) {
    try {
      return _rooms.firstWhere((room) => room.id == id);
    } catch (_) {
      return null;
    }
  }

  CampusRoom? getRoomByCode(String roomCode) {
    final clean = roomCode.trim().toUpperCase();
    final cleanNum = clean.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      return _rooms.firstWhere(
        (r) =>
            r.roomCode.toUpperCase() == clean ||
            r.roomCode.toUpperCase().replaceAll('ITP', '') == clean ||
            (cleanNum.isNotEmpty &&
                r.roomCode.toUpperCase().replaceAll('ITP', '') == cleanNum) ||
            r.tags.any((t) => t.toUpperCase() == clean),
      );
    } catch (_) {
      return null;
    }
  }

  ClassMapping? getClassMapping(String className) {
    final clean = className.trim().toUpperCase();
    try {
      return _classMappings.firstWhere((m) => m.className.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  List<CampusFloor> getFloorsForBuilding(String buildingId) {
    final building = getLocationById(buildingId);
    if (building != null && building.floors.isNotEmpty) {
      return building.floors;
    }
    return const [];
  }

  CampusFloor? getFloor(String buildingId, int floorNumber) {
    final floors = getFloorsForBuilding(buildingId);
    try {
      return floors.firstWhere((f) => f.floorNumber == floorNumber);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // ADMIN MANAGEMENT (CRUD)
  // ==========================================

  /// Saves or updates a dynamic Class Mapping (e.g. CSE-A -> IT Park -> Floor 1 -> Room ITP001)
  Future<void> saveClassMapping(ClassMapping mapping) async {
    final idx = _classMappings.indexWhere(
      (m) => m.id == mapping.id || m.className.toUpperCase() == mapping.className.toUpperCase(),
    );

    if (idx != -1) {
      _classMappings[idx] = mapping;
    } else {
      _classMappings.add(mapping);
    }

    // Also update any matching room's className & department
    final roomIdx = _rooms.indexWhere(
      (r) => r.roomCode.toUpperCase() == mapping.roomNumber.toUpperCase() || r.id == mapping.roomId,
    );
    if (roomIdx != -1) {
      final current = _rooms[roomIdx];
      _rooms[roomIdx] = current.copyWith(
        className: mapping.className,
        department: mapping.department,
        roomType: mapping.roomType,
      );
    }

    notifyListeners();
  }

  /// Deletes a Class Mapping
  Future<void> deleteClassMapping(String mappingId) async {
    _classMappings.removeWhere((m) => m.id == mappingId);
    notifyListeners();
  }

  /// Adds a new Campus Building
  Future<void> addBuilding(CampusLocation building) async {
    final existingIdx = _locations.indexWhere((b) => b.id == building.id);
    if (existingIdx != -1) {
      _locations[existingIdx] = building;
    } else {
      _locations.add(building);
    }
    notifyListeners();
  }

  /// Updates an existing Campus Building
  Future<void> updateBuilding(CampusLocation building) async {
    final idx = _locations.indexWhere((b) => b.id == building.id);
    if (idx != -1) {
      _locations[idx] = building;
      notifyListeners();
    }
  }

  /// Removes a Campus Building
  Future<void> deleteBuilding(String buildingId) async {
    _locations.removeWhere((b) => b.id == buildingId);
    _rooms.removeWhere((r) => r.buildingId == buildingId);
    _classMappings.removeWhere((m) => m.buildingId == buildingId);
    notifyListeners();
  }

  /// Adds or updates a room
  Future<void> saveRoom(CampusRoom room) async {
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      _rooms[idx] = room;
    } else {
      _rooms.add(room);
    }

    // Update building's floor room array
    final bIndex = _locations.indexWhere((b) => b.id == room.buildingId);
    if (bIndex != -1) {
      final building = _locations[bIndex];
      final floorIdx = building.floors.indexWhere((f) => f.floorNumber == room.floor);
      if (floorIdx != -1) {
        final floor = building.floors[floorIdx];
        final updatedRooms = List<CampusRoom>.from(floor.rooms);
        final rIdx = updatedRooms.indexWhere((r) => r.id == room.id);
        if (rIdx != -1) {
          updatedRooms[rIdx] = room;
        } else {
          updatedRooms.add(room);
        }
        final updatedFloors = List<CampusFloor>.from(building.floors);
        updatedFloors[floorIdx] = floor.copyWith(rooms: updatedRooms);
        _locations[bIndex] = building.copyWith(floors: updatedFloors);
      }
    }

    notifyListeners();
  }

  /// Deletes a room
  Future<void> deleteRoom(String roomId) async {
    final target = getRoomById(roomId);
    _rooms.removeWhere((r) => r.id == roomId);

    if (target != null) {
      final bIndex = _locations.indexWhere((b) => b.id == target.buildingId);
      if (bIndex != -1) {
        final building = _locations[bIndex];
        final floorIdx = building.floors.indexWhere((f) => f.floorNumber == target.floor);
        if (floorIdx != -1) {
          final floor = building.floors[floorIdx];
          final updatedRooms = floor.rooms.where((r) => r.id != roomId).toList();
          final updatedFloors = List<CampusFloor>.from(building.floors);
          updatedFloors[floorIdx] = floor.copyWith(rooms: updatedRooms);
          _locations[bIndex] = building.copyWith(floors: updatedFloors);
        }
      }
    }

    _classMappings.removeWhere((m) => m.roomId == roomId);
    notifyListeners();
  }

  /// Adds or updates floor information for a building
  Future<void> saveFloor(String buildingId, CampusFloor floor) async {
    final bIndex = _locations.indexWhere((b) => b.id == buildingId);
    if (bIndex != -1) {
      final building = _locations[bIndex];
      final updatedFloors = List<CampusFloor>.from(building.floors);
      final floorIdx = updatedFloors.indexWhere((f) => f.floorNumber == floor.floorNumber);
      if (floorIdx != -1) {
        updatedFloors[floorIdx] = floor;
      } else {
        updatedFloors.add(floor);
        updatedFloors.sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
      }
      _locations[bIndex] = building.copyWith(
        floors: updatedFloors,
        floorCount: updatedFloors.length,
      );
      notifyListeners();
    }
  }

  /// Deletes a floor from a building
  Future<void> deleteFloor(String buildingId, int floorNumber) async {
    final bIndex = _locations.indexWhere((b) => b.id == buildingId);
    if (bIndex != -1) {
      final building = _locations[bIndex];
      final updatedFloors = building.floors.where((f) => f.floorNumber != floorNumber).toList();
      _locations[bIndex] = building.copyWith(
        floors: updatedFloors,
        floorCount: updatedFloors.length,
      );
      _rooms.removeWhere((r) => r.buildingId == buildingId && r.floor == floorNumber);
      _classMappings.removeWhere((m) => m.buildingId == buildingId && m.floor == floorNumber);
      notifyListeners();
    }
  }

  /// Calculates an outdoor walking route from real GPS or fallback location to target building.
  OutdoorRoute calculateOutdoorRoute(CampusLocation destination) {
    final currentLoc = _locationService.currentLocation;

    final List<Offset> waypoints = [
      Offset(currentLoc.mapX, currentLoc.mapY),
      const Offset(0.50, 0.50), // Central Plaza main intersection
    ];

    if ((destination.mapX - 0.50).abs() > 0.05) {
      waypoints.add(Offset(destination.mapX, 0.50));
    }
    waypoints.add(Offset(destination.mapX, destination.mapY));

    // Calculate real straight-line distance in meters between GPS and building
    final straightLineDist = LocationService.calculateStraightLineDistance(
      startLatitude: currentLoc.latitude,
      startLongitude: currentLoc.longitude,
      endLatitude: destination.latitude,
      endLongitude: destination.longitude,
    );

    final int distanceMeters =
        ((straightLineDist.clamp(30.0, 950.0)) / 10).round() * 10;
    final int estimatedMinutes = (distanceMeters / 70).ceil().clamp(1, 15);

    return OutdoorRoute(
      startLocationName: currentLoc.isMock
          ? 'Campus Plaza (You are here)'
          : 'Current GPS Position',
      destination: destination,
      distanceMeters: distanceMeters,
      estimatedMinutes: estimatedMinutes,
      waypoints: waypoints,
    );
  }
}
