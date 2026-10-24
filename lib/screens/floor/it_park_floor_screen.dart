import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/it_park_layout_data.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../services/campus_location_service.dart';
import '../../widgets/it_park_2d_floor_map.dart';
import '../../widgets/location_detail_sheet.dart';

/// Interactive Floor Layout Screen for IT Park building.
/// Features:
/// - Hand-drawn accurate floor plans for Ground (001-024), Floor 1 (101-128), and Floor 2 (201-227).
/// - Floor switcher (Ground, First, Second Floor).
/// - Zoomable, pannable 2D architectural blueprint map.
/// - Instant room search by number (e.g., 001, 103, 128, 203, 227).
/// - Collision-free corridor route polyline from Entrance or Staircase.
/// - Multi-floor staircase navigation support.
class ITParkFloorScreen extends StatefulWidget {
  final CampusLocation building;
  final int initialFloorNumber;
  final String? initialSelectedRoomCodeOrId;
  final ValueChanged<String>? onNavigateToBuilding;
  final bool startNavigationImmediately;

  const ITParkFloorScreen({
    super.key,
    required this.building,
    this.initialFloorNumber = 0,
    this.initialSelectedRoomCodeOrId,
    this.onNavigateToBuilding,
    this.startNavigationImmediately = false,
  });

  @override
  State<ITParkFloorScreen> createState() => _ITParkFloorScreenState();
}

class _ITParkFloorScreenState extends State<ITParkFloorScreen> {
  final CampusLocationService _service = CampusLocationService();
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();

  late int _selectedFloorNumber;
  ITParkRoomData? _selectedRoom;
  bool _startFromEntrance = true;
  List<Offset> _routePoints = [];

  // Multi-floor navigation pending target
  ITParkRoomData? _multiFloorDestination;

  // Search autocomplete results
  List<ITParkRoomData> _searchResults = [];
  bool _isSearching = false;

  // Viewport metrics for centering and overview fitting
  Size? _viewportSize;
  bool _hasFittedInitialView = false;

  // Active step-by-step corridor navigation state
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  List<ITParkNavStep> _navSteps = [];

  @override
  void initState() {
    super.initState();
    _selectedFloorNumber = widget.initialFloorNumber.clamp(0, 2);

    // Initial room selection
    if (widget.initialSelectedRoomCodeOrId != null) {
      final found = ITParkLayoutData.findRoomByCode(
        widget.initialSelectedRoomCodeOrId!,
      );
      if (found != null) {
        _selectedFloorNumber = found.floor;
        _selectedRoom = found;
      }
    }

    if (_selectedRoom == null) {
      final defaultRooms = ITParkLayoutData.getRoomsForFloor(_selectedFloorNumber);
      _selectedRoom = defaultRooms.isNotEmpty ? defaultRooms.first : null;
    }

    _updateRoute();

    if (widget.startNavigationImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedRoom != null) {
          _startNavigation();
        }
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFloorSelected(int floorNum) {
    setState(() {
      _selectedFloorNumber = floorNum;
      _multiFloorDestination = null;

      // Select first room on floor if current selection is not on this floor
      if (_selectedRoom == null || _selectedRoom!.floor != floorNum) {
        final floorRooms = ITParkLayoutData.getRoomsForFloor(floorNum);
        _selectedRoom = floorRooms.isNotEmpty ? floorRooms.first : null;
      }
      _updateRoute();
      if (_isNavigating) {
        _navSteps = _generateNavSteps();
        _currentStepIndex = 0;
      }
    });
    _fitOverview();
  }

  void _onRoomSelected(ITParkRoomData room) {
    setState(() {
      _selectedRoom = room;
      _multiFloorDestination = null;
      _updateRoute();
      if (_isNavigating) {
        _navSteps = _generateNavSteps();
        _currentStepIndex = 0;
      }
    });
    _centerOnRoom(room);
  }

  void _updateRoute() {
    if (_selectedRoom == null) {
      _routePoints = [];
      return;
    }

    final isGround = _selectedFloorNumber == 0;
    final Offset startPoint = (isGround && _startFromEntrance)
        ? ITParkLayoutData.groundEntrancePoint
        : ITParkLayoutData.stairsDoorPoint;

    final Offset destinationPoint = _selectedRoom!.bounds.center;

    _routePoints = ITParkLayoutData.calculateCorridorRoute(
      startPoint: startPoint,
      endPoint: destinationPoint,
      startAtEntrance: isGround && _startFromEntrance,
    );
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final results = ITParkLayoutData.searchRooms(query);
    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _selectSearchResult(ITParkRoomData room) {
    _searchController.text = room.displayLabel;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = false;
      _searchResults = [];

      if (room.floor != _selectedFloorNumber) {
        // Multi-floor destination selected!
        _multiFloorDestination = room;
        // On current floor, direct user to Central Staircase
        final stairsRoom = ITParkLayoutData.getRoomsForFloor(
          _selectedFloorNumber,
        ).firstWhere((r) => r.type == 'stairs');
        _selectedRoom = stairsRoom;
        _updateRoute();
      } else {
        _multiFloorDestination = null;
        _selectedRoom = room;
        _updateRoute();
      }
    });

    _centerOnRoom(room);
  }

