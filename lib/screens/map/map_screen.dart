import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/campus_locations.dart';
import '../../models/campus_location.dart';
import '../../models/campus_map_models.dart';
import '../../services/campus_location_service.dart';
import '../../services/location_service.dart';
import '../../widgets/campus_search_bar.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/location_detail_sheet.dart';
import '../floor/floor_screen.dart';
import '../outdoor_navigation_screen.dart';
import '../auth/student_login_screen.dart';

/// Interactive OpenStreetMap-based Campus Map screen showing all 11 real college buildings,
/// GPS user positioning, marker tooltips, zoom/recenter controls, and search filtering.
class MapScreen extends StatefulWidget {
  final String? initialSelectedLocationId;

  const MapScreen({super.key, this.initialSelectedLocationId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final CampusLocationService _service = CampusLocationService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  String? _selectedLocationId;
  OutdoorRoute? _activeOutdoorRoute;

  static const LatLng _campusCenter = CampusLocationData.campusCenter;
  static const double _defaultZoom = CampusLocationData.defaultZoom;

  @override
  void initState() {
    super.initState();
    _selectedLocationId =
        widget.initialSelectedLocationId ??
        _service.allLocations.firstOrNull?.id;

    // Start location stream if permitted
    _locationService.startLocationStream();

    // If an initial location was requested, animate to it after map builds
    if (widget.initialSelectedLocationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = _service.getLocationById(widget.initialSelectedLocationId!);
        if (loc != null) {
          _moveToLocation(loc);
        }
      });
    }
  }

