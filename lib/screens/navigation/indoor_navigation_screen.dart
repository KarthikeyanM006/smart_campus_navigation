import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../models/indoor_navigation.dart';
import '../../services/indoor_navigation_service.dart';
import '../../widgets/indoor_nav_schematic_view.dart';

/// Indoor turn-by-turn navigation screen showing schematic route, distance, duration, and step-by-step guidance.
class IndoorNavigationScreen extends StatefulWidget {
  final CampusLocation building;
  final CampusFloor floor;
  final CampusRoom destinationRoom;
  final String? startPointName;

  const IndoorNavigationScreen({
    super.key,
    required this.building,
    required this.floor,
    required this.destinationRoom,
    this.startPointName,
  });

  @override
  State<IndoorNavigationScreen> createState() => _IndoorNavigationScreenState();
}

class _IndoorNavigationScreenState extends State<IndoorNavigationScreen> {
  late IndoorRoute _route;
  bool _isNavigating = false;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _route = IndoorNavigationService().calculateRoute(
      building: widget.building,
      destinationRoom: widget.destinationRoom,
      currentFloorNumber: widget.floor.floorNumber,
      startPointOverride: widget.startPointName,
    );
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _route.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      _finishNavigation();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _finishNavigation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('You Have Arrived!', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'You have reached ${widget.destinationRoom.roomCode} (${widget.destinationRoom.name}) on ${widget.destinationRoom.floorDisplay}.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isNavigating = false;
                _currentStepIndex = 0;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _route.steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Indoor Navigation', style: AppTextStyles.heading2),
            Text(
              '${widget.building.name} • ${widget.destinationRoom.floorDisplay}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP ROUTE SUMMARY & METRICS BAR
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
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
                      widget.destinationRoom.roomCode,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textInverse,
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
                          widget.destinationRoom.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'From ${_route.startPointName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${_route.distanceMeters}m',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '~${_route.estimatedMinutes} min',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. SCHEMATIC FLOOR MAP WITH VISIBLE ROUTE
            Expanded(
              child: SingleChildScrollView(
                child: IndoorNavSchematicView(
                  buildingName: widget.building.name,
                  floor: widget.floor,
                  destinationRoom: widget.destinationRoom,
                  startPointName: _route.startPointName,
                  isMultiFloorTransit: _route.isDifferentFloor,
                  nodePath: _route.nodePath,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. NAVIGATION CONTROLS & TURN-BY-TURN GUIDANCE
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isNavigating) ...[
                    // Pre-navigation state
                    Row(
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Route Prepared (${_route.steps.length} Steps)',
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Follow indoor hallway indicators and turn towards your assigned wing.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text('Start Navigation'),
                      ),
                    ),
                  ] else ...[
                    // Active navigation turn-by-turn state
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'STEP ${_currentStepIndex + 1} OF ${_route.steps.length}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${currentStep.distanceMeters} meters',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            currentStep.icon,
                            color: AppColors.textInverse,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStep.instruction,
                                style: AppTextStyles.heading3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentStep.detail,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (_currentStepIndex > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              child: const Text('Back'),
                            ),
                          ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            child: Text(
                              _currentStepIndex == _route.steps.length - 1
                                  ? 'Arrived'
                                  : 'Next Step',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
