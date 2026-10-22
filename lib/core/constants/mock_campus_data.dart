import '../../data/campus_locations.dart';
import '../../models/campus_floor.dart';
import '../../models/campus_location.dart';
import '../../models/campus_room.dart';
import '../../models/location_category.dart';

/// Predefined campus locations, floor hierarchies, and rooms for Smart Campus Navigation.
class MockCampusData {
  MockCampusData._();

  // IT Park Rooms by Floor
  static const List<CampusRoom> itpGroundRooms = [
    CampusRoom(
      id: 'room_itp_001',
      roomCode: 'ITP001',
      name: 'Main Foyer & Information Desk',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 0,
      category: LocationCategory.academic,
      description: 'Building entrance lobby, visitor check-in kiosk, and building directories.',
      operatingHours: '08:00 AM - 07:00 PM',
      tags: ['ITP001', 'Lobby', 'Helpdesk', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_itp_002',
      roomCode: 'ITP002',
      name: 'Tech Auditorium & Seminar Hall',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 0,
      category: LocationCategory.academic,
      description: '250-seat acoustic auditorium for department symposiums, hackathons, and guest lectures.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP002', 'Auditorium', 'Seminar', 'Events'],
    ),
    CampusRoom(
      id: 'room_itp_003',
      roomCode: 'ITP003',
      name: 'Server Infrastructure Center',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 0,
      category: LocationCategory.academic,
      description: 'Campus intranet core routing racks, high-availability clusters, and data backups.',
      operatingHours: '24 Hours (Authorized Only)',
      tags: ['ITP003', 'Server', 'Networking', 'Data Center'],
    ),
    CampusRoom(
      id: 'room_itp_004',
      roomCode: 'ITP004',
      name: 'Hardware Support & Maintenance',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 0,
      category: LocationCategory.academic,
      description: 'Workstation repair, network technician desk, and peripheral distribution.',
      operatingHours: '09:00 AM - 05:00 PM',
      tags: ['ITP004', 'Helpdesk', 'Hardware', 'Repairs'],
    ),
  ];

