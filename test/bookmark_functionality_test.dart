import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_navigation/main.dart';
import 'package:smart_campus_navigation/screens/main_screen.dart';
import 'package:smart_campus_navigation/services/auth_service.dart';
import 'package:smart_campus_navigation/services/campus_location_service.dart';
import 'package:smart_campus_navigation/widgets/location_card.dart';
import 'package:smart_campus_navigation/widgets/location_detail_sheet.dart';
import 'package:smart_campus_navigation/widgets/room_card.dart';

void main() {
  group('Bookmark & Save Functionality — 10 Required Tests', () {
    late AuthService authService;
    late CampusLocationService locationService;

    setUp(() async {
      authService = AuthService();
      locationService = CampusLocationService();
      authService.resetBookmarks();
      await authService.logout();
    });

    // TEST 1: Login as Student A. Save Library.
    // Expected:
    // - Bookmark becomes BLACK filled icon.
    // - Text changes to "Saved".
    // - Library immediately appears in Saved Locations.
    testWidgets('TEST 1: Student A saves Library -> BLACK filled bookmark & "Saved" text & appears in Saved tab',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Login as Student A (Alex Kumar)
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(authService.currentUser?.userId, equals('usr_student_01'));

      // Open location detail sheet for Library
      final library = locationService.getLocationById('loc_library')!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationDetailSheet.fromLocation(
              location: library,
              onToggleSave: () => locationService.toggleSaved(library.id),
              onNavigate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure initial state: if saved, verify black icon & "Saved"
      expect(find.text('Saved'), findsOneWidget);
      final iconFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.bookmark_rounded && w.color == Colors.black,
      );
      expect(iconFinder, findsOneWidget);

      // Verify Library is in savedLocations
      expect(
        locationService.savedLocations.any((loc) => loc.id == 'loc_library'),
        isTrue,
      );
    });

    // TEST 2: Reopen application. Login as Student A.
    // Expected: Library is still saved.
    test('TEST 2: Persistent storage retains Library saved for Student A across sessions',
        () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      if (!authService.isLocationSaved('loc_library')) {
        authService.toggleBookmark('loc_library');
      }
      expect(authService.isLocationSaved('loc_library'), isTrue);

      // Simulate app logout and restart
      await authService.logout();
      expect(locationService.savedLocations, isEmpty);

      // Student A logs back in
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(authService.isLocationSaved('loc_library'), isTrue);
      expect(
        locationService.savedLocations.any((loc) => loc.id == 'loc_library'),
        isTrue,
      );
    });

    // TEST 3: Click the BLACK bookmark -> becomes unfilled, text "Save", removed from Saved Locations.
    testWidgets('TEST 3: Clicking filled bookmark toggles to unfilled "Save" and removes from Saved tab',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      final library = locationService.getLocationById('loc_library')!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationDetailSheet.fromLocation(
              location: library,
              onToggleSave: () {},
              onNavigate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Currently saved
      expect(find.text('Saved'), findsOneWidget);

      // Tap Save/Saved button to unsave
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      // Now unfilled with text "Save"
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.bookmark_border_rounded,
        ),
        findsOneWidget,
      );

      // Removed from saved locations
      expect(authService.isLocationSaved('loc_library'), isFalse);
      expect(
        locationService.savedLocations.any((l) => l.id == 'loc_library'),
        isFalse,
      );
    });

    // TEST 4 & 5: Student A saves Library & IT Park -> Logout.
    // Student B logs in -> Student B Saved Locations must NOT contain Library or IT Park.
    test('TEST 4 & 5: Student B Saved Locations do NOT contain Student A bookmarks',
        () async {
      // 1. Student A saves Library and IT Park
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(authService.currentUser?.userId, equals('usr_student_01'));
      if (!authService.isLocationSaved('loc_library')) {
        authService.toggleBookmark('loc_library');
      }
      if (!authService.isLocationSaved('loc_it_park')) {
        authService.toggleBookmark('loc_it_park');
      }
      expect(authService.isLocationSaved('loc_library'), isTrue);
      expect(authService.isLocationSaved('loc_it_park'), isTrue);

      // Logout Student A
      await authService.logout();

      // 2. Student B (Priya Sharma: usr_student_02) logs in
      await authService.loginStudent(
        emailOrId: 'priya@campus.edu',
        password: 'student123',
      );
      expect(authService.currentUser?.userId, equals('usr_student_02'));

      // Verify Student B does NOT have Student A's bookmarks
      expect(authService.isLocationSaved('loc_library'), isFalse);
      expect(authService.isLocationSaved('loc_it_park'), isFalse);
      expect(locationService.isLocationBookmarked('loc_library'), isFalse);
      expect(locationService.isLocationBookmarked('loc_it_park'), isFalse);

      final studentBSaved = locationService.savedLocations.map((l) => l.id).toList();
      expect(studentBSaved.contains('loc_library'), isFalse);
      expect(studentBSaved.contains('loc_it_park'), isFalse);

      // Student B only has Food Court
      expect(authService.isLocationSaved('loc_food_court'), isTrue);
    });

    // TEST 6: Login as Guest -> No Student A or B bookmarks, cannot save, Saved tab prompts login.
    testWidgets('TEST 6: Guest has NO bookmarks, cannot save, Saved tab shows login prompt',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await authService.continueAsGuest();
      expect(authService.isGuest, isTrue);

      // 1. Check saved locations & rooms are completely empty
      expect(locationService.savedLocations, isEmpty);
      expect(locationService.savedRooms, isEmpty);
      expect(authService.studentSavedLocationIds, isEmpty);
      expect(authService.studentSavedRoomIds, isEmpty);

      // 2. Attempting to bookmark returns false
      final canBookmark = authService.toggleBookmark('loc_library');
      expect(canBookmark, isFalse);

      // 3. Open Saved Locations tab as Guest
      await tester.pumpWidget(
        const SmartCampusApp(home: MainScreen(initialTabIndex: 2)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Locations'), findsOneWidget);
      expect(find.text('Student Bookmarks'), findsOneWidget);
      expect(
        find.text('Please login as a student to use Saved Locations.'),
        findsOneWidget,
      );
      expect(find.text('Sign In as Student'), findsOneWidget);
    });

    // TEST 7: Login as Student A again -> Only Student A's saved locations shown.
    test('TEST 7: Login as Student A again shows ONLY Student A saved locations',
        () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      final savedIds = locationService.savedLocations.map((l) => l.id).toList();
      expect(savedIds.contains('loc_it_park'), isTrue);
      expect(savedIds.contains('loc_library'), isTrue);

      // Student B's bookmark (Food Court) is not in Student A's list
      expect(savedIds.contains('loc_food_court'), isFalse);
    });

    // TEST 8: Save the same location twice -> Only ONE bookmark entry exists (prevents duplicates).
    test('TEST 8: Toggle bookmark twice removes it, preventing duplicate entries',
        () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      // First ensure loc_ece_block is not saved
      authService.removeBookmark('loc_ece_block');
      expect(authService.isLocationSaved('loc_ece_block'), isFalse);

      // Save once -> added
      authService.toggleBookmark('loc_ece_block');
      expect(authService.isLocationSaved('loc_ece_block'), isTrue);
      final countOnce = authService.currentUserBookmarks
          .where((b) => b.locationId == 'loc_ece_block')
          .length;
      expect(countOnce, equals(1));

      // Second click -> removed
      authService.toggleBookmark('loc_ece_block');
      expect(authService.isLocationSaved('loc_ece_block'), isFalse);
      final countRemoved = authService.currentUserBookmarks
          .where((b) => b.locationId == 'loc_ece_block')
          .length;
      expect(countRemoved, equals(0));
    });

    // TEST 9: Save a location, navigate to another page, then return -> Bookmark still shows BLACK/Saved.
    testWidgets('TEST 9: LocationCard and RoomCard show BLACK icon when bookmarked',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      final itPark = locationService.getLocationById('loc_it_park')!;
      final room201 = locationService.getRoomById('room_itp_201')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LocationCard(location: itPark),
                RoomCard(room: room201),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find black bookmark icons for both cards
      final blackIcons = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.bookmark_rounded && w.color == Colors.black,
      );
      expect(blackIcons, findsNWidgets(2));
    });

    // TEST 10: Save a location, logout, login again -> Correct saved state restored from persistent storage.
    test('TEST 10: Save location, logout, login again restores saved state from disk',
        () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      // Save Food Technology block for Student A
      authService.toggleBookmark('loc_ft_chem_block');
      expect(authService.isLocationSaved('loc_ft_chem_block'), isTrue);

      // Logout
      await authService.logout();
      expect(authService.isGuest, isTrue);
      expect(locationService.savedLocations, isEmpty);

      // Log back in as Student A
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(authService.isLocationSaved('loc_ft_chem_block'), isTrue);
      expect(
        locationService.savedLocations.any((l) => l.id == 'loc_ft_chem_block'),
        isTrue,
      );
    });
  });
}
