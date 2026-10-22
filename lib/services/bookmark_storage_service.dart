import 'dart:convert';
import 'dart:io';

import '../models/bookmark_model.dart';

/// Persistent local storage service for Smart Campus student bookmarks.
/// Stores bookmarks in local JSON format to persist data across app restarts,
/// logouts, and new sessions.
class BookmarkStorageService {
  static final BookmarkStorageService _instance =
      BookmarkStorageService._internal();
  factory BookmarkStorageService() => _instance;
  BookmarkStorageService._internal();

  static const String _fileName = 'smart_campus_bookmarks.json';
  File? _cachedFile;

  File _getStorageFile() {
    if (_cachedFile != null) return _cachedFile!;
    try {
      final dir = Directory.current;
      _cachedFile = File('${dir.path}${Platform.pathSeparator}$_fileName');
    } catch (_) {
      final tmp = Directory.systemTemp;
      _cachedFile = File('${tmp.path}${Platform.pathSeparator}$_fileName');
    }
    return _cachedFile!;
  }

  /// Loads all persistent bookmarks from disk
  List<BookmarkModel> loadBookmarks() {
    try {
      final file = _getStorageFile();
      if (!file.existsSync()) {
        final defaults = _getDefaultSeedBookmarks();
        saveBookmarks(defaults);
        return defaults;
      }
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) {
        final defaults = _getDefaultSeedBookmarks();
        saveBookmarks(defaults);
        return defaults;
      }
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((item) => BookmarkModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _getDefaultSeedBookmarks();
    }
  }

  /// Loads bookmarks for a specific user ID
  List<BookmarkModel> loadBookmarksForUser(String userId) {
    if (userId.isEmpty || userId == 'user_guest') return const [];
    final all = loadBookmarks();
    return all.where((b) => b.userId == userId).toList();
  }

  /// Saves all bookmarks to disk
  void saveBookmarks(List<BookmarkModel> bookmarks) {
    try {
      final file = _getStorageFile();
      final data = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
      file.writeAsStringSync(data, flush: true);
    } catch (_) {
      // Graceful fallback for sandboxed environments
    }
  }

  /// Default seed bookmarks for initial demo accounts
  List<BookmarkModel> _getDefaultSeedBookmarks() {
    return [
      // Student 1 (Alex Kumar: usr_student_01) - Library & IT Park
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_itpark',
        userId: 'usr_student_01',
        locationId: 'loc_it_park',
        locationType: 'building',
        locationName: 'IT Park',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_lib',
        userId: 'usr_student_01',
        locationId: 'loc_library',
        locationType: 'building',
        locationName: 'Library',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_room201',
        userId: 'usr_student_01',
        locationId: 'room_itp_201',
        locationType: 'room',
        locationName: 'ITP201 - Advanced Computing & AI Lab',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_01_libroom',
        userId: 'usr_student_01',
        locationId: 'room_lib_201',
        locationType: 'room',
        locationName: 'LIB201 - Digital Reference & Quiet Zone',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),

      // Student 2 (Priya Sharma: usr_student_02) - Food Court
      BookmarkModel(
        bookmarkId: 'bm_usr_student_02_foodcourt',
        userId: 'usr_student_02',
        locationId: 'loc_food_court',
        locationType: 'building',
        locationName: 'Campus Food Court & Canteen',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      BookmarkModel(
        bookmarkId: 'bm_usr_student_02_room101',
        userId: 'usr_student_02',
        locationId: 'room_itp_101',
        locationType: 'room',
        locationName: 'ITP101 - Programming Lab 1',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
