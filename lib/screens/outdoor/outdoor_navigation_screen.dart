import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/campus_locations.dart';
import '../../models/campus_location.dart';
import '../../services/campus_location_service.dart';
import '../../services/location_service.dart';
import '../../services/outdoor_routing_service.dart';
import '../floor/floor_screen.dart';
import '../indoor_navigation_screen.dart';

/// Full-featured outdoor walking navigation screen supporting both:
/// 1. Building-to-Building walking navigation (from starting building entrance to destination entrance)
/// 2. GPS walking navigation (from user's live GPS coordinates to destination entrance)
class OutdoorNavigationScreen extends StatefulWidget {
  final CampusLocation destination;
  final CampusLocation? startBuilding;
  final NavigationStartType? initialStartType;
  final LatLng? initialUserLocation;

  const OutdoorNavigationScreen({
    super.key,
    required this.destination,
    this.startBuilding,
    this.initialStartType,
    this.initialUserLocation,
  });

  @override
  State<OutdoorNavigationScreen> createState() =>
      _OutdoorNavigationScreenState();
}

class _OutdoorNavigationScreenState extends State<OutdoorNavigationScreen> {
  final CampusLocationService _campusService = CampusLocationService();
  final LocationService _locationService = LocationService();
  final OutdoorRoutingService _routingService = OutdoorRoutingService();
  final MapController _mapController = MapController();

  OutdoorRouteResult? _routeResult;
  bool _isLoadingRoute = true;
  bool _isLiveTracking = false;
  bool _showAllSteps = false;

  late NavigationStartType _startType;
  CampusLocation? _selectedStartBuilding;
  late LatLng _userLatLng;
  StreamSubscription<UserLocationData>? _locationSub;