  static const List<CampusRoom> itpFloor1Rooms = [
    CampusRoom(
      id: 'room_itp_101',
      roomCode: 'ITP101',
      name: 'Software Systems Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 1,
      category: LocationCategory.academic,
      description: 'Undergraduate programming and software engineering laboratory with dedicated Linux environments.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP101', 'Software Lab', 'Java', 'Python', 'Floor 1'],
    ),
    CampusRoom(
      id: 'room_itp_102',
      roomCode: 'ITP102',
      name: 'Data Structures & Algorithms Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 1,
      category: LocationCategory.academic,
      description: 'Core CS lab focused on algorithmic problem solving, competitive programming, and databases.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP102', 'Algorithms', 'Databases', 'Floor 1'],
    ),
    CampusRoom(
      id: 'room_itp_103',
      roomCode: 'ITP103',
      name: 'Faculty Cabins - Computer Science',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 1,
      category: LocationCategory.academic,
      description: 'CS department head and professor consultation chambers for academic mentorship.',
      operatingHours: '09:00 AM - 04:30 PM',
      tags: ['ITP103', 'Faculty', 'HOD', 'Cabins', 'Floor 1'],
    ),
    CampusRoom(
      id: 'room_itp_104',
      roomCode: 'ITP104',
      name: 'Smart Lecture Hall 101',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 1,
      category: LocationCategory.academic,
      description: 'Interactive multimedia lecture hall with digital podium and lecture recording facilities.',
      operatingHours: '08:00 AM - 05:00 PM',
      tags: ['ITP104', 'Lecture Hall', 'Smart Classroom', 'Floor 1'],
    ),
  ];

  static const List<CampusRoom> itpFloor2Rooms = [
    CampusRoom(
      id: 'room_itp_201',
      roomCode: 'ITP201',
      name: 'Advanced Computing & AI Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 2,
      category: LocationCategory.academic,
      description: 'High-performance computing laboratory equipped with GPU workstations for AI, deep learning, and data science research.',
      operatingHours: '08:00 AM - 07:00 PM',
      tags: ['ITP201', 'AI Lab', 'GPU Cluster', 'Coding Lab', 'Floor 2'],
    ),
    CampusRoom(
      id: 'room_itp_202',
      roomCode: 'ITP202',
      name: 'Cloud Computing & DevOps Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 2,
      category: LocationCategory.academic,
      description: 'Virtualization studio focused on Kubernetes, distributed storage systems, and cloud architecture.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP202', 'Cloud Lab', 'DevOps', 'Kubernetes', 'Floor 2'],
    ),
    CampusRoom(
      id: 'room_itp_203',
      roomCode: 'ITP203',
      name: 'Cyber Security & Forensics Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 2,
      category: LocationCategory.academic,
      description: 'Isolated network testing ground for ethical hacking, digital forensics, and network defenses.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP203', 'Security', 'Forensics', 'Cryptography', 'Floor 2'],
    ),
    CampusRoom(
      id: 'room_itp_204',
      roomCode: 'ITP204',
      name: 'Machine Learning Studio',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 2,
      category: LocationCategory.academic,
      description: 'Collaborative student project workspace with dual-monitor developer rigs and brainstorming screens.',
      operatingHours: '08:00 AM - 07:00 PM',
      tags: ['ITP204', 'Machine Learning', 'Project Lab', 'Studio', 'Floor 2'],
    ),
  ];

  static const List<CampusRoom> itpFloor3Rooms = [
    CampusRoom(
      id: 'room_itp_301',
      roomCode: 'ITP301',
      name: 'IoT & Embedded Systems Lab',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 3,
      category: LocationCategory.academic,
      description: 'Microcontroller benches, sensor kits, 3D printers, and edge computing prototype stations.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['ITP301', 'IoT Lab', 'Embedded', 'Sensors', 'Floor 3'],
    ),
    CampusRoom(
      id: 'room_itp_302',
      roomCode: 'ITP302',
      name: 'PG & PhD Research Cubicles',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 3,
      category: LocationCategory.academic,
      description: 'Quiet dedicated study stations and computing workstations for doctoral scholars.',
      operatingHours: '08:00 AM - 08:00 PM',
      tags: ['ITP302', 'Research', 'PhD', 'Quiet Zone', 'Floor 3'],
    ),
    CampusRoom(
      id: 'room_itp_303',
      roomCode: 'ITP303',
      name: 'Department Reference Library',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 3,
      category: LocationCategory.academic,
      description: 'Specialized IT & CS text reserves, IEEE conference proceedings, and project thesis archives.',
      operatingHours: '08:30 AM - 05:30 PM',
      tags: ['ITP303', 'Library', 'Theses', 'Journals', 'Floor 3'],
    ),
    CampusRoom(
      id: 'room_itp_304',
      roomCode: 'ITP304',
      name: 'Innovation & Incubation Cell',
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: 3,
      category: LocationCategory.academic,
      description: 'Student startup incubation bay, conference meeting room, and presentation theatre.',
      operatingHours: '08:00 AM - 07:00 PM',
      tags: ['ITP304', 'Startups', 'Incubation', 'Discussion', 'Floor 3'],
    ),
  ];

  // Admin Block Rooms
  static const List<CampusRoom> adminRooms = [
    CampusRoom(
      id: 'room_adm_001',
      roomCode: 'ADM001',
      name: 'Central Information & Reception',
      buildingId: 'loc_admin_block',
      buildingName: 'Admin Block',
      floor: 0,
      category: LocationCategory.administrative,
      description: 'Main reception for campus visitors, guest passes, and general inquiries.',
      operatingHours: '08:00 AM - 05:00 PM',
      tags: ['ADM001', 'Reception', 'Inquiry', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_adm_101',
      roomCode: 'ADM101',
      name: 'Admissions & Student Welfare',
      buildingId: 'loc_admin_block',
      buildingName: 'Admin Block',
      floor: 1,
      category: LocationCategory.administrative,
      description: 'Central helpdesk for student admissions, certificates, identity verification, and fees.',
      operatingHours: '08:30 AM - 05:00 PM',
      tags: ['ADM101', 'Admissions', 'Certificates', 'Desk', 'Floor 1'],
    ),
    CampusRoom(
      id: 'room_adm_201',
      roomCode: 'ADM201',
      name: 'Principal Chamber & Board Room',
      buildingId: 'loc_admin_block',
      buildingName: 'Admin Block',
      floor: 2,
      category: LocationCategory.administrative,
      description: 'Administrative leadership office and governing body conference hall.',
      operatingHours: '09:00 AM - 05:00 PM',
      tags: ['ADM201', 'Principal', 'Conference', 'Board Room', 'Floor 2'],
    ),
  ];

  // S&H Block Rooms
  static const List<CampusRoom> shRooms = [
    CampusRoom(
      id: 'room_sh_001',
      roomCode: 'SH001',
      name: 'Engineering Chemistry Lab',
      buildingId: 'loc_sh_block',
      buildingName: 'S&H Block',
      floor: 0,
      category: LocationCategory.academic,
      description: 'Titration stations, water quality analysis apparatus, and polymer testing kits.',
      operatingHours: '08:00 AM - 05:00 PM',
      tags: ['SH001', 'Chemistry Lab', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_sh_101',
      roomCode: 'SH101',
      name: 'Engineering Physics Lab',
      buildingId: 'loc_sh_block',
      buildingName: 'S&H Block',
      floor: 1,
      category: LocationCategory.academic,
      description: 'Optics, laser diffraction, and semiconductor physics experimental stations for freshmen.',
      operatingHours: '08:00 AM - 05:30 PM',
      tags: ['SH101', 'Physics Lab', 'Optics', 'Freshmen', 'Floor 1'],
    ),
  ];

  // EEE Block Rooms
  static const List<CampusRoom> eeeRooms = [
    CampusRoom(
      id: 'room_eee_001',
      roomCode: 'EEE001',
      name: 'Heavy Electrical Machines Lab',
      buildingId: 'loc_eee_block',
      buildingName: 'EEE Block',
      floor: 0,
      category: LocationCategory.academic,
      description: 'AC/DC motor generator sets, synchronization panels, and dynamometer test beds.',
      operatingHours: '08:00 AM - 05:30 PM',
      tags: ['EEE001', 'Machines Lab', 'Motors', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_eee_301',
      roomCode: 'EEE301',
      name: 'Power Electronics & Drives Lab',
      buildingId: 'loc_eee_block',
      buildingName: 'EEE Block',
      floor: 3,
      category: LocationCategory.academic,
      description: 'Heavy electrical machinery simulation bench, transformer test sets, and inverter development kits.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['EEE301', 'Power Lab', 'Drives', 'Floor 3'],
    ),
  ];

  // EIE Block Rooms
  static const List<CampusRoom> eieRooms = [
    CampusRoom(
      id: 'room_eie_001',
      roomCode: 'EIE001',
      name: 'Process Automation Workshop',
      buildingId: 'loc_eie_block',
      buildingName: 'EIE Block',
      floor: 0,
      category: LocationCategory.academic,
      description: 'Pneumatic and hydraulic control trainers with industrial SCADA workstations.',
      operatingHours: '08:00 AM - 05:00 PM',
      tags: ['EIE001', 'Automation', 'SCADA', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_eie_201',
      roomCode: 'EIE201',
      name: 'Transducers & Instrumentation Lab',
      buildingId: 'loc_eie_block',
      buildingName: 'EIE Block',
      floor: 2,
      category: LocationCategory.academic,
      description: 'Sensor calibration, temperature transducers, and programmable logic controller (PLC) workstations.',
      operatingHours: '08:00 AM - 06:00 PM',
      tags: ['EIE201', 'Sensors', 'PLC', 'Instrumentation', 'Floor 2'],
    ),
  ];

  // Library Rooms
  static const List<CampusRoom> libRooms = [
    CampusRoom(
      id: 'room_lib_001',
      roomCode: 'LIB001',
      name: 'Circulation Desk & Periodicals',
      buildingId: 'loc_library',
      buildingName: 'Library',
      floor: 0,
      category: LocationCategory.library,
      description: 'Book checkout desk, return drop-box, current journals, and daily newspapers.',
      operatingHours: '08:00 AM - 09:00 PM',
      tags: ['LIB001', 'Issue Desk', 'Newspapers', 'Ground Floor'],
    ),
    CampusRoom(
      id: 'room_lib_101',
      roomCode: 'LIB101',
      name: 'Main Reading & Reference Stacks',
      buildingId: 'loc_library',
      buildingName: 'Library',
      floor: 1,
      category: LocationCategory.library,
      description: 'General engineering textbooks, reference volumes, and quiet individual reading tables.',
      operatingHours: '08:00 AM - 09:00 PM',
      tags: ['LIB101', 'Reading Hall', 'Textbooks', 'Floor 1'],
    ),
    CampusRoom(
      id: 'room_lib_201',
      roomCode: 'LIB201',
      name: 'Digital Reference & Quiet Zone',
      buildingId: 'loc_library',
      buildingName: 'Library',
      floor: 2,
      category: LocationCategory.library,
      description: 'Silent research floor featuring online IEEE/ACM catalog terminals and individual study cubicles.',
      operatingHours: '08:00 AM - 09:00 PM',
      isSaved: false,
      tags: ['LIB201', 'Digital Library', 'Quiet Study', 'IEEE', 'Floor 2'],
    ),
  ];

  // Food Court Rooms
  static const List<CampusRoom> foodCourtRooms = [
    CampusRoom(
      id: 'room_fc_101',
      roomCode: 'FC101',
      name: 'Main Dining & Beverage Section',
      buildingId: 'loc_food_court',
      buildingName: 'Food Court',
      floor: 0,
      category: LocationCategory.amenities,
      description: 'Primary cafeteria hall with meal service, juice counters, and indoor dining tables.',
      operatingHours: '07:30 AM - 08:30 PM',
      tags: ['FC101', 'Cafeteria', 'Meals', 'Juice', 'Dining'],
    ),
    CampusRoom(
      id: 'room_fc_102',
      roomCode: 'FC102',
      name: 'Snack Kiosk & Bakery',
      buildingId: 'loc_food_court',
      buildingName: 'Food Court',
      floor: 0,
      category: LocationCategory.amenities,
      description: 'Quick grab-and-go refreshments, hot beverages, and fresh bakery items.',
      operatingHours: '07:30 AM - 07:30 PM',
      tags: ['FC102', 'Bakery', 'Coffee', 'Snacks'],
    ),
  ];

  // Bus Stop Rooms
  static const List<CampusRoom> busStopRooms = [
    CampusRoom(
      id: 'room_bs_001',
      roomCode: 'BS001',
      name: 'Transit Bay 1 (Route Buses)',
      buildingId: 'loc_bus_stop',
      buildingName: 'Bus Stop',
      floor: 0,
      category: LocationCategory.transit,
      description: 'Designated passenger boarding bay for routes 1-15 and inter-campus shuttles.',
      operatingHours: '06:30 AM - 08:00 PM',
      tags: ['BS001', 'Bus Bay', 'Shuttle', 'Transit'],
    ),
  ];

  // IT Park Floor Definitions
  static const List<CampusFloor> itpFloors = [
    CampusFloor(
      floorNumber: 0,
      floorName: 'Ground Floor',
      description:
          'Entrance Foyer, Main Auditorium, Server Room & Technical Support',
      rooms: itpGroundRooms,
    ),
    CampusFloor(
      floorNumber: 1,
      floorName: 'Floor 1',
      description: 'Software Systems Lab, Data Structures Lab & Faculty Cabins',
      rooms: itpFloor1Rooms,
    ),
    CampusFloor(
      floorNumber: 2,
      floorName: 'Floor 2',
      description:
          'Advanced AI Lab, Cloud Computing, Cyber Security & ML Studio',
      rooms: itpFloor2Rooms,
    ),
    CampusFloor(
      floorNumber: 3,
      floorName: 'Floor 3',
      description:
          'IoT & Embedded Systems Lab, Research Cubicles & Incubation Hub',
      rooms: itpFloor3Rooms,
    ),
  ];

  // Campus Locations List with real GPS coordinates for all 11 buildings
  static List<CampusLocation> get initialLocations =>
      List<CampusLocation>.from(CampusLocationData.campusBuildings);

  static List<CampusRoom> get initialRooms => [
    ...itpGroundRooms,
    ...itpFloor1Rooms,
    ...itpFloor2Rooms,
    ...itpFloor3Rooms,
    ...adminRooms,
    ...shRooms,
    ...eeeRooms,
    ...eieRooms,
    ...libRooms,
    ...foodCourtRooms,
    ...busStopRooms,
  ];
}
