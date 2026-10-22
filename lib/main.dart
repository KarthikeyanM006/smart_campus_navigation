import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_routes.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/student_login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartCampusApp());
}

/// Root widget for the Smart Campus Navigation mobile application.
class SmartCampusApp extends StatelessWidget {
  final Widget? home;

  const SmartCampusApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home ?? const WelcomeScreen(),
      routes: {
        AppRoutes.welcomeRoute: (_) => const WelcomeScreen(),
        AppRoutes.studentLoginRoute: (_) => const StudentLoginScreen(),
        AppRoutes.adminLoginRoute: (_) => const AdminLoginScreen(),
        AppRoutes.adminDashboardRoute: (_) => const AdminDashboardScreen(),
        AppRoutes.homeRoute: (_) => const MainScreen(initialTabIndex: AppRoutes.tabHome),
        AppRoutes.mapRoute: (_) => const MainScreen(initialTabIndex: AppRoutes.tabMap),
        AppRoutes.savedRoute: (_) => const MainScreen(initialTabIndex: AppRoutes.tabSaved),
      },
    );
  }
}

/// Backwards-compatibility alias for tests or default entrypoints
typedef MyApp = SmartCampusApp;
