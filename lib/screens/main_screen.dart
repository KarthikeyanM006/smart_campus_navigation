import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'saved/saved_screen.dart';

/// Main navigation shell hosting Bottom Navigation Bar for Home, Map, Saved, and Admin tabs.
class MainScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainScreen({super.key, this.initialTabIndex = AppRoutes.tabHome});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  late int _currentIndex;
  String? _selectedLocationForMap;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMapWithBuilding(String locationId) {
    setState(() {
      _selectedLocationForMap = locationId;
      _currentIndex = AppRoutes.tabMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        final isAdmin = _authService.isAdmin;

        final screens = [
          HomeScreen(
            onNavigateToTab: _onTabSelected,
            onLocateBuilding: _navigateToMapWithBuilding,
          ),
          MapScreen(
            key: ValueKey('map_screen_$_selectedLocationForMap'),
            initialSelectedLocationId: _selectedLocationForMap,
          ),
          SavedScreen(
            onNavigateToTab: _onTabSelected,
            onLocateBuilding: _navigateToMapWithBuilding,
          ),
          if (isAdmin) const AdminDashboardScreen(),
        ];

        // Ensure index doesn't exceed screen bounds if admin logged out
        if (_currentIndex >= screens.length) {
          _currentIndex = AppRoutes.tabHome;
        }

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: isAdmin ? AppRoutes.adminDestinations : AppRoutes.destinations,
          ),
        );
      },
    );
  }
}