  void _onViewportReady(Size size) {
    final bool isFirstTime = _viewportSize == null;
    _viewportSize = size;
    if (isFirstTime || !_hasFittedInitialView) {
      _hasFittedInitialView = true;
      _fitOverview();
    }
  }

  void _fitOverview() {
    if (_viewportSize == null || _viewportSize!.width <= 0 || _viewportSize!.height <= 0) return;
    final double scaleX = _viewportSize!.width / ITParkLayoutData.canvasWidth;
    final double scaleY = _viewportSize!.height / ITParkLayoutData.canvasHeight;
    final double scale = (math.min(scaleX, scaleY) * 0.94).clamp(0.25, 2.0);

    final double tx = (_viewportSize!.width - (ITParkLayoutData.canvasWidth * scale)) / 2;
    final double ty = (_viewportSize!.height - (ITParkLayoutData.canvasHeight * scale)) / 2;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _centerOnRoom(ITParkRoomData room) {
    if (_viewportSize == null || _viewportSize!.width <= 0 || _viewportSize!.height <= 0) {
      _fitOverview();
      return;
    }
    const double targetScale = 0.85; // comfortable zoom showing room and adjacent corridors
    final double roomCenterX = room.bounds.center.dx;
    final double roomCenterY = room.bounds.center.dy;

    final double tx = (_viewportSize!.width / 2) - (roomCenterX * targetScale);
    final double ty = (_viewportSize!.height / 2) - (roomCenterY * targetScale);

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
  }

  void _zoomIn() {
    _zoom(1.3);
  }

  void _zoomOut() {
    _zoom(0.77);
  }

  void _resetZoom() {
    _fitOverview();
  }

  void _zoom(double factor) {
    if (_viewportSize == null) {
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.scaleByDouble(factor, factor, 1.0, 1.0);
      _transformationController.value = matrix;
      return;
    }
    final double cx = _viewportSize!.width / 2;
    final double cy = _viewportSize!.height / 2;

    final Matrix4 current = _transformationController.value;
    final Matrix4 toCenter = Matrix4.identity()..translateByDouble(-cx, -cy, 0.0, 1.0);
    final Matrix4 scaleMatrix = Matrix4.identity()..scaleByDouble(factor, factor, 1.0, 1.0);
    final Matrix4 fromCenter = Matrix4.identity()..translateByDouble(cx, cy, 0.0, 1.0);

    _transformationController.value = fromCenter * scaleMatrix * toCenter * current;
  }

  void _centerOnWaypoint(Offset pt) {
    if (_viewportSize == null || _viewportSize!.width <= 0 || _viewportSize!.height <= 0) return;
    const double targetScale = 1.0;
    final double tx = (_viewportSize!.width / 2) - (pt.dx * targetScale);
    final double ty = (_viewportSize!.height / 2) - (pt.dy * targetScale);

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
  }

  List<ITParkNavStep> _generateNavSteps() {
    if (_selectedRoom == null) return [];

    final List<ITParkNavStep> steps = [];
    final isGround = _selectedFloorNumber == 0;
    final room = _selectedRoom!;

    // Case 1: Multi-floor destination (room is on another floor)
    if (_multiFloorDestination != null) {
      final dest = _multiFloorDestination!;
      steps.add(ITParkNavStep(
        stepIndex: 1,
        title: isGround && _startFromEntrance
            ? 'Start at Main Entrance'
            : 'Start at Central Hallway',
        instruction: isGround && _startFromEntrance
            ? 'Proceed through Main Entrance foyer and head towards Central Staircase.'
            : 'Follow the corridor walkway towards the Central Staircase.',
        icon: isGround && _startFromEntrance
            ? Icons.door_front_door_outlined
            : Icons.stairs_outlined,
        distanceMeters: 15.0,
        waypoint: (isGround && _startFromEntrance)
            ? ITParkLayoutData.groundEntrancePoint
            : ITParkLayoutData.stairsDoorPoint,
      ));

      steps.add(const ITParkNavStep(
        stepIndex: 2,
        title: 'Walk to Central Staircase',
        instruction: 'Follow the central corridor path directly to the stairwell.',
        icon: Icons.straight_rounded,
        distanceMeters: 20.0,
        waypoint: ITParkLayoutData.stairsDoorPoint,
      ));

      steps.add(ITParkNavStep(
        stepIndex: 3,
        title: 'Take Stairs to ${dest.floor == 1 ? "First Floor" : "Second Floor"}',
        instruction: 'Climb the stairs to Floor ${dest.floor}. Tap "Switch Floor" below to continue navigation to Room ${dest.displayLabel}.',
        icon: Icons.stairs_rounded,
        distanceMeters: 10.0,
        waypoint: ITParkLayoutData.stairsDoorPoint,
        isTransitStep: true,
        transitToFloor: dest.floor,
      ));

      return steps;
    }

    // Case 2: Room is on current floor
    if (_routePoints.isEmpty) return [];

    // Step 1: Start
    final startPt = _routePoints.first;
    steps.add(ITParkNavStep(
      stepIndex: 1,
      title: isGround && _startFromEntrance
          ? 'Start at Main Entrance'
          : 'Start at Central Staircase',
      instruction: isGround && _startFromEntrance
          ? 'Proceed forward through the entrance foyer into North Corridor.'
          : 'Exit the stairwell into the Floor $_selectedFloorNumber corridor.',
      icon: isGround && _startFromEntrance
          ? Icons.door_front_door_outlined
          : Icons.stairs_outlined,
      distanceMeters: 12.0,
      waypoint: startPt,
    ));

    // Intermediate turning waypoints along corridor
    for (int i = 1; i < _routePoints.length - 1; i++) {
      final prev = _routePoints[i - 1];
      final curr = _routePoints[i];
      final next = _routePoints[i + 1];

      final vIn = curr - prev;
      final vOut = next - curr;

      // 2D screen cross product
      final cross = vIn.dx * vOut.dy - vIn.dy * vOut.dx;
      final bool isRightTurn = cross > 10.0;
      final bool isLeftTurn = cross < -10.0;

      String corridorName = 'Corridor';
      if ((curr.dy - 205).abs() < 10 || (next.dy - 205).abs() < 10) {
        corridorName = 'North Corridor';
      } else if ((curr.dy - 515).abs() < 10 || (next.dy - 515).abs() < 10) {
        corridorName = 'South Corridor';
      } else if ((curr.dx - 195).abs() < 10 || (next.dx - 195).abs() < 10) {
        corridorName = 'West Corridor';
      } else if ((curr.dx - 645).abs() < 10 || (next.dx - 645).abs() < 10) {
        corridorName = 'East Corridor';
      }

      String title;
      String instruction;
      IconData icon;

      if (isLeftTurn) {
        title = 'Turn left into $corridorName';
        instruction = 'Turn left and continue along the hallway.';
        icon = Icons.turn_left_rounded;
      } else if (isRightTurn) {
        title = 'Turn right into $corridorName';
        instruction = 'Turn right and proceed along the hallway.';
        icon = Icons.turn_right_rounded;
      } else {
        title = 'Continue straight along $corridorName';
        instruction = 'Follow the hallway walkway path.';
        icon = Icons.straight_rounded;
      }

      final double legDist = (vOut.distance * 0.15).clamp(8.0, 45.0);

      steps.add(ITParkNavStep(
        stepIndex: steps.length + 1,
        title: title,
        instruction: instruction,
        icon: icon,
        distanceMeters: legDist,
        waypoint: curr,
      ));
    }

    // Final Arrival Step
    final double finalLegDist = (_routePoints.length > 1
            ? (_routePoints.last - _routePoints[_routePoints.length - 2]).distance * 0.15
            : 5.0)
        .clamp(4.0, 15.0);

    steps.add(ITParkNavStep(
      stepIndex: steps.length + 1,
      title: 'Arrive at ${room.displayLabel} - ${room.name}',
      instruction: 'Your destination is directly ahead. Enter through the room entrance doorway.',
      icon: Icons.check_circle_rounded,
      distanceMeters: finalLegDist,
      waypoint: room.bounds.center,
    ));

    return steps;
  }

  void _startNavigation() {
    final steps = _generateNavSteps();
    setState(() {
      _navSteps = steps;
      _isNavigating = true;
      _currentStepIndex = 0;
    });
    if (_navSteps.isNotEmpty) {
      _centerOnWaypoint(_navSteps.first.waypoint);
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _navSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _centerOnWaypoint(_navSteps[_currentStepIndex].waypoint);
    } else {
      _finishNavigation();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _centerOnWaypoint(_navSteps[_currentStepIndex].waypoint);
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _currentStepIndex = 0;
    });
    _fitOverview();
  }

