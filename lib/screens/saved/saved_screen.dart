import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../services/auth_service.dart';
import '../../services/campus_location_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/location_card.dart';
import '../../widgets/location_detail_sheet.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../auth/student_login_screen.dart';
import '../navigation/indoor_navigation_screen.dart';
import '../outdoor/outdoor_navigation_screen.dart';

/// Screen displaying bookmarked campus buildings and rooms for students.
class SavedScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<String>? onLocateBuilding;

  const SavedScreen({super.key, this.onNavigateToTab, this.onLocateBuilding});

  void _openIndoorNavigation(BuildContext context, CampusRoom room) {
    final service = CampusLocationService();
    final building = service.getLocationById(room.buildingId);
    if (building != null) {
      final floor =
          service.getFloor(room.buildingId, room.floor) ??
          (building.floors.isNotEmpty
              ? building.floors.first
              : CampusFloor(
                  floorNumber: room.floor,
                  floorName: room.floorDisplay,
                ));

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IndoorNavigationScreen(
            building: building,
            floor: floor,
            destinationRoom: room,
          ),
        ),
      );
    } else {
      onLocateBuilding?.call(room.buildingId);
    }
  }

  void _openOutdoorNavigation(BuildContext context, CampusLocation location) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OutdoorNavigationScreen(destination: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = CampusLocationService();
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Locations')),
      body: ListenableBuilder(
        listenable: Listenable.merge([service, authService]),
        builder: (context, _) {
          // If Guest user, show login prompt
          if (authService.isGuest) {
            return EmptyStateView(
              icon: Icons.lock_outline_rounded,
              title: 'Student Bookmarks',
              description:
                  'Please login as a student to use Saved Locations.',
              actionLabel: 'Sign In as Student',
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StudentLoginScreen(),
                  ),
                );
              },
            );
          }

          final savedLocations = service.savedLocations;
          final savedRooms = service.savedRooms;
          final totalSaved = savedLocations.length + savedRooms.length;

          if (totalSaved == 0) {
            return EmptyStateView(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved locations yet',
              description:
                  'Bookmark buildings, rooms (e.g. ITP201), or labs from the Home screen for fast one-tap navigation.',
              actionLabel: 'Explore Campus',
              onActionPressed: () => onNavigateToTab?.call(0),
            );
          }

          return CustomScrollView(
            slivers: [
              if (savedRooms.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Saved Rooms & Labs',
                    count: savedRooms.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final room = savedRooms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RoomCard(
                          room: room,
                          onTap: () {
                            LocationDetailSheet.show(
                              context,
                              room: room,
                              onToggleSave: () =>
                                  service.toggleRoomSaved(room.id),
                              onNavigate: () =>
                                  _openIndoorNavigation(context, room),
                            );
                          },
                          onToggleSaved: () => service.toggleRoomSaved(room.id),
                          onNavigate: () =>
                              _openIndoorNavigation(context, room),
                        ),
                      );
                    }, childCount: savedRooms.length),
                  ),
                ),
              ],
              if (savedLocations.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Saved Buildings',
                    count: savedLocations.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = savedLocations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LocationCard(
                          location: item,
                          onTap: () {
                            LocationDetailSheet.show(
                              context,
                              location: item,
                              onToggleSave: () => service.toggleSaved(item.id),
                              onNavigate: () =>
                                  _openOutdoorNavigation(context, item),
                            );
                          },
                          onToggleSaved: () => service.toggleSaved(item.id),
                          onNavigate: () =>
                              _openOutdoorNavigation(context, item),
                        ),
                      );
                    }, childCount: savedLocations.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
