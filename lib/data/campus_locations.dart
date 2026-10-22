import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/mock_campus_data.dart';
import '../models/campus_floor.dart';
import '../models/campus_location.dart';
import '../models/location_category.dart';

/// Centralized repository of all real campus buildings and GPS coordinates for Smart Campus Navigation.
class CampusLocationData {
  CampusLocationData._();

  /// Default campus center coordinates
  static const LatLng campusCenter = LatLng(11.2735, 77.6068);
  static const double defaultZoom = 16.8;

  /// All 11 primary campus buildings with exact real-world coordinates
  static final List<CampusLocation> campusBuildings = [
    // 1. Admin Block
    CampusLocation(
      id: 'loc_admin_block',
      name: 'Admin Block',
      shortCode: 'ADM',
      category: LocationCategory.administrative,
      buildingType: 'Administrative',
      description: 'Principal office, Dean chambers, Admissions, Accounts, and Academic Affairs center.',
      floorCount: 3,
      departments: [
        'Admissions',
        'Finance & Fees',
        'Examinations',
        'Student Affairs',
      ],
      operatingHours: '08:30 AM - 05:00 PM',
      latitude: 11.274320029251658,
      longitude: 77.60700139363509,
      entranceLatitude: 11.274320029251658,
      entranceLongitude: 77.60700139363509,
      hasIndoorMap: true,
      mapX: 0.50,
      mapY: 0.20,
      isSaved: false,
      tags: ['Admin', 'Principal', 'Admissions', 'Office', 'Fees Counter'],
      floors: [
        CampusFloor(
          floorNumber: 0,
          floorName: 'Ground Floor',
          rooms: [MockCampusData.adminRooms[0]],
        ),
        CampusFloor(
          floorNumber: 1,
          floorName: 'Floor 1',
          rooms: [MockCampusData.adminRooms[1]],
        ),
        CampusFloor(
          floorNumber: 2,
          floorName: 'Floor 2',
          rooms: [MockCampusData.adminRooms[2]],
        ),
      ],
    ),

    // 2. EIE & EEE Block
    CampusLocation(
      id: 'loc_eie_eee_block',
      name: 'EIE & EEE Block',
      shortCode: 'EEE/EIE',
      category: LocationCategory.academic,
      buildingType: 'Academic / Engineering Lab',
      description: 'Electrical, Electronics and Instrumentation Engineering laboratories, Power Systems, and Automation benches.',
      floorCount: 4,
      departments: [
        'Electrical & Electronics',
        'Electronics & Instrumentation',
        'Power Systems',
      ],
      operatingHours: '08:00 AM - 06:00 PM',
      latitude: 11.274333278182414,
      longitude: 77.60757690407794,
      entranceLatitude: 11.274333278182414,
      entranceLongitude: 77.60757690407794,
      hasIndoorMap: true,
      mapX: 0.65,
      mapY: 0.20,
      isSaved: false,
      tags: ['EEE', 'EIE', 'Power Lab', 'Sensors', 'Circuits', 'Drives'],
      floors: [
        CampusFloor(
          floorNumber: 0,
          floorName: 'Ground Floor',
          rooms: [MockCampusData.eeeRooms[0], MockCampusData.eieRooms[0]],
        ),
        CampusFloor(
          floorNumber: 2,
          floorName: 'Floor 2',
          rooms: [MockCampusData.eieRooms[1]],
        ),
        CampusFloor(
          floorNumber: 3,
          floorName: 'Floor 3',
          rooms: [MockCampusData.eeeRooms[1]],
        ),
      ],
    ),

    // 3. S&H Block
    CampusLocation(
      id: 'loc_sh_block',
      name: 'S&H Block',
      shortCode: 'S&H',
      category: LocationCategory.academic,
      buildingType: 'Academic / Science & Humanities',
      description: 'Science and Humanities department, First-year engineering classrooms, Physics, and Chemistry labs.',
      floorCount: 2,
      departments: [
        'Mathematics',
        'Physics',
        'Chemistry',
        'English & Humanities',
      ],
      operatingHours: '08:00 AM - 05:30 PM',
      latitude: 11.275154710707204,
      longitude: 77.6076822792332,
      entranceLatitude: 11.275154710707204,
      entranceLongitude: 77.6076822792332,
      hasIndoorMap: true,
      mapX: 0.70,
      mapY: 0.12,
      isSaved: false,
      tags: ['Freshmen Block', 'Science Labs', 'Drawing Halls', 'Physics Lab'],
      floors: [
        CampusFloor(
          floorNumber: 0,
          floorName: 'Ground Floor',
          rooms: [MockCampusData.shRooms[0]],
        ),
        CampusFloor(
          floorNumber: 1,
          floorName: 'Floor 1',
          rooms: [MockCampusData.shRooms[1]],
        ),
      ],
    ),

    // 4. MBA Block
    CampusLocation(
      id: 'loc_mba_block',
      name: 'MBA Block',
      shortCode: 'MBA',
      category: LocationCategory.academic,
      buildingType: 'Academic / Management Studies',
      description: 'Department of Management Studies, Executive seminar halls, Case study discussion rooms, and Faculty chambers.',
      floorCount: 3,
      departments: [
        'Management Studies',
        'Finance & Marketing',
        'Human Resources',
      ],
      operatingHours: '08:30 AM - 05:30 PM',
      latitude: 11.275682016157178,
      longitude: 77.60809567406368,
      entranceLatitude: 11.275682016157178,
      entranceLongitude: 77.60809567406368,
      hasIndoorMap: false,
      mapX: 0.85,
      mapY: 0.10,
      isSaved: false,
      tags: ['MBA', 'Management', 'Seminar Hall', 'Business', 'Executive'],
    ),

    // 5. CT-UG Block
    CampusLocation(
      id: 'loc_ct_ug_block',
      name: 'CT-UG Block',
      shortCode: 'CT-UG',
      category: LocationCategory.academic,
      buildingType: 'Academic / Computer Technology',
      description: 'Computer Technology undergraduate classrooms, Software engineering labs, and Programming workspace.',
      floorCount: 3,
      departments: ['Computer Technology', 'Information Science'],
      operatingHours: '08:00 AM - 06:00 PM',
      latitude: 11.273578088150002,
      longitude: 77.60606382498214,
      entranceLatitude: 11.273578088150002,
      entranceLongitude: 77.60606382498214,
      hasIndoorMap: false,
      mapX: 0.35,
      mapY: 0.40,
      isSaved: false,
      tags: ['CT-UG', 'Computer Technology', 'Programming Lab', 'Classrooms'],
    ),

    // 6. IT Park
    CampusLocation(
      id: 'loc_it_park',
      name: 'IT Park',
      shortCode: 'ITP',
      category: LocationCategory.academic,
      buildingType: 'Academic / Technology Hub',
      description: 'Computer Science, Information Technology, AI/DS laboratories, and tech innovation center.',
      floorCount: 4,
      departments: [
        'Computer Science',
        'Information Technology',
        'AI & Data Science',
      ],
      operatingHours: '08:00 AM - 07:00 PM',
      latitude: 11.273694679012738,
      longitude: 77.60702841291867,
      entranceLatitude: 11.273694679012738,
      entranceLongitude: 77.60702841291867,
      hasIndoorMap: true,
      mapX: 0.55,
      mapY: 0.40,
      isSaved: false,
      tags: ['Labs', 'Auditorium', 'Smart Classrooms', 'Coding Hub', 'AI Lab'],
      floors: MockCampusData.itpFloors,
    ),

    // 7. FT & Chemical Block
    CampusLocation(
      id: 'loc_ft_chem_block',
      name: 'FT & Chemical Block',
      shortCode: 'FT/CHEM',
      category: LocationCategory.academic,
      buildingType: 'Academic / Process Engineering',
      description: 'Food Technology and Chemical Engineering pilot processing plants, Analytical chemistry, and Bio-process laboratories.',
      floorCount: 3,
      departments: ['Food Technology', 'Chemical Engineering'],
      operatingHours: '08:00 AM - 05:30 PM',
      latitude: 11.272560565797683,
      longitude: 77.60719593238882,
      entranceLatitude: 11.272560565797683,
      entranceLongitude: 77.60719593238882,
      hasIndoorMap: false,
      mapX: 0.60,
      mapY: 0.60,
      isSaved: false,
      tags: [
        'Food Technology',
        'Chemical Engineering',
        'Processing Plant',
        'Analytical Lab',
      ],
    ),

    // 8. Food Court
    CampusLocation(
      id: 'loc_food_court',
      name: 'Food Court',
      shortCode: 'FC',
      category: LocationCategory.amenities,
      buildingType: 'Dining & Amenities',
      description: 'Multi-cuisine cafeteria, snack counters, bakery, beverage kiosks, and covered dining areas.',
      floorCount: 1,
      departments: ['Main Cafeteria', 'Snack Bar', 'Juice Kiosk', 'Bakery'],
      operatingHours: '07:30 AM - 08:30 PM',
      latitude: 11.2728149467118,
      longitude: 77.60682306646258,
      entranceLatitude: 11.2728149467118,
      entranceLongitude: 77.60682306646258,
      hasIndoorMap: true,
      mapX: 0.50,
      mapY: 0.55,
      isSaved: false,
      tags: ['Dining', 'Cafeteria', 'Snacks', 'Beverages', 'Meals'],
      floors: [
        CampusFloor(
          floorNumber: 0,
          floorName: 'Ground Floor',
          rooms: MockCampusData.foodCourtRooms,
        ),
      ],
    ),

    // 9. ECE Block
    CampusLocation(
      id: 'loc_ece_block',
      name: 'ECE Block',
      shortCode: 'ECE',
      category: LocationCategory.academic,
      buildingType: 'Academic / Electronics Engineering',
      description: 'Electronics and Communication Engineering wing, VLSI design suites, Microwave labs, and Digital Signal Processing centers.',
      floorCount: 4,
      departments: [
        'Electronics & Communication',
        'VLSI Design',
        'Communication Systems',
      ],
      operatingHours: '08:00 AM - 06:00 PM',
      latitude: 11.272311484250583,
      longitude: 77.60530188156989,
      entranceLatitude: 11.272311484250583,
      entranceLongitude: 77.60530188156989,
      hasIndoorMap: false,
      mapX: 0.20,
      mapY: 0.65,
      isSaved: false,
      tags: ['ECE', 'VLSI', 'Antennas', 'Communication Lab', 'DSP'],
    ),

    // 10. Library
    CampusLocation(
      id: 'loc_library',
      name: 'Library',
      shortCode: 'LIB',
      category: LocationCategory.library,
      buildingType: 'Central Library & Archives',
      description: 'Central campus library with digital archives, quiet study zones, IEEE/ACM journals, and book borrowing services.',
      floorCount: 3,
      departments: [
        'Digital Library',
        'Reference Section',
        'Periodicals',
        'Study Hall',
      ],
      operatingHours: '08:00 AM - 09:00 PM',
      latitude: 11.271119069633304,
      longitude: 77.6052694584445,
      entranceLatitude: 11.271119069633304,
      entranceLongitude: 77.6052694584445,
      hasIndoorMap: true,
      mapX: 0.20,
      mapY: 0.85,
      isSaved: false,
      tags: ['Quiet Study', 'Digital Archives', 'Journals', 'Reference Books'],
      floors: [
        CampusFloor(
          floorNumber: 0,
          floorName: 'Ground Floor',
          rooms: [MockCampusData.libRooms[0]],
        ),
        CampusFloor(
          floorNumber: 1,
          floorName: 'Floor 1',
          rooms: [MockCampusData.libRooms[1]],
        ),
        CampusFloor(
          floorNumber: 2,
          floorName: 'Floor 2',
          rooms: [MockCampusData.libRooms[2]],
        ),
      ],
    ),

    // 11. Maharaja Auditorium
    CampusLocation(
      id: 'loc_auditorium',
      name: 'Maharaja Auditorium',
      shortCode: 'AUD',
      category: LocationCategory.amenities,
      buildingType: 'Auditorium & Convention Center',
      description: 'State-of-the-art campus convention center and grand acoustic auditorium for graduation ceremonies, cultural festivals, and national symposiums.',
      floorCount: 2,
      departments: [
        'Campus Events',
        'Cultural Affairs',
        'Convention Facilities',
      ],
      operatingHours: '08:00 AM - 08:00 PM',
      latitude: 11.272247888930217,
      longitude: 77.60595574789971,
      entranceLatitude: 11.272247888930217,
      entranceLongitude: 77.60595574789971,
      hasIndoorMap: false,
      mapX: 0.35,
      mapY: 0.70,
      isSaved: false,
      tags: [
        'Auditorium',
        'Conventions',
        'Cultural Events',
        'Maharaja Auditorium',
      ],
    ),
  ];

