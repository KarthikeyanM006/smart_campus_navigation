import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../models/class_mapping.dart';
import '../../models/location_category.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/campus_location_service.dart';
import '../../widgets/campus_search_bar.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/class_mapping_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/location_card.dart';
import '../../widgets/location_detail_sheet.dart';
import '../../widgets/quick_access_card.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/student_login_screen.dart';
import '../auth/welcome_screen.dart';
import '../floor/floor_screen.dart';
import '../navigation/indoor_navigation_screen.dart';

/// Home Screen for Smart Campus Navigation.
/// Supports search for Class Mappings (e.g. CSE-A), Rooms/Labs (e.g. ITP201),
/// Buildings, and role-aware bookmarking.
class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<String>? onLocateBuilding;

  const HomeScreen({super.key, this.onNavigateToTab, this.onLocateBuilding});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CampusLocationService _service = CampusLocationService();
  final AuthService _authService = AuthService();

  // The 4 key quick-access location IDs
  static const List<String> _quickAccessIds = [
    'loc_it_park',
    'loc_library',
    'loc_food_court',
    'loc_bus_stop',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = _service.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CampusLocation> _getQuickAccessLocations() {
    return _quickAccessIds
        .map((id) => _service.getLocationById(id))
        .whereType<CampusLocation>()
        .toList();
  }

  void _onToggleLocationBookmark(String locationId) {
    final success = _service.toggleSaved(locationId);
    if (!success) {
      _showGuestBookmarkPrompt();
    }
  }

  void _onToggleRoomBookmark(String roomId) {
    final success = _service.toggleRoomSaved(roomId);
    if (!success) {
      _showGuestBookmarkPrompt();
    }
  }

  void _showGuestBookmarkPrompt() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please log in as a student to use bookmarks.'),
        action: SnackBarAction(
          label: 'Log In',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StudentLoginScreen()),
            );
          },
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openFloorScreen(
    CampusLocation building,
    int floorNumber, [
    String? selectedRoomId,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FloorScreen(
          building: building,
          initialFloorNumber: floorNumber,
          initialSelectedRoomId: selectedRoomId,
          onNavigateToBuilding: widget.onLocateBuilding,
        ),
      ),
    );
  }

  void _openIndoorNavigation(CampusRoom room) {
    final building = _service.getLocationById(room.buildingId);
    if (building != null) {
      final floor =
          _service.getFloor(room.buildingId, room.floor) ??
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
      widget.onLocateBuilding?.call(room.buildingId);
    }
  }

  void _handleClassMappingNavigation(ClassMapping mapping, {bool indoor = false}) {
    final building = _service.getLocationById(mapping.buildingId);
    if (building == null) return;

    if (indoor) {
      final room = _service.getRoomById(mapping.roomId) ??
          _service.getRoomByCode(mapping.roomNumber) ??
          CampusRoom(
            id: mapping.roomId,
            roomCode: mapping.roomNumber,
            name: mapping.roomName,
            buildingId: mapping.buildingId,
            buildingName: mapping.buildingName,
            floor: mapping.floor,
            category: LocationCategory.academic,
            description: mapping.description,
            operatingHours: '08:00 AM - 05:00 PM',
          );
      _openIndoorNavigation(room);
    } else {
      widget.onLocateBuilding?.call(mapping.buildingId);
    }
  }

  void _showRoomDetails(BuildContext context, CampusRoom room) {
    if (room.buildingId == 'loc_it_park') {
      final building = _service.getLocationById(room.buildingId);
      if (building != null) {
        _openFloorScreen(building, room.floor, room.roomCode);
        return;
      }
    }
    LocationDetailSheet.show(
      context,
      room: room,
      onToggleSave: () => _onToggleRoomBookmark(room.id),
      onNavigate: () => _openIndoorNavigation(room),
    );
  }

  void _showLocationDetails(BuildContext context, CampusLocation location) {
    LocationDetailSheet.show(
      context,
      location: location,
      onSelectFloor: (floorNumber) => _openFloorScreen(location, floorNumber),
      onToggleSave: () => _onToggleLocationBookmark(location.id),
      onNavigate: () => widget.onLocateBuilding?.call(location.id),
    );
  }

  void _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickAccessSpots = _getQuickAccessLocations();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_service, _authService]),
          builder: (context, _) {
            final locations = _service.filteredLocations;
            final rooms = _service.filteredRooms;
            final classMappings = _service.filteredClassMappings;
            final isSearching = _service.searchQuery.trim().isNotEmpty;
            final totalSearchResults = locations.length + rooms.length + classMappings.length;
            final user = _authService.currentUser;
            final role = _authService.currentRole;

            return CustomScrollView(
              slivers: [
                // 1. Header Branding & User Role Badge
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SMART CAMPUS',
                              style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            // User Role Indicator / Account Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: role.badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: role.badgeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(role.icon, size: 14, color: role.badgeColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    role == UserRole.guest
                                        ? 'Guest'
                                        : (role == UserRole.student
                                            ? 'Student: ${user?.name.split(" ").first ?? "Alex"}'
                                            : 'Admin'),
                                    style: TextStyle(
                                      color: role.badgeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (role == UserRole.guest)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const WelcomeScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        '• Sign In',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: _handleLogout,
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Find places around campus',
                                style: AppTextStyles.heading1,
                              ),
                            ),
                            if (role == UserRole.admin)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AdminDashboardScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.dashboard_rounded, size: 14),
                                label: const Text('Dashboard', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search classes (e.g. CSE-A), rooms (ITP201), buildings, or facilities.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Prominent Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: CampusSearchBar(
                      controller: _searchController,
                      hintText: 'Search classes (e.g. CSE-A), rooms (ITP201), buildings...',
                      onChanged: (val) => _service.setSearchQuery(val),
                      onClear: () => _service.clearSearch(),
                    ),
                  ),
                ),

                // 3. Quick Access Section (Shown when not searching)
                if (!isSearching && _service.selectedCategory == LocationCategory.all) ...[
                  const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Quick Access'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.3,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final loc = quickAccessSpots[index];
                        return QuickAccessCard(
                          location: loc,
                          onTap: () => _showLocationDetails(context, loc),
                        );
                      }, childCount: quickAccessSpots.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],

                // 4. Category Filter Chips (Shown when not searching)
                if (!isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CategoryFilterChips(
                        selectedCategory: _service.selectedCategory,
                        onSelected: (cat) => _service.setCategory(cat),
                      ),
                    ),
                  ),

                // 5. If searching, show Class Mappings (e.g. CSE-A)
                if (isSearching && classMappings.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Class Allocations',
                      count: classMappings.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final map = classMappings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ClassMappingCard(
                            mapping: map,
                            onTap: () => _handleClassMappingNavigation(map, indoor: true),
                            onGetDirections: () => _handleClassMappingNavigation(map, indoor: false),
                            onNavigateIndoor: () => _handleClassMappingNavigation(map, indoor: true),
                          ),
                        );
                      }, childCount: classMappings.length),
                    ),
                  ),
                ],

                // 6. If searching and rooms match, show Rooms & Labs results
                if (isSearching && rooms.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Rooms & Labs',
                      count: rooms.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final room = rooms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RoomCard(
                            room: room,
                            onTap: () => _showRoomDetails(context, room),
                            onToggleSaved: () => _onToggleRoomBookmark(room.id),
                            onNavigate: () => _openIndoorNavigation(room),
                          ),
                        );
                      }, childCount: rooms.length),
                    ),
                  ),
                ],

                // 7. Section Header for Buildings & Facilities
                if (!isSearching || locations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: isSearching
                          ? 'Buildings & Facilities'
                          : (_service.selectedCategory == LocationCategory.all
                              ? 'Campus Locations'
                              : '${_service.selectedCategory.displayName} Locations'),
                      count: locations.length,
                      actionLabel: isSearching ? 'Reset' : null,
                      onActionTap: isSearching
                          ? () {
                              _searchController.clear();
                              _service.clearSearch();
                            }
                          : null,
                    ),
                  ),

                // 8. Campus Locations List or Empty State
                if (isSearching && totalSearchResults == 0)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No locations found',
                      description:
                          'No campus class, room, lab, or building matched "${_service.searchQuery}".',
                      actionLabel: 'Clear Search',
                      onActionPressed: () {
                        _searchController.clear();
                        _service.clearSearch();
                      },
                    ),
                  )
                else if (locations.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = locations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LocationCard(
                            location: item,
                            onTap: () => _showLocationDetails(context, item),
                            onToggleSaved: () => _onToggleLocationBookmark(item.id),
                            onNavigate: () => widget.onLocateBuilding?.call(item.id),
                          ),
                        );
                      }, childCount: locations.length),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}
