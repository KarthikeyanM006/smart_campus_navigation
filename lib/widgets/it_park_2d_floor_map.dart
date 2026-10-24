import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/it_park_layout_data.dart';

/// Interactive, zoomable 2D floor map widget for IT Park building.
/// Renders authentic hand-drawn architectural floor layout with clean room outlines,
/// readable numbers, distinct corridors, staircase, entrance dome, and collision-free routes.
class ITPark2DFloorMap extends StatelessWidget {
  final int floorNumber;
  final ITParkRoomData? selectedRoom;
  final ValueChanged<ITParkRoomData> onRoomTap;
  final bool startFromEntrance;
  final List<Offset> routePoints;
  final TransformationController transformationController;
  final ValueChanged<Size>? onViewportReady;
  final Offset? activeUserPosition;

  const ITPark2DFloorMap({
    super.key,
    required this.floorNumber,
    required this.selectedRoom,
    required this.onRoomTap,
    this.startFromEntrance = true,
    this.routePoints = const [],
    required this.transformationController,
    this.onViewportReady,
    this.activeUserPosition,
  });

  @override
  Widget build(BuildContext context) {
    final rooms = ITParkLayoutData.getRoomsForFloor(floorNumber);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (onViewportReady != null && viewportSize.width > 0 && viewportSize.height > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onViewportReady!(viewportSize);
          });
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: const Color(0xFF0F172A), // Dark slate architectural blueprint
            child: Stack(
              children: [
                // Zoomable and Pannable 2D Canvas - unconstrained for full freedom of movement
                InteractiveViewer(
                  transformationController: transformationController,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(400),
                  minScale: 0.25,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: ITParkLayoutData.canvasWidth,
                    height: ITParkLayoutData.canvasHeight,
                    child: Stack(
                      children: [
                          // 1. Blueprint Grid & Structural Corridors Layer
                          CustomPaint(
                            size: const Size(
                              ITParkLayoutData.canvasWidth,
                              ITParkLayoutData.canvasHeight,
                            ),
                            painter: _ITParkStructuralPainter(
                              floorNumber: floorNumber,
                            ),
                          ),

                          // 2. Interactive Room Outlines & Labels Layer
                          ...rooms.map((room) {
                            final isSelected = selectedRoom?.id == room.id;
                            return Positioned(
                              left: room.bounds.left,
                              top: room.bounds.top,
                              width: room.bounds.width,
                              height: room.bounds.height,
                              child: _RoomItem(
                                room: room,
                                isSelected: isSelected,
                                onTap: () => onRoomTap(room),
                              ),
                            );
                          }),

                          // 3. Corridor Route Polyline Layer (Always strictly in corridors)
                          if (routePoints.isNotEmpty)
                            CustomPaint(
                              size: const Size(
                                ITParkLayoutData.canvasWidth,
                                ITParkLayoutData.canvasHeight,
                              ),
                              painter: _ITParkRoutePainter(
                                routePoints: routePoints,
                                startFromEntrance:
                                    floorNumber == 0 && startFromEntrance,
                                activeUserPosition: activeUserPosition,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Top Subtle Map Info Watermark
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pinch_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pinch to Zoom • Drag to Pan',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Painter for building structural walls, corridors, courtyard, and top dome.
class _ITParkStructuralPainter extends CustomPainter {
  final int floorNumber;

  _ITParkStructuralPainter({required this.floorNumber});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Architectural blueprint fine grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. North Architectural Top Dome (Entrance / Floor Header)
    final domePath = Path();
    domePath.moveTo(330, 80);
    domePath.quadraticBezierTo(420, 10, 510, 80);
    domePath.close();

    final domeFill = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(domePath, domeFill);

    final domeBorder = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(domePath, domeBorder);

    // Text in Top Dome
    final domeLabel = floorNumber == 0
        ? 'ENTRANCE'
        : (floorNumber == 1 ? '1st FLOOR' : '2nd FLOOR');
    final textPainter = TextPainter(
      text: TextSpan(
        text: domeLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(420 - (textPainter.width / 2), 48 - (textPainter.height / 2)),
    );

    // 3. Corridor Loop (Pathway) Background Fill
    // North corridor: y: 175 to 235
    // South corridor: y: 485 to 545
    // West corridor: x: 165 to 225
    // East corridor: x: 615 to 675
    final corridorPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Outer Corridor Ring
    final outerRing = Path()
      ..addRect(const Rect.fromLTWH(165, 175, 510, 370))
      ..addRect(const Rect.fromLTWH(225, 235, 390, 250))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outerRing, corridorPaint);

    // Ground entrance foyer connector
    if (floorNumber == 0) {
      final entranceWalkway = Path()
        ..addRect(const Rect.fromLTWH(385, 80, 70, 100));
      canvas.drawPath(entranceWalkway, corridorPaint);
    }

    // Corridor dashed guideline for clarity
    final corridorLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final corridorGuide = Path()
      ..moveTo(ITParkLayoutData.westCorridorX, ITParkLayoutData.northCorridorY)
      ..lineTo(ITParkLayoutData.eastCorridorX, ITParkLayoutData.northCorridorY)
      ..lineTo(ITParkLayoutData.eastCorridorX, ITParkLayoutData.southCorridorY)
      ..lineTo(ITParkLayoutData.westCorridorX, ITParkLayoutData.southCorridorY)
      ..close();
    canvas.drawPath(corridorGuide, corridorLinePaint);

    // Pathway labels on corridors
    _paintText(
      canvas,
      'PATHWAY',
      const Offset(420, 190),
      color: Colors.white24,
      fontSize: 9,
      letterSpacing: 2.0,
    );
    _paintText(
      canvas,
      'PATHWAY',
      const Offset(420, 528),
      color: Colors.white24,
      fontSize: 9,
      letterSpacing: 2.0,
    );

    // 4. Central Courtyard / Quadrangle
    final courtyardRect = const Rect.fromLTWH(225, 305, 390, 110);
    final courtyardFill = Paint()
      ..color = const Color(0xFF0F261D).withValues(alpha: 0.7) // Lush green courtyard tint
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtyardRect, const Radius.circular(8)),
      courtyardFill,
    );

    final courtyardBorder = Paint()
      ..color = const Color(0xFF059669).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtyardRect, const Radius.circular(8)),
      courtyardBorder,
    );

    _paintText(
      canvas,
      'CENTRAL COURTYARD / OPEN QUADRANGLE',
      const Offset(420, 360),
      color: const Color(0xFF34D399).withValues(alpha: 0.6),
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    );

    // 5. Outer Boundary Wall Border
    final outerWallPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(50, 80, 740, 560),
        const Radius.circular(4),
      ),
      outerWallPaint,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center, {
    Color color = Colors.white,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _ITParkStructuralPainter oldDelegate) {
    return oldDelegate.floorNumber != floorNumber;
  }
}

/// Interactive Room Box with outline, code badge, category colors, and selection glow.
class _RoomItem extends StatelessWidget {
  final ITParkRoomData room;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomItem({
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color baseFill;
    Color borderColor;
    Color textColor = Colors.white;

    switch (room.type) {
      case 'stairs':
        baseFill = isSelected ? const Color(0xFFD97706) : const Color(0xFF3B2A15);
        borderColor = const Color(0xFFF59E0B);
        break;
      case 'entrance':
        baseFill = isSelected ? AppColors.primary : const Color(0xFF1E3A5F);
        borderColor = AppColors.primary;
        break;
      case 'restroom':
        baseFill = isSelected ? const Color(0xFF0D9488) : const Color(0xFF133535);
        borderColor = const Color(0xFF14B8A6);
        break;
      case 'dining':
        baseFill = isSelected ? const Color(0xFFEA580C) : const Color(0xFF3F2314);
        borderColor = const Color(0xFFF97316);
        break;
      case 'office':
        baseFill = isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E2238);
        borderColor = const Color(0xFF818CF8);
        break;
      case 'lab':
        baseFill = isSelected ? const Color(0xFF0284C7) : const Color(0xFF14273E);
        borderColor = const Color(0xFF38BDF8);
        break;
      default:
        baseFill = isSelected ? const Color(0xFF2563EB) : const Color(0xFF182234);
        borderColor = const Color(0xFF60A5FA);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: baseFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : borderColor.withValues(alpha: 0.65),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selected Pin indicator
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),

            // Room Code / Label (e.g. "001", "103", "CC16", "Steps")
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                room.displayLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: room.displayLabel.length > 5 ? 10.5 : 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Optional Subtitle for special facilities
            if (room.type == 'stairs')
              const Text(
                'Steps',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (room.type == 'dining')
              const Text(
                'Pantry',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (room.type == 'restroom')
              const Text(
                'Washroom',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the active corridor route path line.
class _ITParkRoutePainter extends CustomPainter {
  final List<Offset> routePoints;
  final bool startFromEntrance;
  final Offset? activeUserPosition;

  _ITParkRoutePainter({
    required this.routePoints,
    required this.startFromEntrance,
    this.activeUserPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) return;

    final path = Path();
    for (int i = 0; i < routePoints.length; i++) {
      final pt = routePoints[i];
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // 1. Route Outer Halo / Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // 2. Crisp Vibrant Route Line
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF) // Electric Cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 3. Waypoint Junction Dots
    final waypointPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    final waypointCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 1; i < routePoints.length - 1; i++) {
      canvas.drawCircle(routePoints[i], 4.5, waypointPaint);
      canvas.drawCircle(routePoints[i], 2.0, waypointCore);
    }

    // 4. Start Pin ("You Are Here" / Entrance / Steps)
    final startPt = routePoints.first;
    final startGlow = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPt, 12.0, startGlow);

    final startBase = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPt, 7.0, startBase);

    final startCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPt, 3.0, startCore);

    // 5. Destination Pin (Target)
    final destPt = routePoints.last;
    final destGlow = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destPt, 14.0, destGlow);

    final destBase = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destPt, 8.0, destBase);

    final destCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destPt, 3.5, destCore);

    // 6. Active Live Navigation Beacon (User current step waypoint)
    if (activeUserPosition != null) {
      final userGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activeUserPosition!, 18.0, userGlow);

      final userRing = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(activeUserPosition!, 11.0, userRing);

      final userBase = Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activeUserPosition!, 7.5, userBase);

      final userCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activeUserPosition!, 3.5, userCore);
    }
  }

  @override
  bool shouldRepaint(covariant _ITParkRoutePainter oldDelegate) {
    if (oldDelegate.activeUserPosition != activeUserPosition) return true;
    if (oldDelegate.routePoints.length != routePoints.length) return true;
    for (int i = 0; i < routePoints.length; i++) {
      if (oldDelegate.routePoints[i] != routePoints[i]) return true;
    }
    return false;
  }
}
