import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_floor.dart';
import '../models/campus_location.dart';
import '../models/campus_room.dart';
import '../models/location_category.dart';
import '../screens/auth/student_login_screen.dart';
import '../services/auth_service.dart';
import '../services/campus_location_service.dart';

/// Modal bottom sheet displaying structured location details:
/// Building, Floor, Category, Description, Operating hours, Floors selector, and Navigate.
/// Real-time reactive Save/Bookmark button with BLACK filled bookmark icon when saved.
class LocationDetailSheet extends StatelessWidget {
  final String title;
  final String code;
  final String building;
  final String floor;
  final LocationCategory category;
  final String description;
  final String operatingHours;
  final bool? isSaved;
  final List<String> tags;
  final List<CampusFloor> floors;
  final ValueChanged<int>? onSelectFloor;
  final VoidCallback? onToggleSave;
  final VoidCallback onNavigate;
  final String? locationId;
  final String? roomId;
  final bool isRoom;

  const LocationDetailSheet({
    super.key,
    required this.title,
    required this.code,
    required this.building,
    required this.floor,
    required this.category,
    required this.description,
    required this.operatingHours,
    this.isSaved,
    required this.tags,
    this.floors = const [],
    this.onSelectFloor,
    this.onToggleSave,
    required this.onNavigate,
    this.locationId,
    this.roomId,
    this.isRoom = false,
  });

  /// Factory helper for a CampusRoom
  factory LocationDetailSheet.fromRoom({
    Key? key,
    required CampusRoom room,
    VoidCallback? onToggleSave,
    required VoidCallback onNavigate,
  }) {
    return LocationDetailSheet(
      key: key,
      title: room.name,
      code: room.roomCode,
      building: room.buildingName,
      floor: room.floorDisplay,
      category: room.category,
      description: room.description,
      operatingHours: room.operatingHours,
      tags: room.tags,
      floors: const [],
      onToggleSave: onToggleSave,
      onNavigate: onNavigate,
      locationId: room.buildingId,
      roomId: room.id,
      isRoom: true,
    );
  }

  /// Factory helper for a CampusLocation (Building)
  factory LocationDetailSheet.fromLocation({
    Key? key,
    required CampusLocation location,
    ValueChanged<int>? onSelectFloor,
    VoidCallback? onToggleSave,
    required VoidCallback onNavigate,
  }) {
    return LocationDetailSheet(
      key: key,
      title: location.name,
      code: location.shortCode,
      building: location.name,
      floor: location.floorCount > 1
          ? '${location.floorCount} Levels'
          : 'Ground Level',
      category: location.category,
      description: location.description,
      operatingHours: location.operatingHours,
      tags: location.tags,
      floors: location.floors,
      onSelectFloor: onSelectFloor,
      onToggleSave: onToggleSave,
      onNavigate: onNavigate,
      locationId: location.id,
      isRoom: false,
    );
  }

  static Future<void> show(
    BuildContext context, {
    CampusRoom? room,
    CampusLocation? location,
    ValueChanged<int>? onSelectFloor,
    VoidCallback? onToggleSave,
    required VoidCallback onNavigate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        if (room != null) {
          return LocationDetailSheet.fromRoom(
            room: room,
            onToggleSave: onToggleSave,
            onNavigate: () {
              Navigator.pop(ctx);
              onNavigate();
            },
          );
        } else if (location != null) {
          return LocationDetailSheet.fromLocation(
            location: location,
            onSelectFloor: (floorNum) {
              Navigator.pop(ctx);
              onSelectFloor?.call(floorNum);
            },
            onToggleSave: onToggleSave,
            onNavigate: () {
              Navigator.pop(ctx);
              onNavigate();
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _handleSavePressed(BuildContext context) {
    final authService = AuthService();
    final locationService = CampusLocationService();

    if (!authService.isStudent) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login as a student to use Saved Locations.'),
          action: SnackBarAction(
            label: 'Log In',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StudentLoginScreen(),
                ),
              );
            },
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (isRoom && roomId != null) {
      locationService.toggleRoomSaved(roomId!);
    } else if (locationId != null) {
      locationService.toggleSaved(locationId!);
    }

    onToggleSave?.call();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = CampusLocationService();
    final authService = AuthService();

    return ListenableBuilder(
      listenable: Listenable.merge([locationService, authService]),
      builder: (context, _) {
        final bool currentlySaved;
        if (!authService.isStudent) {
          currentlySaved = false;
        } else if (isSaved != null) {
          currentlySaved = isSaved!;
        } else if (isRoom && roomId != null) {
          currentlySaved = locationService.isRoomBookmarked(roomId!);
        } else if (locationId != null) {
          currentlySaved = locationService.isLocationBookmarked(locationId!);
        } else {
          currentlySaved = false;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Code Badge + Title + Subtitle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      code,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.heading2),
                        const SizedBox(height: 2),
                        Text(
                          '$building • $floor',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Structured Details Box: Building, Floor, Category, Operating hours
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _StructuredRow(
                      icon: Icons.business_outlined,
                      label: 'Building',
                      value: building,
                    ),
                    const Divider(height: 16),
                    _StructuredRow(
                      icon: Icons.layers_outlined,
                      label: 'Floor',
                      value: floor,
                    ),
                    const Divider(height: 16),
                    _StructuredRow(
                      icon: category.icon,
                      label: 'Category',
                      value: category.displayName,
                    ),
                    const Divider(height: 16),
                    _StructuredRow(
                      icon: Icons.access_time_rounded,
                      label: 'Operating hours',
                      value: operatingHours,
                    ),
                  ],
                ),
              ),

              // Floors Section for Multi-Floor Buildings
              if (floors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Floors',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tap to explore floor plan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: floors.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => onSelectFloor?.call(f.floorNumber),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            f.floorName,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Description Section
              Text(
                'Description',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.bodyMedium),

              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Bottom Actions: Save Bookmark + Navigate Button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSavePressed(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            currentlySaved ? Colors.black : AppColors.textPrimary,
                        side: BorderSide(
                          color: currentlySaved
                              ? Colors.black87
                              : AppColors.border,
                          width: currentlySaved ? 1.5 : 1.0,
                        ),
                        backgroundColor: currentlySaved
                            ? const Color(0xFFF1F5F9)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        currentlySaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: currentlySaved
                            ? Colors.black
                            : AppColors.textSecondary,
                      ),
                      label: Text(
                        currentlySaved ? 'Saved' : 'Save',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: currentlySaved
                              ? Colors.black
                              : AppColors.textPrimary,
                          fontWeight: currentlySaved
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: onNavigate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StructuredRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StructuredRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
