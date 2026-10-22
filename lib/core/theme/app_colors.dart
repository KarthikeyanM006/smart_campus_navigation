import 'package:flutter/material.dart';

/// Neutral, clean color palette for the Smart Campus Navigation app.
/// Focuses on white, slate, black, and subtle functional accents.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100

  // Text & Content
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textInverse = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color divider = Color(0xFFE2E8F0);

  // Primary & Neutrals
  static const Color primary = Color(
    0xFF0F172A,
  ); // Slate 900 (Dominant neutral)
  static const Color primaryLight = Color(0xFF334155); // Slate 700
  static const Color secondary = Color(0xFF475569); // Slate 600

  // Functional & Semantic Accents (Subtle, realistic)
  static const Color accent = Color(
    0xFF2563EB,
  ); // Subtle Blue for selected states
  static const Color accentLight = Color(0xFFEFF6FF); // Blue 50
  static const Color success = Color(
    0xFF16A34A,
  ); // Subtle Green for open status
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706); // Amber for alerts
  static const Color danger = Color(0xFFDC2626); // Red for closures

  // Chips & Badges
  static const Color badgeBackground = Color(0xFFF1F5F9);
  static const Color badgeText = Color(0xFF334155);
}
