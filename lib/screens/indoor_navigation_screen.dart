import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_floor.dart';
import '../models/campus_location.dart';
import '../models/campus_room.dart';
import '../models/indoor_navigation.dart';
import '../services/campus_location_service.dart';
import '../services/indoor_navigation_service.dart';
import '../widgets/floor_schematic_view.dart';
import '../widgets/indoor_nav_schematic_view.dart';
import '../widgets/location_detail_sheet.dart';

/// Indoor Navigation and Floor Layout Screen.
/// Provides building floor switching, room/lab selection, floor plan viewing,
/// and indoor pathfinding from the building entrance to any room or office.
class IndoorNavigationScreen extends StatefulWidget {
  final CampusLocation building;
  final int initialFloorNumber;
  final CampusRoom? initialDestinationRoom;

  const IndoorNavigationScreen({
    super.key,
    required this.building,
    this.initialFloorNumber = 0,
    this.initialDestinationRoom,
  });

  @override
  State<IndoorNavigationScreen> createState() => _IndoorNavigationScreenState();
}

class _IndoorNavigationScreenState extends State<IndoorNavigationScreen> {
  final CampusLocationService _locationService = CampusLocationService();
  final IndoorNavigationService _navService = IndoorNavigationService();

  late int _selectedFloorNumber;
  CampusRoom? _selectedRoom;
  IndoorRoute? _activeIndoorRoute;
  bool _isNavigating = false;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedFloorNumber =
        widget.initialDestinationRoom?.floor ?? widget.initialFloorNumber;
    _selectedRoom =
        widget.initialDestinationRoom ??
        (_currentFloor.rooms.isNotEmpty ? _currentFloor.rooms.first : null);

