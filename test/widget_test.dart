import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_navigation/main.dart';
import 'package:smart_campus_navigation/services/campus_location_service.dart';
import 'package:smart_campus_navigation/services/location_service.dart';
import 'package:smart_campus_navigation/widgets/campus_map_canvas.dart';
import 'package:smart_campus_navigation/widgets/room_card.dart';

void main() {
  group('Phase 7 LocationService Unit Tests', () {
    test('LocationService calculates realistic straight-line distance', () {
      // Distance between Food Court (13.0818, 80.2702) and Admin Block (13.0835, 80.2705)
      final distance = LocationService.calculateStraightLineDistance(
        startLatitude: 13.0818,
        startLongitude: 80.2702,
        endLatitude: 13.0835,
        endLongitude: 80.2705,
      );
      expect(distance, greaterThan(150));
      expect(distance, lessThan(300));
    });

    test(
      'LocationService projects geographical GPS to 2D canvas coordinates',
      () {
        final centerPoint = LocationService.projectGpsToCanvas(
          13.0820,
          80.2715,
        );
        expect(centerPoint.dx, inInclusiveRange(0.12, 0.88));
        expect(centerPoint.dy, inInclusiveRange(0.12, 0.88));
      },
    );

    test('UserLocationData development mock initializes properly', () {
      final mock = UserLocationData.developmentMock();
      expect(mock.isMock, isTrue);
      expect(mock.mapX, equals(0.50));
      expect(mock.mapY, equals(0.50));
      expect(mock.accuracy, equals(5.0));
    });
  });

  group('Responsive Layout Tests for CampusMapCanvas', () {
    testWidgets(
      'CampusMapCanvas renders safely on compact mobile screen sizes',
      (WidgetTester tester) async {
        // Test on small screen size (e.g. 320x480)
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = CampusLocationService();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 480,
                child: CampusMapCanvas(
                  locations: service.allLocations,
                  selectedLocationId: service.allLocations.first.id,
                  userLocation: UserLocationData.developmentMock(),
                  onSelectLocation: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CampusMapCanvas), findsOneWidget);
        expect(find.text('You Are Here'), findsOneWidget);
      },
    );

    testWidgets(
      'CampusMapCanvas handles extremely constrained dimensions without throwing',
      (WidgetTester tester) async {
        final service = CampusLocationService();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 80,
                height: 80,
                child: CampusMapCanvas(
                  locations: service.allLocations,
                  selectedLocationId: service.allLocations.first.id,
                  userLocation: UserLocationData.developmentMock(),
                  onSelectLocation: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CampusMapCanvas), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Phase 5, 6 & 7: Campus Map, Real GPS Location & Indoor Navigation flow',
    (WidgetTester tester) async {
      // Set realistic mobile phone viewport size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Render App
      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      // Tap Continue as Guest on WelcomeScreen
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // 2. Search for "ITP201" (North Wing Room)
      final searchInput = find.byType(TextField).first;
      await tester.enterText(searchInput, 'ITP201');
      await tester.pumpAndSettle();

      // 3. Find RoomCard for ITP201 and tap Navigate
      expect(find.byType(RoomCard), findsOneWidget);
      final roomNavigateBtn = find.descendant(
        of: find.byType(RoomCard),
        matching: find.text('Navigate'),
      );
      expect(roomNavigateBtn, findsOneWidget);
      await tester.tap(roomNavigateBtn);
      await tester.pumpAndSettle();

      // 4. Verify IndoorNavigationScreen is rendered with graph-based visible route
      expect(find.text('Indoor Navigation'), findsOneWidget);
      expect(find.text('IT Park • Floor 2'), findsOneWidget);
      expect(find.text('ITP201'), findsWidgets);
      expect(find.text('Advanced Computing & AI Lab'), findsWidgets);
      expect(find.text('Active Route'), findsOneWidget);
      expect(find.text('You Are Here'), findsOneWidget);
      expect(find.text('DESTINATION'), findsOneWidget);

      // Verify distance & ETA metrics
      expect(find.text('50m'), findsOneWidget);
      expect(find.text('~1 min'), findsOneWidget);

      // 5. Verify and tap "Start Navigation"
      final startNavBtn = find.widgetWithText(
        ElevatedButton,
        'Start Navigation',
      );
      expect(startNavBtn, findsOneWidget);
      await tester.tap(startNavBtn);
      await tester.pumpAndSettle();

      // 6. Verify Active Turn-by-Turn Guidance State
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      expect(find.text('Start at Floor 2 Entrance'), findsOneWidget);

      // Tap "Next Step" -> Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 4'), findsOneWidget);
      expect(
        find.text('Turn left at Central Junction into Main Corridor'),
        findsOneWidget,
      );

      // Go back to Home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Reset search
      await tester.enterText(searchInput, '');
      await tester.pumpAndSettle();

      // 7. Test Phase 6 & 7: Campus Map Tab & GPS Location
      // Tap on Map bottom navigation bar item
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Verify Map Screen Elements
      expect(find.text('Campus Map'), findsWidgets);
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('My Location'), findsWidgets);
      expect(find.byTooltip('Campus Center'), findsOneWidget);

      // Verify building markers on map
      expect(find.text('ITP'), findsWidgets);
      expect(find.text('ADM'), findsWidgets);
      expect(find.text('LIB'), findsWidgets);
      expect(find.text('FC'), findsWidgets);

      // Tap "My Location" button
      await tester.tap(find.byTooltip('My Location').first);
      await tester.pumpAndSettle();

      // Select Admin Block marker (ADM)
      await tester.tap(find.text('ADM').first);
      await tester.pumpAndSettle();

      // Verify preview card for Admin Block with straight-line distance
      expect(find.text('Admin Block'), findsWidgets);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.textContaining('straight-line'), findsOneWidget);

      // Tap "Navigate" for Admin Block outdoor route
      final mapNavBtn = find.widgetWithText(ElevatedButton, 'Navigate');
      expect(mapNavBtn, findsOneWidget);
      await tester.tap(mapNavBtn);
      await tester.pumpAndSettle();

      // Verify OutdoorNavigationScreen opens first (STAGE 1: Outdoor GPS Navigation)
      expect(find.text('Admin Block'), findsWidgets);
      expect(find.byTooltip('Fit Route'), findsOneWidget);
      expect(find.text('View Floor Layout'), findsOneWidget);
      expect(find.textContaining('min walk'), findsOneWidget);

      // Verify FloorScreen did NOT open automatically
      expect(find.text('ADM • Ground Floor'), findsNothing);

      // Tap "View Floor Layout" (STAGE 2: Enter Building & Indoor Navigation)
      final viewFloorBtn = find.widgetWithText(
        ElevatedButton,
        'View Floor Layout',
      );
      expect(viewFloorBtn, findsOneWidget);
      await tester.tap(viewFloorBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify FloorScreen opens for Admin Block
      expect(find.text('Admin Block'), findsWidgets);
      expect(find.text('ADM • Ground Floor'), findsOneWidget);
      expect(find.text('Ground'), findsOneWidget);
    },
  );
}