  void _finishNavigation() {
    final room = _selectedRoom;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('You Have Arrived!', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          room != null
              ? 'You have reached ${room.displayLabel} (${room.name}) on Floor ${room.floor} of IT Park.'
              : 'You have reached your indoor destination.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopNavigation();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRoomDetailsModal(CampusRoom room) {
    LocationDetailSheet.show(
      context,
      room: room,
      onToggleSave: () {
        final success = _service.toggleRoomSaved(room.id);
        if (!success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in as a student to use bookmarks.'),
              backgroundColor: Color(0xFF1E293B),
            ),
          );
        } else {
          setState(() {});
        }
      },
      onNavigate: () {
        Navigator.pop(context);
        _startNavigation();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoom = _selectedRoom;
    final CampusRoom? campusRoom = selectedRoom?.toCampusRoom();
    final isSaved = campusRoom != null && _service.isRoomBookmarked(campusRoom.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IT Park Floor Layout', style: AppTextStyles.heading2),
            Text(
              'Ground, 1st & 2nd Floor Indoor Navigation',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Zoom & Center',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOOR SELECTOR CHIPS BAR
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  _FloorTab(
                    title: 'Ground Floor',
                    subtitle: 'Rooms 001–024',
                    isSelected: _selectedFloorNumber == 0,
                    onTap: () => _onFloorSelected(0),
                  ),
                  _FloorTab(
                    title: 'First Floor',
                    subtitle: 'Rooms 101–128',
                    isSelected: _selectedFloorNumber == 1,
                    onTap: () => _onFloorSelected(1),
                  ),
                  _FloorTab(
                    title: 'Second Floor',
                    subtitle: 'Rooms 201–227',
                    isSelected: _selectedFloorNumber == 2,
                    onTap: () => _onFloorSelected(2),
                  ),
                ],
              ),
            ),

            // 2. ROOM NUMBER SEARCH BAR & AUTOCOMPLETE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search room number (e.g. 001, 103, 128, 203, 227)...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Autocomplete Dropdown List
            if (_isSearching && _searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(6),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final match = _searchResults[index];
                    final floorName = match.floor == 0
                        ? 'Ground Floor'
                        : (match.floor == 1 ? 'First Floor' : 'Second Floor');
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            match.displayLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          match.name,
                          style: AppTextStyles.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'IT Park • $floorName',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.north_west_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        onTap: () => _selectSearchResult(match),
                      ),
                    );
                  },
                ),
              ),

            // 3. START POINT SWITCHER BAR (Entrance vs Staircase)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Route from: ',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_selectedFloorNumber == 0) ...[
                            ChoiceChip(
                              label: const Text('Main Entrance'),
                              selected: _startFromEntrance,
                              visualDensity: VisualDensity.compact,
                              onSelected: (val) {
                                setState(() {
                                  _startFromEntrance = true;
                                  _updateRoute();
                                });
                              },
                              avatar: const Icon(
                                Icons.door_front_door_outlined,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ChoiceChip(
                            label: const Text('Staircase (Steps)'),
                            selected: _selectedFloorNumber != 0 || !_startFromEntrance,
                            visualDensity: VisualDensity.compact,
                            onSelected: (val) {
                              setState(() {
                                _startFromEntrance = false;
                                _updateRoute();
                              });
                            },
                            avatar: const Icon(Icons.stairs_outlined, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Zoom Floating Action Controls
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_in_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: _zoomIn,
                    tooltip: 'Zoom In',
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_out_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: _zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                ],
              ),
            ),

            // 4. MULTI-FLOOR TRANSIT NOTICE BANNER
            if (_multiFloorDestination != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stairs_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Room ${_multiFloorDestination!.displayLabel} is on ${_multiFloorDestination!.floor == 1 ? "First Floor" : "Second Floor"}. Follow route to Staircase.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final target = _multiFloorDestination!;
                        _onFloorSelected(target.floor);
                        _onRoomSelected(target);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFB45309),
                      ),
                      child: const Text('Switch Floor'),
                    ),
                  ],
                ),
              ),

            // 5. 2D INTERACTIVE ZOOMABLE FLOOR MAP
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ITPark2DFloorMap(
                  floorNumber: _selectedFloorNumber,
                  selectedRoom: selectedRoom,
                  onRoomTap: _onRoomSelected,
                  startFromEntrance: _startFromEntrance,
                  routePoints: _routePoints,
                  transformationController: _transformationController,
                  onViewportReady: _onViewportReady,
                  activeUserPosition: _isNavigating && _navSteps.isNotEmpty
                      ? _navSteps[_currentStepIndex.clamp(0, _navSteps.length - 1)].waypoint
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 6. BOTTOM ACTIVE NAVIGATION CARD OR SELECTED ROOM CARD
            if (_isNavigating && _navSteps.isNotEmpty)
              _buildActiveNavigationCard()
            else if (selectedRoom != null && campusRoom != null)
              _buildSelectedRoomCard(selectedRoom, campusRoom, isSaved),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveNavigationCard() {
    final step = _navSteps[_currentStepIndex.clamp(0, _navSteps.length - 1)];
    final isLastStep = _currentStepIndex >= _navSteps.length - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Step pill + Distance + Cancel
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'STEP ${_currentStepIndex + 1} OF ${_navSteps.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '~${step.distanceMeters.round()}m',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _stopNavigation,
                tooltip: 'Exit Navigation',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Direction Icon + Step Title & Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, color: const Color(0xFF00E5FF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.heading3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.instruction,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (step.isTransitStep && step.transitToFloor != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final targetFloor = step.transitToFloor!;
                  _onFloorSelected(targetFloor);
                  if (_multiFloorDestination != null) {
                    _onRoomSelected(_multiFloorDestination!);
                  }
                },
                icon: const Icon(Icons.stairs_rounded, size: 16),
                label: Text('Switch to Floor ${step.transitToFloor}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Back + Next Step / Finish
          Row(
            children: [
              if (_currentStepIndex > 0) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isLastStep ? AppColors.success : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(
                    isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(isLastStep ? 'Finish Navigation' : 'Next Step'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomCard(
    ITParkRoomData selectedRoom,
    CampusRoom campusRoom,
    bool isSaved,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedRoom.displayLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRoom.name,
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IT Park • Floor ${selectedRoom.floor} • Corridor Route',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.accent : AppColors.textSecondary,
                ),
                onPressed: () {
                  final success = _service.toggleRoomSaved(campusRoom.id);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in as a student to save bookmarks.'),
                      ),
                    );
                  } else {
                    setState(() {});
                  }
                },
                tooltip: 'Bookmark Room',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedRoom.description,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRoomDetailsModal(campusRoom),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Room Info'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Model representing a single walkable navigation leg/step in IT Park.
class ITParkNavStep {
  final int stepIndex;
  final String title;
  final String instruction;
  final IconData icon;
  final double distanceMeters;
  final Offset waypoint;
  final bool isTransitStep;
  final int? transitToFloor;

  const ITParkNavStep({
    required this.stepIndex,
    required this.title,
    required this.instruction,
    required this.icon,
    required this.distanceMeters,
    required this.waypoint,
    this.isTransitStep = false,
    this.transitToFloor,
  });
}

class _FloorTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloorTab({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