    if (widget.initialDestinationRoom != null) {
      _calculateIndoorRoute(widget.initialDestinationRoom!);
    }
  }

  CampusFloor get _currentFloor {
    final floors = widget.building.floors;
    if (floors.isEmpty) {
      return CampusFloor(
        floorNumber: 0,
        floorName: 'Ground Level',
        description: widget.building.description,
      );
    }
    return floors.firstWhere(
      (f) => f.floorNumber == _selectedFloorNumber,
      orElse: () => floors.first,
    );
  }

  void _onFloorSelected(int floorNum) {
    setState(() {
      _selectedFloorNumber = floorNum;
      _activeIndoorRoute = null;
      _isNavigating = false;
      _currentStepIndex = 0;

      final floor = widget.building.floors.firstWhere(
        (f) => f.floorNumber == floorNum,
        orElse: () => _currentFloor,
      );

      if (floor.rooms.isNotEmpty) {
        _selectedRoom = floor.rooms.first;
      } else {
        _selectedRoom = null;
      }
    });
  }

  void _onRoomSelected(CampusRoom room) {
    setState(() {
      _selectedRoom = room;
      _activeIndoorRoute = null;
      _isNavigating = false;
      _currentStepIndex = 0;
    });
  }

  void _calculateIndoorRoute(CampusRoom room) {
    final route = _navService.calculateRoute(
      building: widget.building,
      destinationRoom: room,
      currentFloorNumber: _selectedFloorNumber,
    );

    setState(() {
      _selectedRoom = room;
      _activeIndoorRoute = route;
      _isNavigating = true;
      _currentStepIndex = 0;
    });
  }

  void _nextStep() {
    if (_activeIndoorRoute == null) return;
    if (_currentStepIndex < _activeIndoorRoute!.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      _showArrivalDialog();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _showArrivalDialog() {
    if (_selectedRoom == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('You Have Arrived!', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'You have reached ${_selectedRoom!.roomCode} (${_selectedRoom!.name}) on ${_selectedRoom!.floorDisplay}.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isNavigating = false;
                _activeIndoorRoute = null;
                _currentStepIndex = 0;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(CampusRoom room) {
    LocationDetailSheet.show(
      context,
      room: room,
      onToggleSave: () {
        _locationService.toggleRoomSaved(room.id);
        setState(() {});
      },
      onNavigate: () {
        _calculateIndoorRoute(room);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final building = widget.building;
    final floors = building.floors;
    final currentFloor = _currentFloor;
    final selectedRoom = _selectedRoom;
    final activeRoute = _activeIndoorRoute;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isNavigating ? 'Indoor Navigation' : building.name,
              style: AppTextStyles.heading2,
            ),
            Text(
              '${building.shortCode} • ${currentFloor.floorName}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_isNavigating)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isNavigating = false;
                  _activeIndoorRoute = null;
                  _currentStepIndex = 0;
                });
              },
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Exit Route'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Floor Selector Switcher (Ground | Floor 1 | Floor 2 | Floor 3)
            if (floors.length > 1 && !_isNavigating)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: floors.map((floor) {
                    final isSelected =
                        floor.floorNumber == _selectedFloorNumber;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _onFloorSelected(floor.floorNumber),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            floor.shortName,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.textInverse
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // 2. Active Route Metric Header Bar (if navigating)
            if (_isNavigating && activeRoute != null && selectedRoom != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedRoom.roomCode,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textInverse,
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
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'From ${activeRoute.startPointName}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 26,
                      width: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${activeRoute.distanceMeters}m',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '~${activeRoute.estimatedMinutes} min',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3. Interactive Floor Plan Display or Navigation Schematic
            Expanded(
              child: SingleChildScrollView(
                child: building.floors.isEmpty
                    ? _buildFloorPlaceholder(building)
                    : (_isNavigating &&
                          activeRoute != null &&
                          selectedRoom != null)
                    ? IndoorNavSchematicView(
                        buildingName: building.name,
                        floor: currentFloor,
                        destinationRoom: selectedRoom,
                        startPointName: activeRoute.startPointName,
                        isMultiFloorTransit: activeRoute.isDifferentFloor,
                        nodePath: activeRoute.nodePath,
                      )
                    : FloorSchematicView(
                        buildingName: building.name,
                        floor: currentFloor,
                        selectedRoomId: selectedRoom?.id,
                        onRoomSelected: _onRoomSelected,
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Bottom Information or Turn-by-Turn Guidance Card
            if (_isNavigating && activeRoute != null) ...[
              // Active Turn-by-Turn Card
              _buildTurnByTurnGuidanceCard(activeRoute),
            ] else if (selectedRoom != null) ...[
              // Room Selection & Indoor Navigate Action Card
              _buildRoomSelectionCard(selectedRoom),
            ] else if (building.floors.isEmpty) ...[
              // Placeholder Building Bottom Info
              _buildNoFloorInfoCard(building),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTurnByTurnGuidanceCard(IndoorRoute route) {
    final currentStep = route.steps[_currentStepIndex];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'STEP ${_currentStepIndex + 1} OF ${route.steps.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${currentStep.distanceMeters} meters',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  currentStep.icon,
                  color: AppColors.textInverse,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep.instruction,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 2),
                    Text(currentStep.detail, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_currentStepIndex > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    child: const Text('Back'),
                  ),
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(
                    _currentStepIndex == route.steps.length - 1
                        ? 'Arrived'
                        : 'Next Step',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelectionCard(CampusRoom room) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  room.roomCode,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textInverse,
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
                      room.name,
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.building.name} • ${room.floorDisplay}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            room.description,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRoomDetails(room),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Room Info'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _calculateIndoorRoute(room),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Navigate Here'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlaceholder(CampusLocation building) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.domain_verification_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${building.name} Floor Layout',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Indoor floor blueprint for ${building.name} is currently being mapped.\nCustom architectural floor plans can be placed under assets/floors/${building.id}_floor_0.png.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hours: ${building.operatingHours}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFloorInfoCard(CampusLocation building) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(building.name, style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(building.description, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
