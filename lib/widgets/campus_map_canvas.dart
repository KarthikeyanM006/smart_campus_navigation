import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_location.dart';
import '../models/campus_map_models.dart';
import '../services/location_service.dart';

/// Interactive 2D schematic campus map canvas rendering buildings, roads, real GPS user location, and active routes.
class CampusMapCanvas extends StatelessWidget {
  final List<CampusLocation> locations;
  final String? selectedLocationId;
  final UserLocationData userLocation;
  final OutdoorRoute? activeOutdoorRoute;
  final ValueChanged<CampusLocation> onSelectLocation;

  const CampusMapCanvas({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.userLocation,
    required this.onSelectLocation,
    this.activeOutdoorRoute,
  });

  /// Helper to safely clamp a value within [min, max], ensuring min <= max.
  static double _safeClamp(double value, double min, double max) {
    if (min >= max) return min;
    return value.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Safe dimension evaluation that gracefully handles mobile, desktop, and transient zero sizes
        final double width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
        final double height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 400.0;

        // Responsive element sizing
        const double padding = 6.0;
        final double markerWidth = math.min(
          124.0,
          math.max(70.0, width * 0.34),
        );
        const double markerHeight = 54.0;

        final double maxMarkerLeft = math.max(
          padding,
          width - markerWidth - padding,
        );
        final double maxMarkerTop = math.max(
          padding,
          height - markerHeight - padding,
        );

        // User location marker metrics
        final double userMarkerWidth = math.min(
          115.0,
          math.max(60.0, width * 0.32),
        );
        const double userMarkerHeight = 28.0;
        final double maxUserLeft = math.max(
          padding,
          width - userMarkerWidth - padding,
        );
        final double maxUserTop = math.max(
          padding,
          height - userMarkerHeight - padding,
        );

        final double userLeft = _safeClamp(
          (userLocation.mapX * width) - (userMarkerWidth / 2),
          padding,
          maxUserLeft,
        );
        final double userTop = _safeClamp(
          (userLocation.mapY * height) - (userMarkerHeight / 2),
          padding,
          maxUserTop,
        );

        return Stack(
          children: [
            // 1. Blueprint Grid Background
            const Positioned.fill(
              child: CustomPaint(painter: _CampusGridPainter()),
            ),

            // 2. Campus Pathways and Road Network
            Positioned.fill(child: CustomPaint(painter: _CampusRoadsPainter())),

            // 3. Outdoor Route Polyline (if active)
            if (activeOutdoorRoute != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _OutdoorRoutePainter(route: activeOutdoorRoute!),
                ),
              ),

            // 4. "You Are Here" Current Location Marker
            Positioned(
              left: userLeft,
              top: userTop,
              child: _UserLocationMarker(
                isRealGps:
                    !userLocation.isMock &&
                    userLocation.status == LocationServiceStatus.active,
                accuracy: userLocation.accuracy,
              ),
            ),

            // 5. Interactive Building Markers
            ...locations.map((loc) {
              final isSelected = loc.id == selectedLocationId;
              final rawLeft = (loc.mapX * width) - (markerWidth / 2);
              final rawTop = (loc.mapY * height) - (markerHeight / 2);

              final safeLeft = _safeClamp(rawLeft, padding, maxMarkerLeft);
              final safeTop = _safeClamp(rawTop, padding, maxMarkerTop);

              return Positioned(
                left: safeLeft,
                top: safeTop,
                child: _BuildingMarker(
                  location: loc,
                  isSelected: isSelected,
                  width: markerWidth,
                  onTap: () => onSelectLocation(loc),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// Building marker card on the map canvas.
class _BuildingMarker extends StatelessWidget {
  final CampusLocation location;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _BuildingMarker({
    required this.location,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surface.withValues(alpha: 0.2)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      location.shortCode,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.textInverse
                            : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  location.category.icon,
                  size: 12,
                  color: isSelected
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              location.name,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
                color: isSelected
                    ? AppColors.textInverse
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// "You Are Here" user location marker with pulse ring and GPS status.
class _UserLocationMarker extends StatelessWidget {
  final bool isRealGps;
  final double accuracy;

  const _UserLocationMarker({required this.isRealGps, this.accuracy = 5.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isRealGps ? 'You (GPS)' : 'You Are Here',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter for connected campus avenues and road pathways.
class _CampusRoadsPainter extends CustomPainter {
  const _CampusRoadsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;

    // 1. Campus Road Paint
    final roadPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final roadPath = Path();

    // Central Avenue (Admin Block -> Central Plaza -> Main Gate)
    roadPath.moveTo(w * 0.50, h * 0.16);
    roadPath.lineTo(w * 0.50, h * 0.90);

    // Western Boulevard (S&H -> IT Park -> Bus Stop)
    roadPath.moveTo(w * 0.20, h * 0.20);
    roadPath.lineTo(w * 0.20, h * 0.85);

    // Eastern Avenue (Library -> EEE -> EIE)
    roadPath.moveTo(w * 0.80, h * 0.20);
    roadPath.lineTo(w * 0.80, h * 0.82);

    // North Crosswalk (S&H <-> Admin <-> Library)
    roadPath.moveTo(w * 0.20, h * 0.20);
    roadPath.lineTo(w * 0.80, h * 0.20);

    // Central Crosswalk (IT Park <-> Central Plaza / Food Court <-> EEE Block)
    roadPath.moveTo(w * 0.20, h * 0.48);
    roadPath.lineTo(w * 0.80, h * 0.48);

    // South Crosswalk (Bus Stop <-> Central Gate <-> EIE Block)
    roadPath.moveTo(w * 0.20, h * 0.80);
    roadPath.lineTo(w * 0.80, h * 0.80);

    // Draw Road Borders then Road Surfaces
    canvas.drawPath(roadPath, roadBorderPaint);
    canvas.drawPath(roadPath, roadPaint);

    // 2. Central Plaza Roundabout / Quadrangle
    final plazaPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), 32.0, plazaPaint);

    final plazaInner = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), 24.0, plazaInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for outdoor route polyline connecting current location to selected building.
class _OutdoorRoutePainter extends CustomPainter {
  final OutdoorRoute route;

  const _OutdoorRoutePainter({required this.route});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || route.waypoints.isEmpty) return;

    final double w = size.width;
    final double h = size.height;

    final path = Path();
    for (int i = 0; i < route.waypoints.length; i++) {
      final pt = route.waypoints[i];
      final px = pt.dx * w;
      final py = pt.dy * h;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    // Glow halo
    final glow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glow);

    // Main route line
    final line = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _OutdoorRoutePainter oldDelegate) {
    return oldDelegate.route.destination.id != route.destination.id;
  }
}

/// Blueprint grid lines.
class _CampusGridPainter extends CustomPainter {
  const _CampusGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 0.8;

    const step = 28.0;
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
