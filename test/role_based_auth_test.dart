import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_navigation/main.dart';
import 'package:smart_campus_navigation/models/campus_location.dart';
import 'package:smart_campus_navigation/models/campus_room.dart';
import 'package:smart_campus_navigation/models/location_category.dart';
import 'package:smart_campus_navigation/models/user_role.dart';
import 'package:smart_campus_navigation/screens/auth/welcome_screen.dart';
import 'package:smart_campus_navigation/services/auth_service.dart';
import 'package:smart_campus_navigation/services/campus_location_service.dart';
import 'package:smart_campus_navigation/widgets/class_mapping_card.dart';

void main() {
  group('1. Authentication & Role-Based Access Unit Tests', () {
    late AuthService authService;

    setUp(() async {
      authService = AuthService();
      authService.resetBookmarks();
      await authService.logout(); // Reset to guest state
    });

    test('Default session starts as Guest with restricted permissions', () {
      expect(authService.isGuest, isTrue);
      expect(authService.isStudent, isFalse);
      expect(authService.isAdmin, isFalse);
      expect(authService.canBookmark(), isFalse);
      expect(authService.canManageCampus(), isFalse);
    });

    test('Guest cannot bookmark and returns false', () {
      final canBookmark = authService.toggleBookmark('loc_it_park');
      expect(canBookmark, isFalse);
      expect(authService.isLocationSaved('loc_it_park'), isFalse);
    });

    test('Student Login succeeds with valid credentials', () async {
      final result = await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(result.success, isTrue);
      expect(authService.isStudent, isTrue);
      expect(authService.currentRole, equals(UserRole.student));
      expect(authService.currentUser?.name, equals('Alex Kumar'));
      expect(authService.canBookmark(), isTrue);
      expect(authService.canManageCampus(), isFalse);
    });

    test('Student can toggle, save, and remove bookmarks', () async {
      await authService.loginStudent(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );

      // Bookmark a building
      final savedBuilding = authService.toggleBookmark('loc_ece_block', isRoom: false);
      expect(savedBuilding, isTrue);
      expect(authService.isLocationSaved('loc_ece_block'), isTrue);

      // Bookmark a room
      final savedRoom = authService.toggleBookmark('room_itp_301', isRoom: true);
      expect(savedRoom, isTrue);
      expect(authService.isRoomSaved('room_itp_301'), isTrue);

      // Remove bookmark
      authService.toggleBookmark('loc_ece_block', isRoom: false);
      expect(authService.isLocationSaved('loc_ece_block'), isFalse);
    });

    test('Student registration creates hashed password and logs in', () async {
      final result = await authService.registerStudent(
        name: 'New Student',
        email: 'new.student@campus.edu',
        password: 'securePass123',
        department: 'CSE',
        studentId: '22CS999',
      );
      expect(result.success, isTrue);
      expect(authService.currentUser?.passwordHash, isNotNull);
      // Verify password is NOT stored as plain text
      expect(authService.currentUser?.passwordHash, isNot(equals('securePass123')));
      expect(authService.currentUser?.verifyPassword('securePass123'), isTrue);
      expect(authService.currentUser?.verifyPassword('wrongPassword'), isFalse);
    });

    test('Admin Login succeeds with admin credentials and grants admin role', () async {
      final result = await authService.loginAdmin(
        emailOrId: 'admin@campus.edu',
        password: 'admin123',
      );
      expect(result.success, isTrue);
      expect(authService.isAdmin, isTrue);
      expect(authService.currentRole, equals(UserRole.admin));
      expect(authService.canManageCampus(), isTrue);
    });

    test('Student cannot log in through Admin portal', () async {
      final result = await authService.loginAdmin(
        emailOrId: 'student@campus.edu',
        password: 'student123',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('Access Denied'));
    });

    test('Admin password verification fails on incorrect password', () async {
      final result = await authService.loginAdmin(
        emailOrId: 'admin@campus.edu',
        password: 'wrongAdminPassword',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('Invalid password'));
    });

    test('Logout clears session and returns to Guest mode', () async {
      await authService.loginAdmin(
        emailOrId: 'admin@campus.edu',
        password: 'admin123',
      );
      expect(authService.isAdmin, isTrue);

      await authService.logout();
      expect(authService.isGuest, isTrue);
      expect(authService.isAdmin, isFalse);
      expect(authService.currentUser?.role, equals(UserRole.guest));
    });
  });

  group('2. Dynamic Classroom Mapping & Campus CRUD Tests', () {
    late CampusLocationService locationService;
    late AuthService authService;

    setUp(() async {
      locationService = CampusLocationService();
      authService = AuthService();
      await authService.loginAdmin(emailOrId: 'admin@campus.edu', password: 'admin123');
    });

    test('Dynamic classroom mapping CSE-A can be updated by admin (ITP001 -> ITP101)', () async {
      // 1. Check initial mapping for CSE-A
      locationService.setSearchQuery('CSE-A');
      final initialResults = locationService.filteredClassMappings;
      expect(initialResults, isNotEmpty);
      expect(initialResults.first.className, equals('CSE-A'));
      expect(initialResults.first.roomNumber, equals('ITP001'));

      // 2. Admin updates CSE-A mapping to Room ITP101
      final updatedMapping = initialResults.first.copyWith(
        roomNumber: 'ITP101',
        roomName: 'Software Systems Lab (Allocated to CSE-A)',
        floor: 1,
      );
      await locationService.saveClassMapping(updatedMapping);

      // 3. Search CSE-A immediately reflects the updated room ITP101
      locationService.setSearchQuery('CSE-A');
      final updatedResults = locationService.filteredClassMappings;
      expect(updatedResults, isNotEmpty);
      expect(updatedResults.first.className, equals('CSE-A'));
      expect(updatedResults.first.roomNumber, equals('ITP101'));
      expect(updatedResults.first.roomName, contains('Allocated to CSE-A'));
    });

    test('Admin can add, edit, and delete buildings dynamically', () async {
      const newBuilding = CampusLocation(
        id: 'loc_robotics_block',
        name: 'Robotics & Automation Block',
        shortCode: 'ROBO',
        category: LocationCategory.academic,
        description: 'Mechatronics, Autonomous Systems and Drone Arena.',
        floorCount: 2,
        departments: ['Robotics', 'Mechatronics'],
        operatingHours: '08:00 AM - 06:00 PM',
        latitude: 11.2740,
        longitude: 77.6072,
      );

      // Add building
      await locationService.addBuilding(newBuilding);
      expect(locationService.getLocationById('loc_robotics_block'), isNotNull);
      expect(locationService.getLocationById('loc_robotics_block')?.name, equals('Robotics & Automation Block'));

      // Update building
      final updated = newBuilding.copyWith(name: 'Advanced Robotics Hub');
      await locationService.updateBuilding(updated);
      expect(locationService.getLocationById('loc_robotics_block')?.name, equals('Advanced Robotics Hub'));

      // Delete building
      await locationService.deleteBuilding('loc_robotics_block');
      expect(locationService.getLocationById('loc_robotics_block'), isNull);
    });

    test('Admin can add and update rooms on specific floors', () async {
      const newRoom = CampusRoom(
        id: 'room_itp_105',
        roomCode: 'ITP105',
        name: 'Cyber Physical Systems Lab',
        buildingId: 'loc_it_park',
        buildingName: 'IT Park',
        floor: 1,
        category: LocationCategory.academic,
        department: 'CSE',
        className: 'CSE-D',
        description: 'Hardware in the loop simulation laboratory.',
        operatingHours: '08:00 AM - 05:00 PM',
      );

      await locationService.saveRoom(newRoom);
      expect(locationService.getRoomById('room_itp_105'), isNotNull);
      expect(locationService.getRoomById('room_itp_105')?.roomCode, equals('ITP105'));

      // Delete room
      await locationService.deleteRoom('room_itp_105');
      expect(locationService.getRoomById('room_itp_105'), isNull);
    });
  });

  group('3. UI Role-Based Widget & Navigation Tests', () {
    testWidgets('Guest sees WelcomeScreen options: Continue as Guest, Student Login, Admin Portal', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SMART CAMPUS'), findsOneWidget);
      expect(find.text('Campus Navigation System'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Student Login'), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);
    });

    testWidgets('Guest tapping bookmark in HomeScreen shows "Please log in as a student to use bookmarks."', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await AuthService().continueAsGuest();
      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      // Tap Continue as Guest on WelcomeScreen
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Verify Guest indicator in top header
      expect(find.text('Guest'), findsOneWidget);

      // Scroll to and tap first LocationCard Bookmark button
      final bookmarkBtn = find.byTooltip('Bookmark').first;
      await tester.tap(bookmarkBtn);
      await tester.pumpAndSettle();

      // Verify guest toast message
      expect(find.text('Please log in as a student to use bookmarks.'), findsOneWidget);
    });

    testWidgets('Search "CSE-A" renders ClassMappingCard with Get Directions and View Floor buttons', (tester) async {
      await AuthService().continueAsGuest();
      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      // Tap Continue as Guest on WelcomeScreen
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField).first;
      await tester.enterText(searchInput, 'CSE-A');
      await tester.pumpAndSettle();

      // Verify Class Allocations section & card
      expect(find.text('Class Allocations'), findsOneWidget);
      expect(find.byType(ClassMappingCard), findsWidgets);
      expect(find.text('CSE-A'), findsWidgets);
      expect(find.text('Get Directions'), findsWidgets);
      expect(find.text('View Floor'), findsWidgets);
    });

    testWidgets('Admin logs in and opens Admin Dashboard successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const SmartCampusApp());
      await tester.pumpAndSettle();

      // Tap Admin Portal on WelcomeScreen
      await tester.tap(find.text('Admin Portal'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).at(0), 'admin@campus.edu');
      await tester.enterText(find.byType(TextField).at(1), 'admin123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Authorize & Open Dashboard'));
      await tester.pumpAndSettle();

      // Verify Admin Dashboard opened
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Class Mappings'), findsOneWidget);
      expect(find.text('Buildings'), findsOneWidget);
      expect(find.text('Floors & Rooms'), findsOneWidget);
      expect(find.text('Facilities'), findsOneWidget);
    });
  });
}
