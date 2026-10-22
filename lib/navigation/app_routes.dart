import 'package:flutter/material.dart';

/// Navigation constants and index mapping for bottom navigation tabs and named routes.
class AppRoutes {
  AppRoutes._();

  static const String initialRoute = '/';
  static const String welcomeRoute = '/welcome';
  static const String studentLoginRoute = '/student-login';
  static const String adminLoginRoute = '/admin-login';
  static const String homeRoute = '/home';
  static const String mapRoute = '/map';
  static const String savedRoute = '/saved';
  static const String adminDashboardRoute = '/admin-dashboard';

  // Bottom Navigation Tab Indices
  static const int tabHome = 0;
  static const int tabMap = 1;
  static const int tabSaved = 2;
  static const int tabAdmin = 3;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.bookmark_outline),
      selectedIcon: Icon(Icons.bookmark),
      label: 'Saved',
    ),
  ];

  static const List<NavigationDestination> adminDestinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.bookmark_outline),
      selectedIcon: Icon(Icons.bookmark),
      label: 'Saved',
    ),
    NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings_rounded),
      label: 'Admin',
    ),
  ];
}
