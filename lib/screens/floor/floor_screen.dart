import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../services/campus_location_service.dart';
import '../../widgets/floor_schematic_view.dart';
import '../../widgets/location_detail_sheet.dart';
import '../navigation/indoor_navigation_screen.dart';

/// Screen displaying the interactive indoor floor plan and room directory for a building.
class FloorScreen extends StatefulWidget {
  final CampusLocation building;
  final int initialFloorNumber;
  final String? initialSelectedRoomId;
  final ValueChanged<String>? onNavigateToBuilding;

  const FloorScreen({
    super.key,
    required this.building,
    this.initialFloorNumber = 0,
    this.initialSelectedRoomId,
    this.onNavigateToBuilding,
  });

  @override
  State<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends State<FloorScreen> {
  final CampusLocationService _service = CampusLocationService();
  late int _selectedFloorNumber;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _selectedFloorNumber = widget.initialFloorNumber;
    _selectedRoomId = widget.initialSelectedRoomId;
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

  CampusRoom? get _selectedRoom {
    if (_selectedRoomId == null) return null;
    final floorRooms = _currentFloor.rooms;
    try {
      return floorRooms.firstWhere((r) => r.id == _selectedRoomId);
    } catch (_) {
      return _service.getRoomById(_selectedRoomId!);
    }
  }

  void _onFloorSelected(int floorNum) {
    setState(() {
      _selectedFloorNumber = floorNum;
      // Reset selected room if not on the new floor
      final floor = widget.building.floors.firstWhere(
        (f) => f.floorNumber == floorNum,
        orElse: () => _currentFloor,
      );
      if (floor.rooms.isNotEmpty) {
        _selectedRoomId = floor.rooms.first.id;
      } else {
        _selectedRoomId = null;
      }
    });
  }

  void _openIndoorNavigation(CampusRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IndoorNavigationScreen(
          building: widget.building,
          floor: _currentFloor,
          destinationRoom: room,
        ),
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
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {});
        }
      },
      onNavigate: () {
        _openIndoorNavigation(room);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = widget.building.floors;
    final currentFloor = _currentFloor;
    final selectedRoom =
        _selectedRoom ??
        (currentFloor.rooms.isNotEmpty ? currentFloor.rooms.first : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.building.name, style: AppTextStyles.heading2),
            Text(
              '${widget.building.shortCode} • ${currentFloor.floorName}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOOR NAVIGATION SWITCHER BAR (Ground | 1 | 2 | 3)
            if (floors.length > 1)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

            // 2. FLOOR DESCRIPTION
            if (currentFloor.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  currentFloor.description!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 3. SCHEMATIC INDOOR FLOOR MAP
            Expanded(
              child: SingleChildScrollView(
                child: FloorSchematicView(
                  buildingName: widget.building.name,
                  floor: currentFloor,
                  selectedRoomId: selectedRoom?.id,
                  onRoomSelected: (room) {
                    setState(() {
                      _selectedRoomId = room.id;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. SELECTED ROOM PREVIEW BOTTOM CARD
            if (selectedRoom != null)
              Container(
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
                                style: AppTextStyles.heading3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.building.name} • ${selectedRoom.floorDisplay}',
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
                            onPressed: () =>
                                _showRoomDetailsModal(selectedRoom),
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('View Details'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openIndoorNavigation(selectedRoom),
                            icon: const Icon(
                              Icons.navigation_outlined,
                              size: 16,
                            ),
                            label: const Text('Navigate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
