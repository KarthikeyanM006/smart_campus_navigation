/// Data model representing a saved campus location or room bookmark for students.
class BookmarkModel {
  final String bookmarkId;
  final String userId;
  final String locationId;
  final String locationType; // "building" or "room"
  final String locationName;
  final DateTime createdAt;

  const BookmarkModel({
    required this.bookmarkId,
    required this.userId,
    required this.locationId,
    String? locationType,
    this.locationName = '',
    required this.createdAt,
    bool? isRoom,
  }) : locationType = locationType ?? (isRoom == true ? 'room' : 'building');

  /// Helper boolean to check if this bookmark is a room
  bool get isRoom => locationType == 'room';

  /// Factory constructor to create a new bookmark record
  factory BookmarkModel.create({
    required String userId,
    required String locationId,
    String locationType = 'building',
    String locationName = '',
    bool isRoom = false,
  }) {
    final effectiveType = isRoom ? 'room' : locationType;
    return BookmarkModel(
      bookmarkId:
          'bm_${userId}_${locationId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      locationId: locationId,
      locationType: effectiveType,
      locationName: locationName,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookmarkId': bookmarkId,
      'userId': userId,
      'locationId': locationId,
      'locationType': locationType,
      'locationName': locationName,
      'isRoom': isRoom,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    final isRoomVal = json['isRoom'] as bool? ?? false;
    final locType =
        json['locationType'] as String? ?? (isRoomVal ? 'room' : 'building');
    return BookmarkModel(
      bookmarkId: json['bookmarkId'] as String? ??
          'bm_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      locationType: locType,
      locationName: json['locationName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          locationId == other.locationId;

  @override
  int get hashCode => userId.hashCode ^ locationId.hashCode;
}