  @override
  void initState() {
    super.initState();
    final currentLoc = _locationService.currentLocation;
    _userLatLng =
        widget.initialUserLocation ??
        LatLng(currentLoc.latitude, currentLoc.longitude);

    // Determine initial navigation start type and start building
    if (widget.startBuilding != null) {
      _selectedStartBuilding = widget.startBuilding;
      _startType =
          widget.initialStartType ?? NavigationStartType.selectedBuilding;
    } else if (_campusService.currentBuilding != null &&
        _campusService.currentBuilding!.id != widget.destination.id) {
      _selectedStartBuilding = _campusService.currentBuilding;
      _startType = NavigationStartType.selectedBuilding;
    } else {
      _selectedStartBuilding = null;
      _startType = widget.initialStartType ?? NavigationStartType.currentLocation;
    }

    _calculateRoute();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationSub = _locationService.locationStream.listen((userLoc) {
      if (mounted &&
          (userLoc.status == LocationServiceStatus.active || !userLoc.isMock)) {
        final newLatLng = LatLng(userLoc.latitude, userLoc.longitude);
        setState(() {
          _userLatLng = newLatLng;
        });

        if (_isLiveTracking) {
          _mapController.move(newLatLng, _mapController.camera.zoom);
        }
      }
    });
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    final route = await _routingService.calculateWalkingRoute(
      start: _userLatLng,
      destination: widget.destination,
      startBuilding: _selectedStartBuilding,
      startType: _startType,
    );

    if (!mounted) return;

    setState(() {
      _routeResult = route;
      _isLoadingRoute = false;
    });

    // Fit map bounds to show full route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRouteBounds();
    });
  }

  void _fitRouteBounds() {
    if (_routeResult == null || _routeResult!.polylinePoints.isEmpty) return;

    final points = _routeResult!.polylinePoints;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  Future<void> _recenterOnUser() async {
    _mapController.move(_userLatLng, 18.0);
    setState(() {
      _isLiveTracking = true;
    });

    final loc = await _locationService.refreshCurrentLocation();
    if (mounted &&
        (loc.status == LocationServiceStatus.active || !loc.isMock)) {
      final newLatLng = LatLng(loc.latitude, loc.longitude);
      setState(() {
        _userLatLng = newLatLng;
      });
      _mapController.move(newLatLng, 18.0);
    }
  }

  void _zoomIn() {
    final targetZoom = (_mapController.camera.zoom + 0.75).clamp(14.0, 19.5);
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _zoomOut() {
    final targetZoom = (_mapController.camera.zoom - 0.75).clamp(14.0, 19.5);
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _switchStartOrigin(NavigationStartType newType, CampusLocation? building) {
    setState(() {
      _startType = newType;
      _selectedStartBuilding = building;
      if (building != null) {
        _campusService.setCurrentBuilding(building.id);
      }
    });
    _calculateRoute();
  }

  void _showOriginPicker() {
    final allBuildings = _campusService.allLocations
        .where((b) => b.id != widget.destination.id)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trip_origin_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Choose Starting Point',
                      style: AppTextStyles.heading3.copyWith(fontSize: 17),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Option 1: Live GPS Location
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'My Current Location (GPS)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Route begins from your active GPS coordinates',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: _startType == NavigationStartType.currentLocation
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _switchStartOrigin(NavigationStartType.currentLocation, null);
                },
              ),
              const Divider(height: 1, indent: 64),
              // Header for campus buildings
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'CAMPUS BUILDINGS (ENTRANCES)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allBuildings.length,
                  itemBuilder: (context, index) {
                    final building = allBuildings[index];
                    final isSelected =
                        _startType == NavigationStartType.selectedBuilding &&
                        _selectedStartBuilding?.id == building.id;

                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CampusLocationData.getBuildingColor(building)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CampusLocationData.getBuildingIcon(building),
                          color: CampusLocationData.getBuildingColor(building),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${building.name} (Main Entrance)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${building.shortCode} • ${building.effectiveBuildingType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _switchStartOrigin(
                          NavigationStartType.selectedBuilding,
                          building,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Calculates remaining distance to entrance
  double get _distanceToEntranceMeters {
    final startLat = (_startType == NavigationStartType.selectedBuilding &&
            _selectedStartBuilding != null)
        ? _selectedStartBuilding!.effectiveEntranceLatitude
        : _userLatLng.latitude;
    final startLng = (_startType == NavigationStartType.selectedBuilding &&
            _selectedStartBuilding != null)
        ? _selectedStartBuilding!.effectiveEntranceLongitude
        : _userLatLng.longitude;

    return LocationService.calculateStraightLineDistance(
      startLatitude: startLat,
      startLongitude: startLng,
      endLatitude: widget.destination.effectiveEntranceLatitude,
      endLongitude: widget.destination.effectiveEntranceLongitude,
    );
  }

  bool get _isNearEntrance => _distanceToEntranceMeters <= 28.0;

  void _openFloorLayout() {
    // Set destination building as current building on entrance
    _campusService.setCurrentBuilding(widget.destination.id);

    if (widget.destination.floors.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FloorScreen(building: widget.destination, initialFloorNumber: 0),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IndoorNavigationScreen(building: widget.destination),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final destLatLng = LatLng(
      destination.effectiveEntranceLatitude,
      destination.effectiveEntranceLongitude,
    );
    final buildingColor = CampusLocationData.getBuildingColor(destination);
    final buildingIcon = CampusLocationData.getBuildingIcon(destination);

    final startLatLng = (_startType == NavigationStartType.selectedBuilding &&
            _selectedStartBuilding != null)
        ? LatLng(
            _selectedStartBuilding!.effectiveEntranceLatitude,
            _selectedStartBuilding!.effectiveEntranceLongitude,
          )
        : _userLatLng;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Campus Map',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(destination.name, style: AppTextStyles.heading2),
            Text(
              '${destination.shortCode} • ${destination.effectiveBuildingType}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Origin-Destination Route Banner (Shows starting building entrance vs GPS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showOriginPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _startType == NavigationStartType.selectedBuilding
                                ? Icons.domain_rounded
                                : Icons.my_location_rounded,
                            size: 16,
                            color: _startType ==
                                    NavigationStartType.selectedBuilding
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'STARTING POINT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _startType ==
                                              NavigationStartType
                                                  .selectedBuilding &&
                                          _selectedStartBuilding != null
                                      ? '${_selectedStartBuilding!.name} Entrance'
                                      : 'My Current Location (GPS)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          buildingIcon,
                          size: 16,
                          color: buildingColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESTINATION',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '${destination.name} Entrance',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Map Canvas Section with Controls
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      (destLatLng.latitude + startLatLng.latitude) / 2,
                      (destLatLng.longitude + startLatLng.longitude) / 2,
                    ),
                    initialZoom: 17.2,
                    minZoom: 14.0,
                    maxZoom: 19.5,
                    onPositionChanged: (cam, hasGesture) {
                      if (hasGesture && _isLiveTracking) {
                        setState(() {
                          _isLiveTracking = false;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.smart_campus_navigation',
                    ),

                    // Walking Route Polyline
                    if (_routeResult != null &&
                        _routeResult!.polylinePoints.isNotEmpty) ...[
                      // Outer polyline border
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeResult!.polylinePoints,
                            strokeWidth: 7.0,
                            color: _routeResult!.isFallback
                                ? Colors.amber.shade800.withValues(alpha: 0.35)
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      // Inner vibrant walking line
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeResult!.polylinePoints,
                            strokeWidth: 4.5,
                            color: _routeResult!.isFallback
                                ? AppColors.warning
                                : AppColors.primary,
                            pattern: _routeResult!.isFallback
                                ? StrokePattern.dashed(segments: const [9, 6])
                                : const StrokePattern.solid(),
                          ),
                        ],
                      ),
                    ],

                    // Map Markers
                    MarkerLayer(
                      markers: [
                        // 1. Destination Building Entrance Marker
                        Marker(
                          point: destLatLng,
                          width: 120,
                          height: 78,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: buildingColor,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  destination.name,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: buildingColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: buildingColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  buildingIcon,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Starting Building Entrance Marker (If building-to-building)
                        if (_startType == NavigationStartType.selectedBuilding &&
                            _selectedStartBuilding != null)
                          Marker(
                            point: LatLng(
                              _selectedStartBuilding!.effectiveEntranceLatitude,
                              _selectedStartBuilding!.effectiveEntranceLongitude,
                            ),
                            width: 120,
                            height: 78,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_selectedStartBuilding!.shortCode} Start',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF16A34A).withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 3. Current GPS User Marker
                        Marker(
                          point: _userLatLng,
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_walk_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // Fallback Route Banner (If live OSRM is offline)
                if (_routeResult != null && _routeResult!.isFallback)
                  Positioned(
                    top: 10,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Direct preview. Walking route calculated between defined entrance points.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Floating Map Controls (Fit Route, Recenter, Zoom In/Out)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavMapButton(
                        icon: Icons.alt_route_rounded,
                        tooltip: 'Fit Route',
                        onTap: _fitRouteBounds,
                      ),
                      const SizedBox(height: 8),
                      _NavMapButton(
                        icon: _isLiveTracking
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        tooltip: 'My Location',
                        iconColor: _isLiveTracking
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        onTap: _recenterOnUser,
                      ),
                      const SizedBox(height: 8),
                      _NavMapButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 8),
                      _NavMapButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Navigation Control Card
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag indicator handle
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
                const SizedBox(height: 12),

                // Arrived Proximity Highlight Banner
                if (_isNearEntrance) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF15803D),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You have arrived at ${destination.name}!',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: const Color(0xFF166534),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Tap "View Floor Layout" to explore rooms and navigate indoors.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF14532D),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Route Metrics Header (Distance & Walk Time)
                if (_isLoadingRoute) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Calculating walking route...',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ] else if (_routeResult != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_walk_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _routeResult!.distanceDisplay,
                                style: AppTextStyles.heading2.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                _routeResult!.durationDisplay,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Toggle Steps List Button
                      if (_routeResult!.steps.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllSteps = !_showAllSteps;
                            });
                          },
                          icon: Icon(
                            _showAllSteps
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.format_list_bulleted_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _showAllSteps
                                ? 'Hide Steps'
                                : 'Steps (${_routeResult!.steps.length})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Active Step Maneuver Banner
                  if (_routeResult!.steps.isNotEmpty && !_showAllSteps)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _routeResult!.steps.first.icon,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _routeResult!.steps.first.instruction,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${_routeResult!.steps.first.distanceMeters}m',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Expandable Step-by-Step Directions List
                  if (_showAllSteps) ...[
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _routeResult!.steps.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final step = _routeResult!.steps[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  step.icon,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    step.instruction,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (step.distanceMeters > 0)
                                  Text(
                                    '${step.distanceMeters}m',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 14),

                // Action Buttons: "View Floor Layout" / "Enter Building"
                Row(
                  children: [
                    // Origin change / Switch Start
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _showOriginPicker,
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                        ),
                        label: const Text('Change Start'),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // "View Floor Layout" / "Enter Building"
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: _openFloorLayout,
                        icon: const Icon(Icons.domain_rounded, size: 18),
                        label: Text(
                          destination.floors.length > 1
                              ? 'View Floor Layout'
                              : 'Enter Building',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buildingColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavMapButton({
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
        borderRadius: BorderRadius.circular(10),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
