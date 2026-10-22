import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_floor.dart';
import '../models/campus_room.dart';

/// Clean schematic indoor floor plan widget displaying rooms, corridor, stairs, and entrance.
/// Supports displaying custom architectural floor plan images when provided,
/// or generating an interactive blueprint schematic view.
class FloorSchematicView extends StatelessWidget {
  final String buildingName;
  final CampusFloor floor;
  final String? selectedRoomId;
  final ValueChanged<CampusRoom> onRoomSelected;
  final String? customFloorAssetPath;

  const FloorSchematicView({
    super.key,
    required this.buildingName,
    required this.floor,
    this.selectedRoomId,
    required this.onRoomSelected,
    this.customFloorAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    // Split rooms between top wing (North) and bottom wing (South)
    final rooms = floor.rooms;
    final half = (rooms.length / 2).ceil();
    final topRooms = rooms.take(half).toList();
    final bottomRooms = rooms.skip(half).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Architectural blueprint subtle grid or custom image asset
            if (customFloorAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  customFloorAssetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _BlueprintGrid(),
                ),
              )
            else
              const _BlueprintGrid(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Building Header Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        '${buildingName.toUpperCase()} • ${floor.floorName.toUpperCase()}',
                        style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TOP ROW ROOMS (North Wing)
                  Row(
                    children: topRooms.map((room) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _RoomBox(
                            room: room,
                            isSelected: room.id == selectedRoomId,
                            onTap: () => onRoomSelected(room),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // CENTRAL CORRIDOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.linear_scale_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MAIN CORRIDOR',
                              style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.linear_scale_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BOTTOM ROW ROOMS (South Wing)
                  if (bottomRooms.isNotEmpty)
                    Row(
                      children: bottomRooms.map((room) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _RoomBox(
                              room: room,
                              isSelected: room.id == selectedRoomId,
                              onTap: () => onRoomSelected(room),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // BOTTOM UTILITY ROW: Entrance & Stairs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _UtilityBadge(
                        icon: Icons.door_front_door_outlined,
                        label: 'Main Entrance',
                        color: AppColors.primary,
                      ),
                      _UtilityBadge(
                        icon: Icons.stairs_outlined,
                        label: 'Stairs & Elevator',
                        color: AppColors.secondary,
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

class _RoomBox extends StatelessWidget {
  final CampusRoom room;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomBox({
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surface.withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                room.roomCode,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.textInverse
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              room.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textInverse
                    : AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _UtilityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintGrid extends StatelessWidget {
  const _BlueprintGrid();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BlueprintGridPainter()),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 0.8;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
