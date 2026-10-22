import 'package:flutter/material.dart';

/// Categories of campus locations.
enum LocationCategory {
  all,
  academic,
  administrative,
  library,
  amenities,
  transit;

  String get displayName {
    switch (this) {
      case LocationCategory.all:
        return 'All';
      case LocationCategory.academic:
        return 'Academic';
      case LocationCategory.administrative:
        return 'Admin';
      case LocationCategory.library:
        return 'Library';
      case LocationCategory.amenities:
        return 'Amenities';
      case LocationCategory.transit:
        return 'Transit';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationCategory.all:
        return Icons.grid_view_rounded;
      case LocationCategory.academic:
        return Icons.school_outlined;
      case LocationCategory.administrative:
        return Icons.business_outlined;
      case LocationCategory.library:
        return Icons.local_library_outlined;
      case LocationCategory.amenities:
        return Icons.restaurant_outlined;
      case LocationCategory.transit:
        return Icons.directions_bus_outlined;
    }
  }
}
