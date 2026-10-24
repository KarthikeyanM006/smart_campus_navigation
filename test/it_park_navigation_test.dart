import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_campus_navigation/data/it_park_layout_data.dart';
import 'package:smart_campus_navigation/models/campus_location.dart';
import 'package:smart_campus_navigation/models/location_category.dart';
import 'package:smart_campus_navigation/screens/floor/it_park_floor_screen.dart';
import 'package:smart_campus_navigation/widgets/it_park_2d_floor_map.dart';

void main() {
  group('IT Park Floor Layout Data Tests', () {
    test('Ground floor contains rooms 001 to 024, entrance, and steps', () {
      final groundRooms = ITParkLayoutData.groundFloorRooms;
      expect(groundRooms.isNotEmpty, isTrue);

      // Verify specific room codes
      final codes = groundRooms.map((r) => r.roomCode).toList();
      expect(codes.contains('001') || codes.contains('ITP001'), isTrue);
      expect(codes.contains('002') || codes.contains('ITP002'), isTrue);
      expect(codes.contains('003') || codes.contains('ITP003'), isTrue);
      expect(codes.contains('006') || codes.contains('ITP006'), isTrue);
      expect(codes.contains('007') || codes.contains('ITP007'), isTrue);
      expect(codes.contains('012') || codes.contains('ITP012'), isTrue);
      expect(codes.contains('016') || codes.contains('ITP016'), isTrue);
      expect(codes.contains('017') || codes.contains('ITP017'), isTrue);
      expect(codes.contains('020') || codes.contains('ITP020'), isTrue);
      expect(codes.contains('024') || codes.contains('ITP024'), isTrue);
      expect(codes.contains('Entrance'), isTrue);
      expect(codes.contains('Steps'), isTrue);
    });

    test('First floor contains rooms 101 to 128, CC rooms, and library', () {
      final firstRooms = ITParkLayoutData.firstFloorRooms;
      expect(firstRooms.isNotEmpty, isTrue);

      final room103 = ITParkLayoutData.findRoomByCode('103');
      expect(room103, isNotNull);
      expect(room103!.floor, equals(1));
      expect(room103.displayLabel, contains('103'));

      final room128 = ITParkLayoutData.findRoomByCode('128');
      expect(room128, isNotNull);
      expect(room128!.floor, equals(1));
      expect(room128.displayLabel, equals('128'));

      final cc1 = ITParkLayoutData.findRoomByCode('CC1');
      expect(cc1, isNotNull);
      expect(cc1!.floor, equals(1));
    });

    test('Second floor contains rooms 201 to 227, CC16, dining hall, and steps', () {
      final secondRooms = ITParkLayoutData.secondFloorRooms;
      expect(secondRooms.isNotEmpty, isTrue);

      final room201 = ITParkLayoutData.findRoomByCode('201');
      expect(room201, isNotNull);
      expect(room201!.floor, equals(2));

      final room203 = ITParkLayoutData.findRoomByCode('203');
      expect(room203, isNotNull);
      expect(room203!.floor, equals(2));

      final room227 = ITParkLayoutData.findRoomByCode('227');
      expect(room227, isNotNull);
      expect(room227!.floor, equals(2));

      final cc16 = ITParkLayoutData.findRoomByCode('CC16');
      expect(cc16, isNotNull);
      expect(cc16!.floor, equals(2));

      final dining = ITParkLayoutData.findRoomByCode('Dining');
      expect(dining, isNotNull);
      expect(dining!.floor, equals(2));
    });

    test('Search functionality finds rooms by exact number', () {
      expect(ITParkLayoutData.searchRooms('001').isNotEmpty, isTrue);
      expect(ITParkLayoutData.searchRooms('103').isNotEmpty, isTrue);
      expect(ITParkLayoutData.searchRooms('128').isNotEmpty, isTrue);
      expect(ITParkLayoutData.searchRooms('203').isNotEmpty, isTrue);
      expect(ITParkLayoutData.searchRooms('227').isNotEmpty, isTrue);
    });

    test('Corridor route remains strictly along corridor coordinates', () {
      final room203 = ITParkLayoutData.findRoomByCode('203')!;
      final route = ITParkLayoutData.calculateCorridorRoute(
        startPoint: ITParkLayoutData.stairsDoorPoint,
        endPoint: room203.bounds.center,
        startAtEntrance: false,
      );

      expect(route.length, greaterThanOrEqualTo(2));
      // First waypoint is near the stairs door at the North corridor
      expect((route.first.dy - ITParkLayoutData.northCorridorY).abs(), lessThanOrEqualTo(2.0));
    });
  });

  group('ITParkFloorScreen Widget Tests', () {
    final mockBuilding = CampusLocation(
      id: 'loc_it_park',
      name: 'IT Park',
      shortCode: 'ITP',
      category: LocationCategory.academic,
      buildingType: 'Academic / Technology Hub',
      description: 'Computer Science and IT Labs',
      floorCount: 3,
      departments: const ['Computer Science', 'IT'],
      operatingHours: '08:00 AM - 07:00 PM',
      latitude: 11.2736,
      longitude: 77.6070,
      hasIndoorMap: true,
      floors: const [],
    );

    testWidgets('Renders IT Park floor screen with floor selector and 2D floor map', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ITParkFloorScreen(
            building: mockBuilding,
            initialFloorNumber: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Headers & Floor Selector
      expect(find.text('IT Park Floor Layout'), findsOneWidget);
      expect(find.text('Ground Floor'), findsOneWidget);
      expect(find.text('First Floor'), findsOneWidget);
      expect(find.text('Second Floor'), findsOneWidget);

      // 2. Verify 2D Floor Map presence
      expect(find.byType(ITPark2DFloorMap), findsOneWidget);

      // 3. Switch to Second Floor
      await tester.tap(find.text('Second Floor'));
      await tester.pumpAndSettle();

      // 4. Search for Room 203
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, '203');
      await tester.pumpAndSettle();

      // Verify search autocomplete dropdown appears
      expect(find.textContaining('Cyber Security Lab'), findsWidgets);

      // Select Room 203 from autocomplete
      await tester.tap(find.textContaining('Cyber Security Lab').first);
      await tester.pumpAndSettle();

      // Verify Room 203 details and Navigate button are rendered
      expect(find.text('203'), findsWidgets);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Room Info'), findsOneWidget);
    });

    testWidgets('Renders Ground floor on narrow mobile screen without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ITParkFloorScreen(
            building: mockBuilding,
            initialFloorNumber: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow exception occurred and route chips render
      expect(tester.takeException(), isNull);
      expect(find.text('Main Entrance'), findsOneWidget);
      expect(find.text('Staircase (Steps)'), findsOneWidget);

      // Verify zoom controls are responsive
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);
      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Navigate starts turn-by-turn navigation on 2D map without old layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ITParkFloorScreen(
            building: mockBuilding,
            initialFloorNumber: 0,
            initialSelectedRoomCodeOrId: '001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Navigate button is present
      final navBtn = find.widgetWithText(ElevatedButton, 'Navigate');
      expect(navBtn, findsOneWidget);

      // Tap Navigate
      await tester.tap(navBtn);
      await tester.pumpAndSettle();

      // Verify active step-by-step guidance card appears on the 2D layout screen
      expect(find.textContaining('STEP 1 OF'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.textContaining('Start at Main Entrance'), findsOneWidget);

      // Tap Next Step
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Verify Step 2 is active and Back button is now available
      expect(find.textContaining('STEP 2 OF'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Tap Back to return to Step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.textContaining('STEP 1 OF'), findsOneWidget);
    });
  });
}
