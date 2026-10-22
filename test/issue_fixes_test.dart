import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_campus_navigation/main.dart';
import 'package:smart_campus_navigation/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_campus_navigation/screens/auth/welcome_screen.dart';
import 'package:smart_campus_navigation/screens/main_screen.dart';
import 'package:smart_campus_navigation/services/auth_service.dart';
import 'package:smart_campus_navigation/services/campus_location_service.dart';
import 'package:smart_campus_navigation/services/outdoor_routing_service.dart';

void main() {
  group('Smart Campus Navigation — 10 Required Verification Tests', () {
    late AuthService authService;
    late CampusLocationService locationService;
    late OutdoorRoutingService routingService;

    setUp(() async {
      authService = AuthService();
      authService.resetBookmarks();
      await authService.logout();
      locationService = CampusLocationService();
      locationService.clearCurrentBuilding();
      routingService = OutdoorRoutingService();
    });

    // TEST 1: Open the app -> Welcome/Login page appears first.
    testWidgets('TEST 1: Welcome/Login page appears FIRST when app is opened',
        (tester) async {
      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('SMART CAMPUS'), findsOneWidget);
      expect(find.text('Campus Navigation System'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Student Login'), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);
    });

    // TEST 2: Click Continue as Guest -> Guest can access map and navigation.
    testWidgets('TEST 2: Guest continues to map and navigation without account',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Campus Map'), findsNothing); // On Home tab

      // Switch to Map tab
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Campus Map'), findsWidgets);
      expect(find.text('ITP'), findsWidgets);
    });

    // TEST 3: Student logs in -> searches Library -> clicks Save. Library appears in Saved Locations.
    // Close/reopen -> Library is still saved for that student.
    test('TEST 3: Student saves Library bookmark and it persists across sessions',
        () async {
      // 1. Login as Student A (Alex Kumar)
      final loginResult = await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(loginResult.success, isTrue);
      expect(authService.isStudent, isTrue);

      // 2. Ensure Library is bookmarked
      if (!authService.isLocationSaved('loc_library')) {
        authService.toggleBookmark('loc_library', isRoom: false);
      }

      expect(authService.isLocationSaved('loc_library'), isTrue);
      expect(locationService.isLocationBookmarked('loc_library'), isTrue);

      // Verify Library appears in student's savedLocations
      final saved = locationService.savedLocations;
      expect(saved.any((loc) => loc.id == 'loc_library'), isTrue);

      // 3. Simulate close & reopen by re-logging in
      await authService.logout();
      expect(locationService.savedLocations, isEmpty);

      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(authService.isLocationSaved('loc_library'), isTrue);
      expect(locationService.savedLocations.any((l) => l.id == 'loc_library'), isTrue);
    });

    // TEST 4: Student removes Library bookmark -> Library disappears from Saved Locations.
    test('TEST 4: Student removes bookmark and it immediately disappears',
        () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      // Ensure it is currently saved
      if (!authService.isLocationSaved('loc_library')) {
        authService.toggleBookmark('loc_library', isRoom: false);
      }
      expect(authService.isLocationSaved('loc_library'), isTrue);

      // Remove bookmark
      final removed = authService.removeBookmark('loc_library', isRoom: false);
      expect(removed, isTrue);
      expect(authService.isLocationSaved('loc_library'), isFalse);
      expect(locationService.isLocationBookmarked('loc_library'), isFalse);
      expect(locationService.savedLocations.any((l) => l.id == 'loc_library'), isFalse);
    });

    // TEST 5: Student A saves Library. Login as Student B -> Student B cannot see Student A's Library bookmark.
    test('TEST 5: Bookmarks are strictly isolated per Student userId', () async {
      // Student A (Alex Kumar: usr_student_01)
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      if (!authService.isLocationSaved('loc_library')) {
        authService.toggleBookmark('loc_library', isRoom: false);
      }
      expect(authService.isLocationSaved('loc_library'), isTrue);

      // Student B (Priya Sharma: usr_student_02)
      await authService.loginStudent(
        emailOrId: 'priya@campus.edu',
        password: 'student123',
      );
      expect(authService.currentUser?.userId, equals('usr_student_02'));

      // Student B should NOT see Student A's Library bookmark
      expect(authService.isLocationSaved('loc_library'), isFalse);
      expect(locationService.isLocationBookmarked('loc_library'), isFalse);
      expect(locationService.savedLocations.any((l) => l.id == 'loc_library'), isFalse);

      // Student B has Food Court bookmark
      expect(authService.isLocationSaved('loc_food_court'), isTrue);
      expect(locationService.savedLocations.any((l) => l.id == 'loc_food_court'), isTrue);
    });

    // TEST 6: Start at Building A (IT Park) -> Select Building B (Library).
    // Expected route: IT Park entrance -> Library entrance (NOT arbitrary GPS road coordinate).
    test('TEST 6: Route from IT Park to Library starts strictly from IT Park entrance coordinates',
        () async {
      final itPark = locationService.getLocationById('loc_it_park')!;
      final library = locationService.getLocationById('loc_library')!;

      final route = await routingService.calculateWalkingRoute(
        start: const LatLng(11.2750, 77.6050), // Arbitrary GPS location
        destination: library,
        startBuilding: itPark,
        startType: NavigationStartType.selectedBuilding,
      );

      // Verify Start coordinate matches IT Park entrance coordinates
      expect(route.startPoint.latitude, equals(itPark.effectiveEntranceLatitude));
      expect(route.startPoint.longitude, equals(itPark.effectiveEntranceLongitude));

      // Verify Destination coordinate matches Library entrance coordinates
      expect(route.destinationPoint.latitude, equals(library.effectiveEntranceLatitude));
      expect(route.destinationPoint.longitude, equals(library.effectiveEntranceLongitude));

      expect(route.originDisplayName, equals('IT Park (Entrance)'));
      expect(route.destinationDisplayName, equals('Library (Entrance)'));
      expect(route.steps.first.instruction, contains('Depart from IT Park'));
    });

    // TEST 7: After reaching Building B, select Building C (Admin Block -> IT Park).
    test('TEST 7: Continuous building routing uses Admin Block entrance as origin to IT Park',
        () async {
      final adminBlock = locationService.getLocationById('loc_admin_block')!;
      final itPark = locationService.getLocationById('loc_it_park')!;

      // Simulate user set at Admin Block
      locationService.setCurrentBuilding('loc_admin_block');
      expect(locationService.currentBuilding?.id, equals('loc_admin_block'));

      final route = await routingService.calculateWalkingRoute(
        start: const LatLng(11.2720, 77.6080),
        destination: itPark,
        startBuilding: locationService.currentBuilding,
        startType: NavigationStartType.selectedBuilding,
      );

      // Origin must be Admin Block entrance
      expect(route.startPoint.latitude, equals(adminBlock.effectiveEntranceLatitude));
      expect(route.startPoint.longitude, equals(adminBlock.effectiveEntranceLongitude));
      expect(route.destinationPoint.latitude, equals(itPark.effectiveEntranceLatitude));
      expect(route.destinationPoint.longitude, equals(itPark.effectiveEntranceLongitude));
      expect(route.steps.first.instruction, contains('Depart from Admin Block'));
    });

    // TEST 8: Logout -> Welcome/Login page appears.
    testWidgets('TEST 8: Logout returns user to Welcome/Login page',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Login as student
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      await tester.pumpWidget(const SmartCampusApp(home: MainScreen()));
      await tester.pumpAndSettle();

      // Tap logout icon in top right
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      // Verify WelcomeScreen is displayed
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(authService.isGuest, isTrue);
    });

    // TEST 9: Try to access Admin Dashboard as Student -> Access denied.
    testWidgets('TEST 9: Student accessing Admin Dashboard is denied access',
        (tester) async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      await tester.pumpWidget(
        const MaterialApp(home: AdminDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Unauthorized Access'), findsOneWidget);
    });

    // TEST 10: Try to access Student Saved Locations as Guest -> Guest is asked to log in as Student.
    testWidgets('TEST 10: Guest accessing Saved Locations is prompted to log in as Student',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await authService.continueAsGuest();
      await tester.pumpWidget(const SmartCampusApp(home: MainScreen(initialTabIndex: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Saved Locations'), findsOneWidget);
      expect(find.text('Student Bookmarks'), findsOneWidget);
      expect(
        find.text(
          'Please login as a student to use Saved Locations.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign In as Student'), findsOneWidget);
    });
  });
}
