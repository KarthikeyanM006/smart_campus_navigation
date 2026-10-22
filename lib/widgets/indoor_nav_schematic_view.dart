import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/campus_floor.dart';
import '../models/campus_room.dart';
import '../models/indoor_navigation.dart';

/// Indoor schematic map that renders walkable hallways and rooms,
/// dynamically drawing the route path strictly along connected graph nodes.
class IndoorNavSchematicView extends StatelessWidget {
  final String buildingName;
  final CampusFloor floor;
  final CampusRoom destinationRoom;
  final String startPointName;
  final bool isMultiFloorTransit;
  final List<IndoorNavNode> nodePath;

  const IndoorNavSchematicView({
    super.key,
    required this.buildingName,
    required this.floor,
    required this.destinationRoom,
    required this.startPointName,
    this.isMultiFloorTransit = false,
    this.nodePath = const [],
  });

  @override
  Widget build(BuildContext context) {
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
            // 1. Architectural blueprint background grid
            const Positioned.fill(
              child: CustomPaint(painter: _BlueprintGridPainter()),
            ),

            // 2. Visible Graph-Based Route Path Layer
            if (nodePath.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePathPainter(nodePath: nodePath),
                ),
              ),

            // 3. Schematic Architectural Layout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Status Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Text(
                          '${buildingName.toUpperCase()} • ${floor.floorName.toUpperCase()}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Active Route',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TOP ROW: NORTH WING ROOMS
                  Row(
                    children: topRooms.map((room) {
                      final isDestination =
                          room.roomCode == destinationRoom.roomCode;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _NavRoomBox(
                            room: room,
                            isDestination: isDestination,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // CENTRAL MAIN CORRIDOR (Walkable Hallway)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        Text(
                          'MAIN CORRIDOR',
                          style: AppTextStyles.labelSmall.copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BOTTOM SECTION: SOUTH ROOMS, CENTRAL ENTRANCE FOYER & VERTICAL TRANSIT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // South-West Room (e.g. ITP203)
                      if (bottomRooms.isNotEmpty)
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _NavRoomBox(
                              room: bottomRooms[0],
                              isDestination:
                                  bottomRooms[0].roomCode ==
                                  destinationRoom.roomCode,
                            ),
                          ),
                        ),

                      // Central Entrance Foyer ("You Are Here" / Main Entrance)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _EntranceFoyerBox(
                            startPointName: startPointName,
                            isActive: !isMultiFloorTransit,
                          ),
                        ),
                      ),

                      // South-East Room (e.g. ITP204)
                      if (bottomRooms.length > 1)
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _NavRoomBox(
                              room: bottomRooms[1],
                              isDestination:
                                  bottomRooms[1].roomCode ==
                                  destinationRoom.roomCode,
                            ),
                          ),
                        ),

                      // Vertical Transit (Stairs & Lift)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _StairsElevatorBox(
                            destinationFloorDisplay:
                                destinationRoom.floorDisplay,
                            isMultiFloorTransit: isMultiFloorTransit,
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
      ),
    );
  }
}

/// Custom painter that draws the route polyline strictly along the graph [nodePath].
class _RoutePathPainter extends CustomPainter {
  final List<IndoorNavNode> nodePath;

  const _RoutePathPainter({required this.nodePath});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || nodePath.isEmpty) return;

    const double pad = 16.0;
    final double innerWidth = size.width - (pad * 2);
    final double innerHeight = size.height - (pad * 2);

    final Path path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < nodePath.length; i++) {
      final node = nodePath[i];
      final double px = pad + (node.normalizedX * innerWidth);
      final double py = pad + (node.normalizedY * innerHeight);
      final pt = Offset(px, py);
      points.add(pt);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    // 1. Route Outer Glow / Halo for sharp contrast over elements
    final Paint glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // 2. Main Crisp Route Path Line (Restrained Accent Blue)
    final Paint routePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // 3. Intermediate Corridor Waypoint Junction Dots
    final Paint junctionPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    final Paint junctionCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 4.5, junctionPaint);
      canvas.drawCircle(points[i], 1.8, junctionCore);
    }

    // 4. Start Marker ("You Are Here" Node)
    if (points.isNotEmpty) {
      final startPt = points.first;
      final Paint startGlow = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPt, 12.0, startGlow);

      final Paint startBase = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPt, 6.5, startBase);

      final Paint startCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPt, 2.5, startCore);
    }

    // 5. Destination Target Marker Node
    if (points.length > 1) {
      final destPt = points.last;
      final Paint destGlow = Paint()
        ..color = AppColors.success.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(destPt, 13.0, destGlow);

      final Paint destBase = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.fill;
      canvas.drawCircle(destPt, 7.5, destBase);

      final Paint destCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(destPt, 2.5, destCore);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    if (oldDelegate.nodePath.length != nodePath.length) return true;
    for (int i = 0; i < nodePath.length; i++) {
      if (oldDelegate.nodePath[i].id != nodePath[i].id) return true;
    }
    return false;
  }
}

class _NavRoomBox extends StatelessWidget {
  final CampusRoom room;
  final bool isDestination;

  const _NavRoomBox({required this.room, required this.isDestination});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: isDestination ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDestination ? AppColors.primary : AppColors.border,
          width: isDestination ? 2 : 1,
        ),
        boxShadow: isDestination
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDestination) ...[
                const Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: AppColors.textInverse,
                ),
                const SizedBox(width: 3),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDestination
                      ? AppColors.surface.withValues(alpha: 0.2)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  room.roomCode,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDestination
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            room.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10.5,
              fontWeight: isDestination ? FontWeight.w600 : FontWeight.w500,
              color: isDestination
                  ? AppColors.textInverse
                  : AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          if (isDestination) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DESTINATION',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 8.5,
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntranceFoyerBox extends StatelessWidget {
  final String startPointName;
  final bool isActive;

  const _EntranceFoyerBox({
    required this.startPointName,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.my_location_rounded,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(height: 4),
          Text(
            'You Are Here',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            startPointName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StairsElevatorBox extends StatelessWidget {
  final String destinationFloorDisplay;
  final bool isMultiFloorTransit;

  const _StairsElevatorBox({
    required this.destinationFloorDisplay,
    required this.isMultiFloorTransit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMultiFloorTransit
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stairs_outlined,
            size: 16,
            color: isMultiFloorTransit
                ? AppColors.warning
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            'Transit',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isMultiFloorTransit
                  ? AppColors.warning
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMultiFloorTransit ? 'To $destinationFloorDisplay' : 'Stairs/Lift',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter();

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
