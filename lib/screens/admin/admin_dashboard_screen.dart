import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/campus_locations.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../models/class_mapping.dart';
import '../../models/location_category.dart';
import '../../services/auth_service.dart';
import '../../services/campus_location_service.dart';
import '../auth/welcome_screen.dart';

/// Comprehensive Administrator Management Portal for Smart Campus Navigation.
/// Allows live management of Class Allocations, Buildings, Floor Layouts, and Rooms.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final CampusLocationService _locationService = CampusLocationService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    // Role Guard Check
    if (!_authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text('Unauthorized Access', style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                const Text(
                  'You must be logged in as an Administrator to view and edit campus data.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Return to Welcome Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(
                  'Live Campus Management',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out Admin',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: 'Class Mappings'),
            Tab(icon: Icon(Icons.business_rounded, size: 18), text: 'Buildings'),
            Tab(icon: Icon(Icons.layers_rounded, size: 18), text: 'Floors & Rooms'),
            Tab(icon: Icon(Icons.room_preferences_rounded, size: 18), text: 'Facilities'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _locationService,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _ClassMappingsTab(service: _locationService),
              _BuildingsTab(service: _locationService),
              _FloorsAndRoomsTab(service: _locationService),
              _FacilitiesTab(service: _locationService),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// TAB 1: DYNAMIC CLASSROOM MAPPINGS
// ============================================================================
class _ClassMappingsTab extends StatelessWidget {
  final CampusLocationService service;

  const _ClassMappingsTab({required this.service});

  void _openMappingEditor(BuildContext context, [ClassMapping? existing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ClassMappingEditorSheet(
        service: service,
        existingMapping: existing,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassMapping mapping) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mapping'),
        content: Text('Are you sure you want to remove the classroom mapping for "${mapping.className}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              service.deleteClassMapping(mapping.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted mapping for ${mapping.className}')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mappings = service.allClassMappings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: () => _openMappingEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Map Class to Room', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Informational Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF7C3AED), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dynamic Classroom Allocations',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Map classes (e.g. CSE-A) to physical rooms. Students and guests searching for a class will immediately be directed to the updated room.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF6D28D9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Class Mappings (${mappings.length})',
                style: AppTextStyles.heading3,
              ),
              Text(
                'Tap to edit allocation',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (mappings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No classroom mappings created yet. Tap "+ Map Class" below.'),
            )
          else
            ...mappings.map((mapping) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openMappingEditor(context, mapping),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mapping.className,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  mapping.department,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                                onPressed: () => _openMappingEditor(context, mapping),
                                tooltip: 'Edit Mapping',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                onPressed: () => _confirmDelete(context, mapping),
                                tooltip: 'Delete Mapping',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                                    children: [
                                      TextSpan(
                                        text: mapping.buildingName,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const TextSpan(text: '  ›  '),
                                      TextSpan(text: mapping.floorDisplay),
                                      const TextSpan(text: '  ›  '),
                                      TextSpan(
                                        text: 'Room ${mapping.roomNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (mapping.roomName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              mapping.roomName,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Dynamic Class Mapping Editor Modal (Workflow: Department -> Class -> Building -> Floor -> Room -> Save)
class _ClassMappingEditorSheet extends StatefulWidget {
  final CampusLocationService service;
  final ClassMapping? existingMapping;

  const _ClassMappingEditorSheet({
    required this.service,
    this.existingMapping,
  });

  @override
  State<_ClassMappingEditorSheet> createState() => _ClassMappingEditorSheetState();
}

class _ClassMappingEditorSheetState extends State<_ClassMappingEditorSheet> {
  late String _selectedDept;
  late TextEditingController _classController;
  late TextEditingController _descController;

  CampusLocation? _selectedBuilding;
  int _selectedFloorNumber = 0;
  CampusRoom? _selectedRoom;
  late TextEditingController _roomNumberCustomController;
  late TextEditingController _roomNameCustomController;

  final List<String> _departments = [
    'CSE',
    'IT',
    'AI & DS',
    'ECE',
    'EEE',
    'EIE',
    'S&H',
    'MBA',
    'Chemical',
    'Food Tech',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMapping;

    _selectedDept = existing?.department ?? 'CSE';
    _classController = TextEditingController(text: existing?.className ?? 'CSE-A');
    _descController = TextEditingController(text: existing?.description ?? '');

    // Initialize building
    final buildings = widget.service.allLocations;
    if (existing != null) {
      _selectedBuilding = widget.service.getLocationById(existing.buildingId) ?? buildings.firstOrNull;
      _selectedFloorNumber = existing.floor;
    } else {
      _selectedBuilding = buildings.firstWhere(
        (b) => b.id == 'loc_it_park',
        orElse: () => buildings.first,
      );
      _selectedFloorNumber = 1;
    }

    // Initialize room controllers
    _roomNumberCustomController = TextEditingController(text: existing?.roomNumber ?? 'ITP001');
    _roomNameCustomController = TextEditingController(text: existing?.roomName ?? 'Classroom');

    _syncSelectedRoom();
  }

  void _syncSelectedRoom() {
    if (_selectedBuilding == null) return;
    final floors = _selectedBuilding!.floors;
    final currentFloor = floors.firstWhere(
      (f) => f.floorNumber == _selectedFloorNumber,
      orElse: () => floors.isNotEmpty ? floors.first : const CampusFloor(floorNumber: 0, floorName: 'Ground'),
    );

    if (currentFloor.rooms.isNotEmpty) {
      _selectedRoom = currentFloor.rooms.firstWhere(
        (r) => r.roomCode.toUpperCase() == _roomNumberCustomController.text.toUpperCase(),
        orElse: () => currentFloor.rooms.first,
      );
      _roomNumberCustomController.text = _selectedRoom!.roomCode;
      _roomNameCustomController.text = _selectedRoom!.name;
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _descController.dispose();
    _roomNumberCustomController.dispose();
    _roomNameCustomController.dispose();
    super.dispose();
  }

  void _saveMapping() {
    final className = _classController.text.trim().toUpperCase();
    if (className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Class/Section name (e.g. CSE-A)')),
      );
      return;
    }

    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a building')),
      );
      return;
    }

    final roomNumber = _roomNumberCustomController.text.trim().toUpperCase();
    final roomName = _roomNameCustomController.text.trim();

    final mapping = ClassMapping(
      id: widget.existingMapping?.id ?? 'map_${className.replaceAll('-', '_').toLowerCase()}',
      department: _selectedDept,
      className: className,
      buildingId: _selectedBuilding!.id,
      buildingName: _selectedBuilding!.name,
      floor: _selectedFloorNumber,
      roomId: _selectedRoom?.id ?? 'room_${_selectedBuilding!.id}_${roomNumber.toLowerCase()}',
      roomNumber: roomNumber.isNotEmpty ? roomNumber : '001',
      roomName: roomName.isNotEmpty ? roomName : '$className Classroom',
      description: _descController.text.trim(),
      latitude: _selectedBuilding!.latitude,
      longitude: _selectedBuilding!.longitude,
    );

    widget.service.saveClassMapping(mapping);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mapping updated: $className → ${_selectedBuilding!.name} (Room $roomNumber)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildings = widget.service.allLocations;
    final availableFloors = _selectedBuilding?.floors ?? [];
    final currentFloor = availableFloors.firstWhere(
      (f) => f.floorNumber == _selectedFloorNumber,
      orElse: () => availableFloors.isNotEmpty
          ? availableFloors.first
          : CampusFloor(floorNumber: _selectedFloorNumber, floorName: 'Floor $_selectedFloorNumber'),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.existingMapping != null ? 'Edit Classroom Mapping' : 'New Classroom Mapping',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 4),
            Text(
              'Follow the workflow: Department › Class › Building › Floor › Room',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // 1. SELECT DEPARTMENT
            const Text('1. Select Department', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _departments.contains(_selectedDept) ? _selectedDept : _departments.first,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDept = val);
              },
            ),
            const SizedBox(height: 14),

            // 2. ENTER CLASS / SECTION
            const Text('2. Class / Section Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _classController,
              decoration: const InputDecoration(
                hintText: 'e.g. CSE-A, CSE-B, IT-A, ECE-C',
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // 3. SELECT BUILDING
            const Text('3. Select Target Building', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<CampusLocation>(
              initialValue: _selectedBuilding,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.business_outlined)),
              items: buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBuilding = val;
                    if (val.floors.isNotEmpty) {
                      _selectedFloorNumber = val.floors.first.floorNumber;
                    } else {
                      _selectedFloorNumber = 0;
                    }
                    _syncSelectedRoom();
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // 4. SELECT FLOOR
            const Text('4. Select Floor Level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            if (availableFloors.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: availableFloors.any((f) => f.floorNumber == _selectedFloorNumber)
                    ? _selectedFloorNumber
                    : availableFloors.first.floorNumber,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.layers_outlined)),
                items: availableFloors
                    .map((f) => DropdownMenuItem(value: f.floorNumber, child: Text(f.floorName)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFloorNumber = val;
                      _syncSelectedRoom();
                    });
                  }
                },
              )
            else
              TextFormField(
                initialValue: 'Floor $_selectedFloorNumber',
                decoration: const InputDecoration(prefixIcon: Icon(Icons.layers_outlined)),
                enabled: false,
              ),
            const SizedBox(height: 14),

            // 5. SELECT ROOM / NUMBER
            const Text('5. Select Room / Number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            if (currentFloor.rooms.isNotEmpty) ...[
              DropdownButtonFormField<CampusRoom>(
                initialValue: currentFloor.rooms.contains(_selectedRoom) ? _selectedRoom : currentFloor.rooms.first,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.meeting_room_outlined)),
                items: currentFloor.rooms
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.roomCode} - ${r.name}', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRoom = val;
                      _roomNumberCustomController.text = val.roomCode;
                      _roomNameCustomController.text = val.name;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _roomNumberCustomController,
                    decoration: const InputDecoration(
                      labelText: 'Room Number / Code',
                      hintText: 'e.g. ITP101',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _roomNameCustomController,
                    decoration: const InputDecoration(
                      labelText: 'Room Name',
                      hintText: 'e.g. Software Systems Lab',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Allocation Description / Notes (Optional)',
                hintText: 'e.g. IV Semester Section A theory class and lecture room',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 22),

            // Save Action Button
            ElevatedButton.icon(
              onPressed: _saveMapping,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Save Classroom Allocation', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 2: BUILDINGS MANAGEMENT
// ============================================================================
class _BuildingsTab extends StatelessWidget {
  final CampusLocationService service;

  const _BuildingsTab({required this.service});

  void _openBuildingEditor(BuildContext context, [CampusLocation? building]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _BuildingEditorSheet(service: service, existing: building),
    );
  }

  void _confirmDelete(BuildContext context, CampusLocation building) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Building'),
        content: Text('Are you sure you want to remove "${building.name}" and its associated rooms from the campus directory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              service.deleteBuilding(building.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Building "${building.name}" removed.')),
              );
            },
            child: const Text('Delete Building', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildings = service.allLocations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: () => _openBuildingEditor(context),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Building', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Campus Buildings (${buildings.length})', style: AppTextStyles.heading3),
              Text('Tap to edit details', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...buildings.map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(CampusLocationData.getBuildingIcon(b), color: CampusLocationData.getBuildingColor(b)),
                ),
                title: Row(
                  children: [
                    Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(b.shortCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${b.floorCount} Floors • ${b.category.displayName} • ${b.departments.join(", ")}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GPS: ${b.latitude.toStringAsFixed(4)}, ${b.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                      onPressed: () => _openBuildingEditor(context, b),
                      tooltip: 'Edit Building',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      onPressed: () => _confirmDelete(context, b),
                      tooltip: 'Delete Building',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BuildingEditorSheet extends StatefulWidget {
  final CampusLocationService service;
  final CampusLocation? existing;

  const _BuildingEditorSheet({required this.service, this.existing});

  @override
  State<_BuildingEditorSheet> createState() => _BuildingEditorSheetState();
}

class _BuildingEditorSheetState extends State<_BuildingEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  late TextEditingController _floorsController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late LocationCategory _category;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _nameController = TextEditingController(text: b?.name ?? '');
    _codeController = TextEditingController(text: b?.shortCode ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    _floorsController = TextEditingController(text: (b?.floorCount ?? 3).toString());
    _latController = TextEditingController(text: (b?.latitude ?? 11.2735).toString());
    _lngController = TextEditingController(text: (b?.longitude ?? 77.6068).toString());
    _category = b?.category ?? LocationCategory.academic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _floorsController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _saveBuilding() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter building name and short code')),
      );
      return;
    }

    final lat = double.tryParse(_latController.text.trim()) ?? 11.2735;
    final lng = double.tryParse(_lngController.text.trim()) ?? 77.6068;
    final floorCount = int.tryParse(_floorsController.text.trim()) ?? 1;

    final building = (widget.existing ?? CampusLocation(
      id: 'loc_${code.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      shortCode: code,
      category: _category,
      description: _descController.text.trim(),
      floorCount: floorCount,
      departments: ['General'],
      operatingHours: '08:00 AM - 06:00 PM',
      latitude: lat,
      longitude: lng,
    )).copyWith(
      name: name,
      shortCode: code,
      category: _category,
      description: _descController.text.trim(),
      floorCount: floorCount,
      latitude: lat,
      longitude: lng,
    );

    if (widget.existing != null) {
      widget.service.updateBuilding(building);
    } else {
      widget.service.addBuilding(building);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Building "$name" saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.existing != null ? 'Edit Building' : 'Add Campus Building', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Building Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Short Code (e.g. ITP)')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _floorsController,
                    decoration: const InputDecoration(labelText: 'Floor Count'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LocationCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: LocationCategory.values
                  .where((c) => c != LocationCategory.all)
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Building Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBuilding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Building Information', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: FLOORS & ROOMS MANAGEMENT
// ============================================================================
class _FloorsAndRoomsTab extends StatefulWidget {
  final CampusLocationService service;

  const _FloorsAndRoomsTab({required this.service});

  @override
  State<_FloorsAndRoomsTab> createState() => _FloorsAndRoomsTabState();
}

class _FloorsAndRoomsTabState extends State<_FloorsAndRoomsTab> {
  CampusLocation? _selectedBuilding;
  int _selectedFloor = 0;

  @override
  void initState() {
    super.initState();
    final buildings = widget.service.allLocations;
    if (buildings.isNotEmpty) {
      _selectedBuilding = buildings.firstWhere((b) => b.id == 'loc_it_park', orElse: () => buildings.first);
      if (_selectedBuilding!.floors.isNotEmpty) {
        _selectedFloor = _selectedBuilding!.floors.first.floorNumber;
      }
    }
  }

  void _openRoomEditor([CampusRoom? room]) {
    if (_selectedBuilding == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _RoomEditorSheet(
        service: widget.service,
        building: _selectedBuilding!,
        floorNumber: _selectedFloor,
        existing: room,
      ),
    );
  }

  void _confirmDeleteRoom(CampusRoom room) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete room "${room.roomCode} - ${room.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              widget.service.deleteRoom(room.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Room ${room.roomCode} removed.')),
              );
            },
            child: const Text('Delete Room', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildings = widget.service.allLocations;
    if (_selectedBuilding != null) {
      // Refresh selected building reference from service
      _selectedBuilding = widget.service.getLocationById(_selectedBuilding!.id) ?? _selectedBuilding;
    }

    final floors = _selectedBuilding?.floors ?? [];
    final currentFloor = floors.firstWhere(
      (f) => f.floorNumber == _selectedFloor,
      orElse: () => floors.isNotEmpty ? floors.first : CampusFloor(floorNumber: _selectedFloor, floorName: 'Floor $_selectedFloor'),
    );

    final roomsOnFloor = widget.service.allRooms.where(
      (r) => r.buildingId == _selectedBuilding?.id && r.floor == _selectedFloor,
    ).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: () => _openRoomEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Room / Lab', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Select Building Filter
          const Text('Select Campus Building', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<CampusLocation>(
            initialValue: _selectedBuilding,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.business_outlined)),
            items: buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedBuilding = val;
                  if (val.floors.isNotEmpty) {
                    _selectedFloor = val.floors.first.floorNumber;
                  } else {
                    _selectedFloor = 0;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // Floor Selector Pills
          if (floors.isNotEmpty) ...[
            const Text('Select Floor Level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: floors.map((f) {
                  final isSel = f.floorNumber == _selectedFloor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSel,
                      label: Text(f.floorName),
                      selectedColor: const Color(0xFF7C3AED),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _selectedFloor = f.floorNumber),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rooms on ${currentFloor.floorName} (${roomsOnFloor.length})', style: AppTextStyles.heading3),
              Text('Tap to edit', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),

          if (roomsOnFloor.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No rooms registered on this floor yet. Tap "+ Add Room / Lab" below.'),
            )
          else
            ...roomsOnFloor.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.roomCode,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    '${r.effectiveRoomType} ${r.department != null ? "• ${r.department}" : ""} ${r.className != null ? "• Class: ${r.className}" : ""}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                        onPressed: () => _openRoomEditor(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        onPressed: () => _confirmDeleteRoom(r),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RoomEditorSheet extends StatefulWidget {
  final CampusLocationService service;
  final CampusLocation building;
  final int floorNumber;
  final CampusRoom? existing;

  const _RoomEditorSheet({
    required this.service,
    required this.building,
    required this.floorNumber,
    this.existing,
  });

  @override
  State<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<_RoomEditorSheet> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _deptController;
  late TextEditingController _classController;
  late TextEditingController _descController;
  late LocationCategory _category;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _codeController = TextEditingController(text: r?.roomCode ?? '');
    _nameController = TextEditingController(text: r?.name ?? '');
    _deptController = TextEditingController(text: r?.department ?? 'CSE');
    _classController = TextEditingController(text: r?.className ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _category = r?.category ?? LocationCategory.academic;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _deptController.dispose();
    _classController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveRoom() {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter room code and name')),
      );
      return;
    }

    final room = CampusRoom(
      id: widget.existing?.id ?? 'room_${widget.building.id}_${code.toLowerCase()}',
      roomCode: code,
      name: name,
      buildingId: widget.building.id,
      buildingName: widget.building.name,
      floor: widget.floorNumber,
      category: _category,
      department: _deptController.text.trim(),
      className: _classController.text.trim(),
      description: _descController.text.trim(),
      operatingHours: '08:00 AM - 06:00 PM',
      tags: [code, name, _deptController.text.trim()],
    );

    widget.service.saveRoom(room);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room $code ($name) saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.existing != null ? 'Edit Room' : 'Add Room to ${widget.building.name} (Floor ${widget.floorNumber})',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Room Code (e.g. ITP101)')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Room Name')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _deptController, decoration: const InputDecoration(labelText: 'Department (e.g. CSE)')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(controller: _classController, decoration: const InputDecoration(labelText: 'Class Section (e.g. CSE-A)')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LocationCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: LocationCategory.values
                  .where((c) => c != LocationCategory.all)
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Room Description'), maxLines: 2),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Room Information', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 4: FACILITIES TAB
// ============================================================================
class _FacilitiesTab extends StatelessWidget {
  final CampusLocationService service;

  const _FacilitiesTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final facilities = service.allLocations.where(
      (l) => l.category == LocationCategory.amenities ||
             l.category == LocationCategory.transit ||
             l.category == LocationCategory.library ||
             l.category == LocationCategory.administrative,
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Key Campus Facilities & Public Amenities', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Manage public spots like Food Court, Library, Bus Stops, Auditoriums, and Admin Block.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        ...facilities.map((fac) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: Icon(CampusLocationData.getBuildingIcon(fac), color: CampusLocationData.getBuildingColor(fac), size: 28),
              title: Text(fac.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${fac.category.displayName} • Hours: ${fac.operatingHours}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Chip(
                label: Text(fac.shortCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                backgroundColor: AppColors.surfaceVariant,
              ),
            ),
          );
        }),
      ],
    );
  }
}
