import 'dart:math';
import 'package:flutter/material.dart';

import '../models/bookmark_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'bookmark_storage_service.dart';

/// Centralized Authentication and Session Service for Smart Campus Navigation.
/// Manages Guest, Student, and Admin user sessions, password verification,
/// role-based permissions, and user bookmark persistence.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final BookmarkStorageService _storageService = BookmarkStorageService();

  UserModel? _currentUser;
  final List<UserModel> _registeredUsers = [];
  late List<BookmarkModel> _bookmarks;

  AuthService._internal() {
    _seedDefaultUsers();
    _bookmarks = _storageService.loadBookmarks();
    // Default session is Guest
    _currentUser = UserModel.guest();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  UserRole get currentRole => _currentUser?.role ?? UserRole.guest;
  bool get isGuest => currentRole == UserRole.guest;
  bool get isStudent => currentRole == UserRole.student;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.role != UserRole.guest;

  /// Check whether the current user has student bookmark permissions
  bool canBookmark() => isStudent;

  /// Check whether the current user has administrative permissions
  bool canManageCampus() => isAdmin;

  /// Returns the saved location IDs for the currently logged-in student ONLY
  List<String> get studentSavedLocationIds {
    if (!isStudent || _currentUser == null) return const [];
    return _bookmarks
        .where((b) => b.userId == _currentUser!.userId && !b.isRoom)
        .map((b) => b.locationId)
        .toSet()
        .toList();
  }

  /// Returns the saved room IDs for the currently logged-in student ONLY
  List<String> get studentSavedRoomIds {
    if (!isStudent || _currentUser == null) return const [];
    return _bookmarks
        .where((b) => b.userId == _currentUser!.userId && b.isRoom)
        .map((b) => b.locationId)
        .toSet()
        .toList();
  }

  /// Returns all bookmark records for the currently logged-in student
  List<BookmarkModel> get currentUserBookmarks {
    if (!isStudent || _currentUser == null) return const [];
    return _bookmarks
        .where((b) => b.userId == _currentUser!.userId)
        .toList();
  }

  bool isLocationSaved(String locationId) {
    if (!isStudent || _currentUser == null) return false;
    return _bookmarks.any(
      (b) =>
          b.userId == _currentUser!.userId &&
          !b.isRoom &&
          b.locationId == locationId,
    );
  }

  bool isRoomSaved(String roomId) {
    if (!isStudent || _currentUser == null) return false;
    return _bookmarks.any(
      (b) =>
          b.userId == _currentUser!.userId &&
          b.isRoom &&
          b.locationId == roomId,
    );
  }

  /// Seeds initial demo accounts with secure hashed passwords
  void _seedDefaultUsers() {
    // 1. Admin Account: admin@campus.edu / admin123
    final adminSalt = 'admin_salt_883';
    _registeredUsers.add(
      UserModel(
        userId: 'usr_admin_01',
        name: 'Campus Administrator',
        email: 'admin@campus.edu',
        role: UserRole.admin,
        passwordHash: UserModel.hashPassword('admin123', adminSalt),
        salt: adminSalt,
      ),
    );

    // 2. Student Account 1: student@campus.edu / student123
    final studentSalt1 = 'student_salt_441';
    _registeredUsers.add(
      UserModel(
        userId: 'usr_student_01',
        name: 'Alex Kumar',
        email: 'student@campus.edu',
        role: UserRole.student,
        department: 'CSE',
        studentId: '21CS042',
        passwordHash: UserModel.hashPassword('student123', studentSalt1),
        salt: studentSalt1,
        savedLocationIds: ['loc_it_park', 'loc_library'],
        savedRoomIds: ['room_itp_201', 'room_lib_201'],
      ),
    );

    // 3. Student Account 2: priya@campus.edu / student123
    final studentSalt2 = 'student_salt_772';
    _registeredUsers.add(
      UserModel(
        userId: 'usr_student_02',
        name: 'Priya Sharma',
        email: 'priya@campus.edu',
        role: UserRole.student,
        department: 'IT',
        studentId: '21IT019',
        passwordHash: UserModel.hashPassword('student123', studentSalt2),
        salt: studentSalt2,
        savedLocationIds: ['loc_food_court'],
        savedRoomIds: ['room_itp_101'],
      ),
    );
  }

  /// Continues session as a Guest (no account required)
  Future<AuthResult> continueAsGuest() async {
    _currentUser = UserModel.guest();
    notifyListeners();
    return AuthResult.ok(_currentUser!);
  }

  /// Student Login
  Future<AuthResult> loginStudent({
    required String emailOrId,
    required String password,
  }) async {
    return login(
      emailOrId: emailOrId,
      password: password,
      expectedRole: UserRole.student,
    );
  }

  /// Admin Login
  Future<AuthResult> loginAdmin({
    required String emailOrId,
    required String password,
  }) async {
    return login(
      emailOrId: emailOrId,
      password: password,
      expectedRole: UserRole.admin,
    );
  }

  /// Universal Login with role verification
  Future<AuthResult> login({
    required String emailOrId,
    required String password,
    UserRole? expectedRole,
  }) async {
    final cleanInput = emailOrId.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanInput.isEmpty || cleanPass.isEmpty) {
      return const AuthResult.failure(
        'Please enter your credentials and password.',
      );
    }

    final user = _registeredUsers.firstWhere(
      (u) =>
          u.email.toLowerCase() == cleanInput ||
          (u.studentId?.toLowerCase() == cleanInput) ||
          (cleanInput == 'admin' && u.role == UserRole.admin) ||
          (cleanInput == 'student' &&
              u.role == UserRole.student &&
              u.userId == 'usr_student_01'),
      orElse: () => const UserModel(
        userId: '',
        name: '',
        email: '',
        role: UserRole.guest,
      ),
    );

    if (user.userId.isEmpty) {
      return const AuthResult.failure(
        'No account found with this email or ID.',
      );
    }

    // Role check if expectedRole is passed
    if (expectedRole != null && user.role != expectedRole) {
      if (expectedRole == UserRole.admin) {
        return const AuthResult.failure(
          'Access Denied: This account does not have Admin privileges.',
        );
      } else if (expectedRole == UserRole.student) {
        return const AuthResult.failure(
          'Please use the Admin login portal for administrator accounts.',
        );
      }
    }

    // Verify Password Hash
    final isValid = user.verifyPassword(cleanPass);
    if (!isValid) {
      return const AuthResult.failure(
        'Invalid password. Please check and try again.',
      );
    }

    // Reload fresh bookmarks from persistent storage
    _bookmarks = _storageService.loadBookmarks();

    // Attach student bookmarks dynamically for this specific user
    _currentUser = user.copyWith(
      savedLocationIds: _bookmarks
          .where((b) => b.userId == user.userId && !b.isRoom)
          .map((b) => b.locationId)
          .toSet()
          .toList(),
      savedRoomIds: _bookmarks
          .where((b) => b.userId == user.userId && b.isRoom)
          .map((b) => b.locationId)
          .toSet()
          .toList(),
    );

    notifyListeners();
    return AuthResult.ok(_currentUser!);
  }

  /// Registers a new student account
  Future<AuthResult> registerStudent({
    required String name,
    required String email,
    required String password,
    required String department,
    required String studentId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanDept = department.trim();
    final cleanId = studentId.trim().toUpperCase();
    final cleanPass = password.trim();

    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        cleanPass.isEmpty ||
        cleanId.isEmpty) {
      return const AuthResult.failure('Please fill out all registration fields.');
    }

    if (cleanPass.length < 6) {
      return const AuthResult.failure(
        'Password must be at least 6 characters long.',
      );
    }

    // Check for existing account
    final exists = _registeredUsers.any(
      (u) =>
          u.email.toLowerCase() == cleanEmail ||
          u.studentId?.toUpperCase() == cleanId,
    );
    if (exists) {
      return const AuthResult.failure(
        'An account with this email or Student ID already exists.',
      );
    }

    final salt = (Random().nextInt(900000) + 100000).toString();
    final newUser = UserModel(
      userId: 'usr_student_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      role: UserRole.student,
      department: cleanDept,
      studentId: cleanId,
      passwordHash: UserModel.hashPassword(cleanPass, salt),
      salt: salt,
      savedLocationIds: [],
      savedRoomIds: [],
    );

    _registeredUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();
    return AuthResult.ok(newUser);
  }

  /// Toggles a saved building or room bookmark for the currently logged-in student.
  /// Strictly prevents duplicate entries and associates the bookmark directly with the user's ID.
  bool toggleBookmark(
    String id, {
    bool isRoom = false,
    String? locationName,
    String? locationType,
  }) {
    if (!isStudent || _currentUser == null) {
      return false;
    }

    final userId = _currentUser!.userId;
    final existingIndex = _bookmarks.indexWhere(
      (b) => b.userId == userId && b.isRoom == isRoom && b.locationId == id,
    );

    if (existingIndex != -1) {
      // Remove bookmark immediately
      _bookmarks.removeAt(existingIndex);
    } else {
      // Add bookmark without duplicate
      _bookmarks.add(
        BookmarkModel.create(
          userId: userId,
          locationId: id,
          isRoom: isRoom,
          locationName: locationName ?? '',
          locationType: locationType ?? (isRoom ? 'room' : 'building'),
        ),
      );
    }

    // Persist changes to local persistent storage
    try {
      _storageService.saveBookmarks(_bookmarks);
    } catch (_) {
      return false;
    }

    // Update active UserModel snapshot
    _currentUser = _currentUser!.copyWith(
      savedLocationIds: studentSavedLocationIds,
      savedRoomIds: studentSavedRoomIds,
    );

    // Update registered users cache
    final idx = _registeredUsers.indexWhere((u) => u.userId == userId);
    if (idx != -1) {
      _registeredUsers[idx] = _currentUser!;
    }

    notifyListeners();
    return true;
  }

  /// Removes a specific bookmark for the current student
  bool removeBookmark(String locationId, {bool isRoom = false}) {
    if (!isStudent || _currentUser == null) return false;
    final userId = _currentUser!.userId;
    final existingIndex = _bookmarks.indexWhere(
      (b) => b.userId == userId && b.isRoom == isRoom && b.locationId == locationId,
    );
    if (existingIndex != -1) {
      _bookmarks.removeAt(existingIndex);
      _storageService.saveBookmarks(_bookmarks);
      _currentUser = _currentUser!.copyWith(
        savedLocationIds: studentSavedLocationIds,
        savedRoomIds: studentSavedRoomIds,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Resets bookmarks back to default seed for clean test runs
  void resetBookmarks() {
    _bookmarks = [
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_itpark',
        userId: 'usr_student_01',
        locationId: 'loc_it_park',
        locationType: 'building',
        locationName: 'IT Park',
        createdAt: DateTime.now(),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_lib',
        userId: 'usr_student_01',
        locationId: 'loc_library',
        locationType: 'building',
        locationName: 'Library',
        createdAt: DateTime.now(),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_room201',
        userId: 'usr_student_01',
        locationId: 'room_itp_201',
        locationType: 'room',
        locationName: 'ITP201 - Advanced Computing & AI Lab',
        createdAt: DateTime.now(),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_libroom',
        userId: 'usr_student_01',
        locationId: 'room_lib_201',
        locationType: 'room',
        locationName: 'LIB201 - Digital Reference & Quiet Zone',
        createdAt: DateTime.now(),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_02_foodcourt',
        userId: 'usr_student_02',
        locationId: 'loc_food_court',
        locationType: 'building',
        locationName: 'Food Court',
        createdAt: DateTime.now(),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_02_room101',
        userId: 'usr_student_02',
        locationId: 'room_itp_101',
        locationType: 'room',
        locationName: 'ITP101 - Programming Lab 1',
        createdAt: DateTime.now(),
      ),
    ];
    _storageService.saveBookmarks(_bookmarks);
    if (_currentUser != null && isStudent) {
      _currentUser = _currentUser!.copyWith(
        savedLocationIds: studentSavedLocationIds,
        savedRoomIds: studentSavedRoomIds,
      );
    }
    notifyListeners();
  }

  /// Logs out the current user and reverts to Guest mode
  Future<void> logout() async {
    _currentUser = UserModel.guest();
    notifyListeners();
  }
}
