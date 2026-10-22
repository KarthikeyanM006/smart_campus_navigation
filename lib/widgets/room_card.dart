import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_room.dart';
import '../services/campus_location_service.dart';

/// Reusable card displaying room-level search results (e.g., ITP201 -> IT Park, Floor 2).
class RoomCard extends StatelessWidget {
  final CampusRoom room;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onNavigate;
  final bool? isSaved;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onToggleSaved,
    this.onNavigate,
    this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = CampusLocationService();
    final bool currentlySaved =
        isSaved ?? locationService.isRoomBookmarked(room.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Room Code Badge, Room Name, Bookmark Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        room.roomCode,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        room.name,
                        style: AppTextStyles.heading3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        currentlySaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: currentlySaved
                            ? Colors.black
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      onPressed: onToggleSaved,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: currentlySaved
                          ? 'Remove Bookmark'
                          : 'Bookmark',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  room.description,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Bottom Meta: Building, Floor, Category, Navigate action
                Row(
                  children: [
                    _MetaBadge(
                      icon: Icons.business_outlined,
                      label: room.buildingName,
                    ),
                    const SizedBox(width: 8),
                    _MetaBadge(
                      icon: Icons.layers_outlined,
                      label: room.floorDisplay,
                    ),
                    const Spacer(),
                    if (onNavigate != null)
                      TextButton.icon(
                        onPressed: onNavigate,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 14),
                        label: Text(
                          'Navigate',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