  @override
  void dispose() {
    _locationService.stopLocationStream();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectLocation(CampusLocation location) {
    setState(() {
      _selectedLocationId = location.id;
      _activeOutdoorRoute = null; // Clear previous outdoor route
    });
    _moveToLocation(location);
  }

  void _moveToLocation(CampusLocation location) {
    _mapController.move(LatLng(location.latitude, location.longitude), 17.5);
  }

  void _recenterToCampus() {
    _mapController.move(_campusCenter, _defaultZoom);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = (currentZoom + 0.75).clamp(14.0, 19.0);
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = (currentZoom - 0.75).clamp(14.0, 19.0);
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  Future<void> _handleMyLocationTap() async {
    if (_locationService.isRequestingLocation) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(LocationService.msgFindingLocation),
          ],
        ),
        duration: Duration(seconds: 25),
        backgroundColor: AppColors.primary,
      ),
    );

    final locationData = await _locationService.refreshCurrentLocation();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (locationData.status == LocationServiceStatus.active) {
      _mapController.move(
        LatLng(locationData.latitude, locationData.longitude),
        17.8,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS Location: ${locationData.latitude.toStringAsFixed(5)}, ${locationData.longitude.toStringAsFixed(5)} (±${locationData.accuracy.round()}m)',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (locationData.status == LocationServiceStatus.serviceDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(LocationService.msgTurnOnLocation),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => _locationService.openLocationSettings(),
          ),
        ),
      );
    } else if (locationData.status == LocationServiceStatus.permissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(LocationService.msgPermissionRequired),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Grant',
            textColor: Colors.white,
            onPressed: () => _locationService.requestLocationPermission(),
          ),
        ),
      );
    } else if (locationData.status ==
        LocationServiceStatus.permissionDeniedPermanently) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(LocationService.msgPermissionPermanentlyDenied),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.danger,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => _locationService.openAppSettings(),
          ),
        ),
      );
    } else if (locationData.status == LocationServiceStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationData.statusMessage ??
                LocationService.msgLocationUnavailable,
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      // Fallback mock
      _mapController.move(
        LatLng(locationData.latitude, locationData.longitude),
        17.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationData.statusMessage ?? 'Development location centered',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _toggleBookmark(String locationId) {
    final success = _service.toggleSaved(locationId);
    if (!success) {
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
    } else {
      setState(() {});
    }
  }

  void _showLocationDetails(CampusLocation location) {
    LocationDetailSheet.show(
      context,
      location: location,
      onSelectFloor: (floorNum) {
        _openFloorScreen(location, floorNum);
      },
      onToggleSave: () => _toggleBookmark(location.id),
      onNavigate: () {
        _startOutdoorNavigation(location);
      },
    );
  }

  void _startOutdoorNavigation(CampusLocation location) {
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() {
      _selectedLocationId = location.id;
    });

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OutdoorNavigationScreen(destination: location),
      ),
    );
  }

  void _openFloorScreen(CampusLocation building, int floorNumber) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FloorScreen(building: building, initialFloorNumber: floorNumber),
      ),
    );
  }

  List<Marker> _buildMarkers(
    List<CampusLocation> locations,
    CampusLocation? selectedLocation,
    UserLocationData userLoc,
  ) {
    final markers = <Marker>[];

    // 1. Building Markers
    for (final loc in locations) {
      final isSelected = selectedLocation?.id == loc.id;
      final color = CampusLocationData.getBuildingColor(loc);
      final icon = CampusLocationData.getBuildingIcon(loc);

      markers.add(
        Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: isSelected ? 120 : 90,
          height: isSelected ? 72 : 54,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectLocation(loc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Building short code badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    loc.shortCode,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: isSelected ? 11 : 9.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),

                // Marker Pin Icon
                Container(
                  width: isSelected ? 34 : 28,
                  height: isSelected ? 34 : 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 2.5 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: isSelected ? 8 : 4,
                        spreadRadius: isSelected ? 2 : 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isSelected ? 18 : 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. User GPS Location Marker (if active or available)
    if (userLoc.status == LocationServiceStatus.active || !userLoc.isMock) {
      markers.add(
        Marker(
          point: LatLng(userLoc.latitude, userLoc.longitude),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.my_location_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Map'),
        actions: [
          IconButton(
            icon: _locationService.isRequestingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 20),
            tooltip: 'My Location',
            onPressed: _locationService.isRequestingLocation
                ? null
                : _handleMyLocationTap,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_service, _locationService]),
        builder: (context, _) {
          final locations = _service.filteredLocations;
          final selectedLocation = _service.getLocationById(
            _selectedLocationId ?? _service.allLocations.first.id,
          );
          final userLoc = _locationService.currentLocation;

          OutdoorRoute? previewRoute;
          if (selectedLocation != null) {
            previewRoute = _service.calculateOutdoorRoute(selectedLocation);
          }

          return Column(
            children: [
              // 1. Map Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: CampusSearchBar(
                  controller: _searchController,
                  hintText: 'Search building name, code (e.g. EEE, ITP)...',
                  onChanged: (val) {
                    _service.setSearchQuery(val);
                    if (locations.isNotEmpty) {
                      _selectedLocationId = locations.first.id;
                      _moveToLocation(locations.first);
                    }
                  },
                  onClear: () {
                    _service.clearSearch();
                  },
                ),
              ),

              // 2. Category Filter Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CategoryFilterChips(
                  selectedCategory: _service.selectedCategory,
                  onSelected: (cat) => _service.setCategory(cat),
                ),
              ),

              // 3. Interactive OpenStreetMap Container with Zoom & Recenter Controls
              Expanded(
                child: Container(
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
                        // FlutterMap OSM Layer
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _campusCenter,
                            initialZoom: _defaultZoom,
                            minZoom: 14.0,
                            maxZoom: 19.0,
                            onTap: (tapPosition, point) {},
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.smart_campus_navigation',
                            ),
                            if (_activeOutdoorRoute != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      LatLng(
                                        userLoc.latitude,
                                        userLoc.longitude,
                                      ),
                                      LatLng(
                                        _activeOutdoorRoute!
                                            .destination
                                            .latitude,
                                        _activeOutdoorRoute!
                                            .destination
                                            .longitude,
                                      ),
                                    ],
                                    strokeWidth: 4.0,
                                    color: AppColors.primary,
                                    pattern: StrokePattern.dashed(
                                      segments: const [8, 5],
                                    ),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: _buildMarkers(
                                locations,
                                selectedLocation,
                                userLoc,
                              ),
                            ),
                            const RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  '© OpenStreetMap contributors',
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Map Control Floating Tools (+, -, Center Recenter, My Location)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MapToolButton(
                                icon: Icons.add_rounded,
                                tooltip: 'Zoom In',
                                onTap: _zoomIn,
                              ),
                              const SizedBox(height: 6),
                              _MapToolButton(
                                icon: Icons.remove_rounded,
                                tooltip: 'Zoom Out',
                                onTap: _zoomOut,
                              ),
                              const SizedBox(height: 6),
                              _MapToolButton(
                                icon: Icons.center_focus_strong_rounded,
                                tooltip: 'Campus Center',
                                onTap: _recenterToCampus,
                              ),
                              const SizedBox(height: 6),
                              _MapToolButton(
                                icon: _locationService.isRequestingLocation
                                    ? Icons.location_searching_rounded
                                    : Icons.my_location_rounded,
                                tooltip: 'My Location',
                                iconColor:
                                    userLoc.status ==
                                        LocationServiceStatus.active
                                    ? AppColors.primary
                                    : null,
                                onTap: _handleMyLocationTap,
                              ),
                            ],
                          ),
                        ),

                        // GPS / Location Status Badge
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        userLoc.status ==
                                            LocationServiceStatus.active
                                        ? AppColors.success
                                        : AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  userLoc.status == LocationServiceStatus.active
                                      ? 'GPS Active'
                                      : 'Campus Map',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. Selected Location Compact Preview Bottom Card
              if (selectedLocation != null && previewRoute != null)
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
                              color: CampusLocationData.getBuildingColor(
                                selectedLocation,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedLocation.shortCode,
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
                                  selectedLocation.name,
                                  style: AppTextStyles.heading3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedLocation.category.displayName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _service.isLocationBookmarked(selectedLocation.id)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _service.isLocationBookmarked(selectedLocation.id)
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            onPressed: () =>
                                _toggleBookmark(selectedLocation.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedLocation.description,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Distance & Walk Time Metrics
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.straighten_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '~${previewRoute.distanceMeters}m straight-line',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '~${previewRoute.estimatedMinutes} min walk',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showLocationDetails(selectedLocation),
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
                              label: const Text('View Details'),
                            ),
                          ),
                          if (selectedLocation.hasIndoorMap) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openFloorScreen(selectedLocation, 0),
                                icon: const Icon(
                                  Icons.layers_outlined,
                                  size: 16,
                                ),
                                label: const Text('Floor Map'),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startOutdoorNavigation(selectedLocation),
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
          );
        },
      ),
    );
  }
}

class _MapToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MapToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