  /// Returns an appropriate icon for the campus building.
  static IconData getBuildingIcon(CampusLocation location) {
    final nameLower = location.name.toLowerCase();
    final codeLower = location.shortCode.toLowerCase();

    if (nameLower.contains('food') || codeLower == 'fc') {
      return Icons.restaurant_rounded;
    } else if (nameLower.contains('library') || codeLower == 'lib') {
      return Icons.local_library_rounded;
    } else if (nameLower.contains('auditorium') || codeLower == 'aud') {
      return Icons.theater_comedy_rounded;
    } else if (nameLower.contains('admin') || codeLower == 'adm') {
      return Icons.account_balance_rounded;
    } else if (nameLower.contains('it park') || codeLower == 'itp') {
      return Icons.memory_rounded;
    } else if (nameLower.contains('eee') || nameLower.contains('eie')) {
      return Icons.bolt_rounded;
    } else if (nameLower.contains('chem') || nameLower.contains('s&h')) {
      return Icons.science_rounded;
    } else if (nameLower.contains('mba')) {
      return Icons.business_center_rounded;
    } else if (nameLower.contains('ece')) {
      return Icons.settings_input_antenna_rounded;
    } else {
      return Icons.school_rounded;
    }
  }

  /// Returns a themed accent color for the building type.
  static Color getBuildingColor(CampusLocation location) {
    final nameLower = location.name.toLowerCase();
    final codeLower = location.shortCode.toLowerCase();

    if (nameLower.contains('food') || codeLower == 'fc') {
      return const Color(0xFFEA580C); // Warm Orange
    } else if (nameLower.contains('library') || codeLower == 'lib') {
      return const Color(0xFF7C3AED); // Deep Purple
    } else if (nameLower.contains('auditorium') || codeLower == 'aud') {
      return const Color(0xFFE11D48); // Rose / Crimson
    } else if (nameLower.contains('admin') || codeLower == 'adm') {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (nameLower.contains('it park') || codeLower == 'itp') {
      return const Color(0xFF0284C7); // Tech Blue
    } else if (nameLower.contains('eee') || nameLower.contains('eie')) {
      return const Color(0xFFD97706); // Amber Gold
    } else if (nameLower.contains('chem')) {
      return const Color(0xFF059669); // Emerald Green
    } else if (nameLower.contains('mba')) {
      return const Color(0xFF6366F1); // Indigo
    } else if (nameLower.contains('ece')) {
      return const Color(0xFF0891B2); // Cyan
    } else {
      return const Color(0xFF4F46E5); // Academic Indigo
    }
  }
}
