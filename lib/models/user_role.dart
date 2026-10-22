import 'package:flutter/material.dart';

/// Role types for Smart Campus Navigation.
enum UserRole {
  guest,
  student,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'Guest';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.guest:
        return Icons.person_outline_rounded;
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.guest:
        return const Color(0xFF64748B); // Slate
      case UserRole.student:
        return const Color(0xFF2563EB); // Blue
      case UserRole.admin:
        return const Color(0xFF7C3AED); // Purple
    }
  }
}
