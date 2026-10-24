import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/campus_room.dart';
import '../models/location_category.dart';

/// Room data specification for IT Park indoor architectural layout.
class ITParkRoomData {
  final String id;
  final String roomCode;
  final String displayLabel;
  final String name;
  final int floor;
  final Rect bounds;
  final Offset doorPoint;
  final LocationCategory category;
  final String type; // 'classroom', 'lab', 'office', 'restroom', 'stairs', 'entrance', 'dining'
  final String description;
  final List<String> tags;

  const ITParkRoomData({
    required this.id,
    required this.roomCode,
    required this.displayLabel,
    required this.name,
    required this.floor,
    required this.bounds,
    required this.doorPoint,
    this.category = LocationCategory.academic,
    this.type = 'classroom',
    this.description = '',
    this.tags = const [],
  });

  CampusRoom toCampusRoom() {
    return CampusRoom(
      id: id,
      roomCode: roomCode,
      name: name,
      buildingId: 'loc_it_park',
      buildingName: 'IT Park',
      floor: floor,
      category: category,
      description: description.isNotEmpty
          ? description
          : '$name on Floor $floor of IT Park.',
      operatingHours: type == 'restroom' || type == 'stairs'
          ? '24 Hours'
          : '08:00 AM - 06:00 PM',
      tags: [roomCode, displayLabel, ...tags, 'Floor $floor'],
    );
  }
}

/// Architectural corridor node for IT Park navigation.
class ITParkCorridorNode {
  final String id;
  final Offset position;
  final List<String> connectedIds;

  const ITParkCorridorNode({
    required this.id,
    required this.position,
    required this.connectedIds,
  });
}

/// Static repository containing full floor plans, room metrics, and corridor graphs
/// for IT Park Ground Floor, First Floor, and Second Floor.
class ITParkLayoutData {
  static const double canvasWidth = 840.0;
  static const double canvasHeight = 720.0;

  // Corridor Centerline Coordinates
  static const double northCorridorY = 205.0;
  static const double southCorridorY = 515.0;
  static const double westCorridorX = 195.0;
  static const double eastCorridorX = 645.0;

  // Staircase (Steps) location shared across all floors
  static const Rect stairsRect = Rect.fromLTWH(375, 235, 90, 70);
  static const Offset stairsDoorPoint = Offset(420, 205);

  // Ground Floor Entrance
  static const Rect groundEntranceRect = Rect.fromLTWH(330, 80, 180, 95);
  static const Offset groundEntrancePoint = Offset(420, 140);

  // -------------------------------------------------------------
  // GROUND FLOOR ROOMS (001 - 024)
  // -------------------------------------------------------------
  static final List<ITParkRoomData> groundFloorRooms = [
    // Outer North Wing
    const ITParkRoomData(
      id: 'room_itp_001',
      roomCode: '001',
      displayLabel: '001',
      name: 'Room 001 - Tech Research Lab',
      floor: 0,
      bounds: Rect.fromLTWH(50, 80, 100, 95),
      doorPoint: Offset(100, northCorridorY),
      type: 'lab',
      description: 'Advanced Systems Research & Hardware Interfacing Laboratory.',
      tags: ['001', 'ITP001', 'Research', 'Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_002',
      roomCode: '002',
      displayLabel: '002',
      name: 'Room 002 - Tech Auditorium',
      floor: 0,
      bounds: Rect.fromLTWH(150, 80, 140, 95),
      doorPoint: Offset(220, northCorridorY),
      type: 'classroom',
      description: 'Department seminar hall & guest lecture presentation hall.',
      tags: ['002', 'ITP002', 'Auditorium', 'Seminar'],
    ),
    const ITParkRoomData(
      id: 'room_itp_000_entrance',
      roomCode: 'Entrance',
      displayLabel: 'Entrance',
      name: 'Main Building Entrance & Lobby',
      floor: 0,
      bounds: groundEntranceRect,
      doorPoint: groundEntrancePoint,
      type: 'entrance',
      category: LocationCategory.amenities,
      description: 'Primary North entrance foyer and visitor reception desk.',
      tags: ['Entrance', 'Main Entrance', 'Foyer', 'Lobby'],
    ),
    const ITParkRoomData(
      id: 'room_itp_003',
      roomCode: '003',
      displayLabel: '003',
      name: 'Room 003 - Server Center',
      floor: 0,
      bounds: Rect.fromLTWH(550, 80, 75, 95),
      doorPoint: Offset(585, northCorridorY),
      type: 'lab',
      description: 'Central IT infrastructure racks and high-speed switches.',
      tags: ['003', 'ITP003', 'Server', 'Networking'],
    ),
    const ITParkRoomData(
      id: 'room_itp_004',
      roomCode: '004',
      displayLabel: '004',
      name: 'Room 004 - Hardware Support',
      floor: 0,
      bounds: Rect.fromLTWH(625, 80, 75, 95),
      doorPoint: Offset(645, northCorridorY),
      type: 'office',
      description: 'Desktop repair, peripherals storage, and tech technician hub.',
      tags: ['004', 'ITP004', 'Hardware', 'Support'],
    ),
    const ITParkRoomData(
      id: 'room_itp_005',
      roomCode: '005',
      displayLabel: '005',
      name: 'Room 005 - Seminar Hall',
      floor: 0,
      bounds: Rect.fromLTWH(700, 80, 90, 95),
      doorPoint: Offset(700, northCorridorY),
      type: 'classroom',
      description: 'Faculty briefing hall and multimedia presentation space.',
      tags: ['005', 'ITP005', 'Seminar', 'Classroom'],
    ),

    // Outer East Wing
    const ITParkRoomData(
      id: 'room_itp_006',
      roomCode: '006',
      displayLabel: '006',
      name: 'Room 006 - Project Workspace',
      floor: 0,
      bounds: Rect.fromLTWH(675, 175, 115, 185),
      doorPoint: Offset(eastCorridorX, 265),
      type: 'lab',
      description: 'Undergraduate student capstone project work bays.',
      tags: ['006', 'ITP006', 'Project Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_007',
      roomCode: '007',
      displayLabel: '007',
      name: 'Room 007 - Electronics Testing Hub',
      floor: 0,
      bounds: Rect.fromLTWH(675, 360, 115, 185),
      doorPoint: Offset(eastCorridorX, 450),
      type: 'lab',
      description: 'Oscilloscopes, soldering benches, and signal generators.',
      tags: ['007', 'ITP007', 'Testing', 'Electronics'],
    ),

    // Outer South Wing
    const ITParkRoomData(
      id: 'room_itp_000_gr',
      roomCode: 'GR',
      displayLabel: 'Girls Restroom',
      name: 'Girls Restroom (Ground)',
      floor: 0,
      bounds: Rect.fromLTWH(665, 545, 125, 95),
      doorPoint: Offset(700, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Female restroom facilities with accessible amenities.',
      tags: ['GR', 'Girls Restroom', 'Washroom', 'Restroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_009',
      roomCode: '009',
      displayLabel: '009',
      name: 'Room 009 - Tutorial Hall',
      floor: 0,
      bounds: Rect.fromLTWH(565, 545, 100, 95),
      doorPoint: Offset(615, southCorridorY),
      type: 'classroom',
      description: 'Section tutorial discussions and student remedial sessions.',
      tags: ['009', 'ITP009', 'Tutorial'],
    ),
    const ITParkRoomData(
      id: 'room_itp_010',
      roomCode: '010',
      displayLabel: '010',
      name: 'Room 010 - Smart Classroom',
      floor: 0,
      bounds: Rect.fromLTWH(455, 545, 110, 95),
      doorPoint: Offset(510, southCorridorY),
      type: 'classroom',
      description: 'Smart board equipped interactive classroom.',
      tags: ['010', 'ITP010', 'Smart Classroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_011',
      roomCode: '011',
      displayLabel: '011',
      name: 'Room 011 - Lecture Room',
      floor: 0,
      bounds: Rect.fromLTWH(345, 545, 110, 95),
      doorPoint: Offset(400, southCorridorY),
      type: 'classroom',
      description: 'Tiered lecture classroom for undergraduate courses.',
      tags: ['011', 'ITP011', 'Lecture Room'],
    ),
    const ITParkRoomData(
      id: 'room_itp_012',
      roomCode: '012',
      displayLabel: '012',
      name: 'Room 012 - Coding Studio',
      floor: 0,
      bounds: Rect.fromLTWH(235, 545, 110, 95),
      doorPoint: Offset(290, southCorridorY),
      type: 'lab',
      description: 'Dual monitor developer rigs for competitive programming.',
      tags: ['012', 'ITP012', 'Coding Studio'],
    ),
    const ITParkRoomData(
      id: 'room_itp_013',
      roomCode: '013',
      displayLabel: '013',
      name: 'Room 013 - Discussion Room',
      floor: 0,
      bounds: Rect.fromLTWH(155, 545, 80, 95),
      doorPoint: Offset(195, southCorridorY),
      type: 'classroom',
      description: 'Roundtable discussions and peer study room.',
      tags: ['013', 'ITP013', 'Discussion'],
    ),
    const ITParkRoomData(
      id: 'room_itp_000_br',
      roomCode: 'BR',
      displayLabel: 'Boys Restroom',
      name: 'Boys Restroom (Ground)',
      floor: 0,
      bounds: Rect.fromLTWH(50, 545, 105, 95),
      doorPoint: Offset(120, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Male restroom facilities and sanitation station.',
      tags: ['BR', 'Boys Restroom', 'Washroom', 'Restroom'],
    ),

    // Outer West Wing
    const ITParkRoomData(
      id: 'room_itp_015',
      roomCode: '015',
      displayLabel: '015',
      name: 'Room 015 - Robotics Studio',
      floor: 0,
      bounds: Rect.fromLTWH(50, 360, 115, 185),
      doorPoint: Offset(westCorridorX, 450),
      type: 'lab',
      description: 'Autonomous robotics testbed and microcontroller fabrication.',
      tags: ['015', 'ITP015', 'Robotics'],
    ),
    const ITParkRoomData(
      id: 'room_itp_016',
      roomCode: '016',
      displayLabel: '016',
      name: 'Room 016 - Innovation Hub',
      floor: 0,
      bounds: Rect.fromLTWH(50, 175, 115, 185),
      doorPoint: Offset(westCorridorX, 265),
      type: 'lab',
      description: 'Startup incubator space and prototyping station.',
      tags: ['016', 'ITP016', 'Innovation'],
    ),

    // Inner Island North & Steps
    const ITParkRoomData(
      id: 'room_itp_017',
      roomCode: '017',
      displayLabel: '017',
      name: 'Room 017 - Department Office',
      floor: 0,
      bounds: Rect.fromLTWH(230, 235, 70, 70),
      doorPoint: Offset(265, northCorridorY),
      type: 'office',
      description: 'Student records, exam coordination, and administrative desk.',
      tags: ['017', 'ITP017', 'Office'],
    ),
    const ITParkRoomData(
      id: 'room_itp_018',
      roomCode: '018',
      displayLabel: '018',
      name: 'Room 018 - Staff Room',
      floor: 0,
      bounds: Rect.fromLTWH(300, 235, 75, 70),
      doorPoint: Offset(335, northCorridorY),
      type: 'office',
      description: 'Assistant professors and teaching assistants work chambers.',
      tags: ['018', 'ITP018', 'Staff Room'],
    ),
    const ITParkRoomData(
      id: 'room_itp_steps_0',
      roomCode: 'Steps',
      displayLabel: 'Staircase',
      name: 'Central Staircase (Steps)',
      floor: 0,
      bounds: stairsRect,
      doorPoint: stairsDoorPoint,
      type: 'stairs',
      category: LocationCategory.amenities,
      description: 'Main central stairwell connecting Ground, Floor 1, and Floor 2.',
      tags: ['Steps', 'Stairs', 'Staircase', 'Elevator'],
    ),
    const ITParkRoomData(
      id: 'room_itp_019',
      roomCode: '019',
      displayLabel: '019',
      name: 'Room 019 - Counseling Cell',
      floor: 0,
      bounds: Rect.fromLTWH(465, 235, 85, 70),
      doorPoint: Offset(500, northCorridorY),
      type: 'office',
      description: 'Academic advisor and student mentorship cabin.',
      tags: ['019', 'ITP019', 'Counseling', 'Office'],
    ),

    // Inner Island South (020 - 024)
    const ITParkRoomData(
      id: 'room_itp_024',
      roomCode: '024',
      displayLabel: '024',
      name: 'Room 024 - Faculty Cabin',
      floor: 0,
      bounds: Rect.fromLTWH(230, 415, 75, 70),
      doorPoint: Offset(265, southCorridorY),
      type: 'office',
      description: 'Faculty research and consultation room.',
      tags: ['024', 'ITP024', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_023',
      roomCode: '023',
      displayLabel: '023',
      name: 'Room 023 - Research Cubicle',
      floor: 0,
      bounds: Rect.fromLTWH(305, 415, 75, 70),
      doorPoint: Offset(340, southCorridorY),
      type: 'office',
      description: 'PhD scholar workspace and research station.',
      tags: ['023', 'ITP023', 'Research'],
    ),
    const ITParkRoomData(
      id: 'room_itp_022',
      roomCode: '022',
      displayLabel: '022',
      name: 'Room 022 - Project Lab B',
      floor: 0,
      bounds: Rect.fromLTWH(380, 415, 75, 70),
      doorPoint: Offset(420, southCorridorY),
      type: 'lab',
      description: 'Software development and app testing workspace.',
      tags: ['022', 'ITP022', 'Project Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_021',
      roomCode: '021',
      displayLabel: '021',
      name: 'Room 021 - Faculty Cabin',
      floor: 0,
      bounds: Rect.fromLTWH(455, 415, 75, 70),
      doorPoint: Offset(490, southCorridorY),
      type: 'office',
      description: 'Associate Professor consultation chamber.',
      tags: ['021', 'ITP021', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_020',
      roomCode: '020',
      displayLabel: '020',
      name: 'Room 020 - Meeting Room',
      floor: 0,
      bounds: Rect.fromLTWH(530, 415, 80, 70),
      doorPoint: Offset(570, southCorridorY),
      type: 'office',
      description: 'Department meeting and internal review room.',
      tags: ['020', 'ITP020', 'Meeting'],
    ),
  ];

  // -------------------------------------------------------------
  // FIRST FLOOR ROOMS (101 - 128 / CC1 - CC8)
  // -------------------------------------------------------------
  static final List<ITParkRoomData> firstFloorRooms = [
    // Outer North
    const ITParkRoomData(
      id: 'room_itp_cc8',
      roomCode: 'CC8',
      displayLabel: 'CC8',
      name: 'CC8 - Computer Center 8',
      floor: 1,
      bounds: Rect.fromLTWH(50, 80, 180, 95),
      doorPoint: Offset(140, northCorridorY),
      type: 'lab',
      description: 'Full-stack development lab with dedicated virtual machines.',
      tags: ['CC8', '108', 'ITP108', 'Computer Center', 'Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_103_lib',
      roomCode: '103',
      displayLabel: '103 ITP Lib',
      name: '103 - IT Park Digital Library',
      floor: 1,
      bounds: Rect.fromLTWH(230, 80, 310, 95),
      doorPoint: Offset(385, northCorridorY),
      type: 'lab',
      category: LocationCategory.library,
      description: 'Specialized departmental digital library, IEEE journals, and quiet study room.',
      tags: ['103', 'ITP Lib', 'Library', 'ITP103', 'Digital Library'],
    ),
    const ITParkRoomData(
      id: 'room_itp_106',
      roomCode: '106',
      displayLabel: '106',
      name: 'Room 106 - Classroom',
      floor: 1,
      bounds: Rect.fromLTWH(540, 80, 110, 95),
      doorPoint: Offset(595, northCorridorY),
      type: 'classroom',
      description: 'Smart classroom for upper-level theory coursework.',
      tags: ['106', 'ITP106', 'Classroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_107',
      roomCode: '107',
      displayLabel: '107',
      name: 'Room 107 - Classroom',
      floor: 1,
      bounds: Rect.fromLTWH(650, 80, 140, 95),
      doorPoint: Offset(710, northCorridorY),
      type: 'classroom',
      description: 'Interactive lecture hall with digital podium.',
      tags: ['107', 'ITP107', 'Classroom'],
    ),

    // Outer East Wing
    const ITParkRoomData(
      id: 'room_itp_cc6',
      roomCode: 'CC6',
      displayLabel: 'CC6',
      name: 'CC6 - Computer Center 6',
      floor: 1,
      bounds: Rect.fromLTWH(675, 175, 115, 185),
      doorPoint: Offset(eastCorridorX, 265),
      type: 'lab',
      description: 'Operating Systems & System Programming computer lab.',
      tags: ['CC6', '106', 'Lab', 'Operating Systems'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc5',
      roomCode: 'CC5',
      displayLabel: 'CC5',
      name: 'CC5 - Computer Center 5',
      floor: 1,
      bounds: Rect.fromLTWH(675, 360, 115, 185),
      doorPoint: Offset(eastCorridorX, 450),
      type: 'lab',
      description: 'Database Systems & Data Warehousing computer lab.',
      tags: ['CC5', '105', 'Lab', 'Databases'],
    ),

    // Outer South Wing
    const ITParkRoomData(
      id: 'room_itp_1_gr',
      roomCode: 'GR',
      displayLabel: 'Girls Restroom',
      name: 'Girls Restroom (Floor 1)',
      floor: 1,
      bounds: Rect.fromLTWH(675, 545, 115, 95),
      doorPoint: Offset(700, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Floor 1 female restroom facilities.',
      tags: ['GR', 'Girls Restroom', 'Washroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc4',
      roomCode: 'CC4',
      displayLabel: 'CC4',
      name: 'CC4 - Computer Center 4',
      floor: 1,
      bounds: Rect.fromLTWH(540, 545, 135, 95),
      doorPoint: Offset(605, southCorridorY),
      type: 'lab',
      description: 'Algorithms & Competitive Programming computer center.',
      tags: ['CC4', '104', 'Lab', 'Algorithms'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc3',
      roomCode: 'CC3',
      displayLabel: 'CC3',
      name: 'CC3 - Computer Center 3',
      floor: 1,
      bounds: Rect.fromLTWH(410, 545, 130, 95),
      doorPoint: Offset(475, southCorridorY),
      type: 'lab',
      description: 'Object Oriented Software Engineering laboratory.',
      tags: ['CC3', '103', 'Lab', 'Java'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc2',
      roomCode: 'CC2',
      displayLabel: 'CC2',
      name: 'CC2 - Computer Center 2',
      floor: 1,
      bounds: Rect.fromLTWH(280, 545, 130, 95),
      doorPoint: Offset(345, southCorridorY),
      type: 'lab',
      description: 'Data Structures laboratory with Linux workstation rigs.',
      tags: ['CC2', '102', 'Lab', 'Data Structures'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc1',
      roomCode: 'CC1',
      displayLabel: 'CC1',
      name: 'CC1 - Computer Center 1',
      floor: 1,
      bounds: Rect.fromLTWH(150, 545, 130, 95),
      doorPoint: Offset(215, southCorridorY),
      type: 'lab',
      description: 'Foundations of Computing & Python programming lab.',
      tags: ['CC1', '101', 'ITP101', 'Lab', 'Python'],
    ),
    const ITParkRoomData(
      id: 'room_itp_1_br',
      roomCode: 'BR',
      displayLabel: 'Boys Restroom',
      name: 'Boys Restroom (Floor 1)',
      floor: 1,
      bounds: Rect.fromLTWH(50, 545, 100, 95),
      doorPoint: Offset(100, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Floor 1 male restroom facilities.',
      tags: ['BR', 'Boys Restroom', 'Washroom'],
    ),

    // Outer West Wing
    const ITParkRoomData(
      id: 'room_itp_119',
      roomCode: '119',
      displayLabel: '119',
      name: 'Room 119 - Faculty Room',
      floor: 1,
      bounds: Rect.fromLTWH(50, 440, 115, 105),
      doorPoint: Offset(westCorridorX, 490),
      type: 'office',
      description: 'Senior Professor chambers and student mentorship.',
      tags: ['119', 'ITP119', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_120',
      roomCode: '120',
      displayLabel: '120 Lab',
      name: 'Room 120 - Advanced Software Lab',
      floor: 1,
      bounds: Rect.fromLTWH(50, 260, 115, 180),
      doorPoint: Offset(westCorridorX, 350),
      type: 'lab',
      description: 'Software testing, CI/CD pipelines, and cloud sandbox workstations.',
      tags: ['120', 'ITP120', 'Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_121',
      roomCode: '121',
      displayLabel: '121',
      name: 'Room 121 - HOD Cabin',
      floor: 1,
      bounds: Rect.fromLTWH(50, 175, 115, 85),
      doorPoint: Offset(westCorridorX, 215),
      type: 'office',
      description: 'Head of Computer Science & Engineering department office.',
      tags: ['121', 'ITP121', 'HOD', 'Office'],
    ),

    // Inner Island North & Steps
    const ITParkRoomData(
      id: 'room_itp_cc7',
      roomCode: 'CC7',
      displayLabel: 'CC7',
      name: 'CC7 - Computer Center 7',
      floor: 1,
      bounds: Rect.fromLTWH(230, 235, 145, 70),
      doorPoint: Offset(300, northCorridorY),
      type: 'lab',
      description: 'Cybersecurity & Network penetration testing lab.',
      tags: ['CC7', '122', 'Security', 'Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_steps_1',
      roomCode: 'Steps',
      displayLabel: 'Staircase',
      name: 'Central Staircase (Floor 1)',
      floor: 1,
      bounds: stairsRect,
      doorPoint: stairsDoorPoint,
      type: 'stairs',
      category: LocationCategory.amenities,
      description: 'Main central stairwell connecting Ground, Floor 1, and Floor 2.',
      tags: ['Steps', 'Stairs', 'Staircase'],
    ),
    const ITParkRoomData(
      id: 'room_itp_125',
      roomCode: '125',
      displayLabel: 'ITP 125',
      name: 'Room 125 - Network Operations Lab',
      floor: 1,
      bounds: Rect.fromLTWH(465, 235, 145, 70),
      doorPoint: Offset(535, northCorridorY),
      type: 'lab',
      description: 'Campus internet routing monitors and network telemetry.',
      tags: ['125', 'ITP125', 'Network'],
    ),

    // Inner Island South
    const ITParkRoomData(
      id: 'room_itp_124',
      roomCode: '124',
      displayLabel: '124',
      name: 'Room 124 - Research Cabin',
      floor: 1,
      bounds: Rect.fromLTWH(230, 415, 95, 70),
      doorPoint: Offset(275, southCorridorY),
      type: 'office',
      description: 'Postdoctoral fellow and research associate chamber.',
      tags: ['124', 'ITP124', 'Research'],
    ),
    const ITParkRoomData(
      id: 'room_itp_126',
      roomCode: '126',
      displayLabel: '126',
      name: 'Room 126 - Seminar Suite',
      floor: 1,
      bounds: Rect.fromLTWH(410, 415, 100, 70),
      doorPoint: Offset(460, southCorridorY),
      type: 'classroom',
      description: 'Small group interactive seminar presentation suite.',
      tags: ['126', 'ITP126', 'Seminar'],
    ),
    const ITParkRoomData(
      id: 'room_itp_128',
      roomCode: '128',
      displayLabel: '128',
      name: 'Room 128 - Department Conference Room',
      floor: 1,
      bounds: Rect.fromLTWH(510, 415, 100, 70),
      doorPoint: Offset(560, southCorridorY),
      type: 'office',
      description: 'Faculty board meeting and doctoral defense presentation room.',
      tags: ['128', 'ITP128', 'Conference'],
    ),
  ];

  // -------------------------------------------------------------
  // SECOND FLOOR ROOMS (201 - 228 / CC16)
  // -------------------------------------------------------------
  static final List<ITParkRoomData> secondFloorRooms = [
    // Outer North
    const ITParkRoomData(
      id: 'room_itp_201',
      roomCode: 'ITP201',
      displayLabel: '201',
      name: 'Advanced Computing & AI Lab',
      floor: 2,
      bounds: Rect.fromLTWH(50, 80, 80, 95),
      doorPoint: Offset(90, northCorridorY),
      type: 'lab',
      description: 'High-performance computing laboratory with GPU clusters for deep learning.',
      tags: ['201', 'ITP201', 'AI Lab', 'GPU Cluster', 'Coding Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_202',
      roomCode: '202',
      displayLabel: '202',
      name: 'Room 202 - Cloud Computing Lab',
      floor: 2,
      bounds: Rect.fromLTWH(130, 80, 75, 95),
      doorPoint: Offset(165, northCorridorY),
      type: 'lab',
      description: 'Kubernetes orchestration and distributed systems laboratory.',
      tags: ['202', 'ITP202', 'Cloud Lab', 'DevOps'],
    ),
    const ITParkRoomData(
      id: 'room_itp_203',
      roomCode: '203',
      displayLabel: '203',
      name: 'Room 203 - Cyber Security Lab',
      floor: 2,
      bounds: Rect.fromLTWH(205, 80, 75, 95),
      doorPoint: Offset(240, northCorridorY),
      type: 'lab',
      description: 'Network forensics and ethical hacking testing ground.',
      tags: ['203', 'ITP203', 'Security', 'Forensics'],
    ),
    const ITParkRoomData(
      id: 'room_itp_cc16',
      roomCode: 'CC16',
      displayLabel: 'CC16',
      name: 'CC16 - Supercomputing Center',
      floor: 2,
      bounds: Rect.fromLTWH(280, 80, 240, 95),
      doorPoint: Offset(400, northCorridorY),
      type: 'lab',
      description: 'Large computing center housing cluster workstations for data science & AI.',
      tags: ['CC16', '204', 'Supercomputing', 'Lab', 'AI'],
    ),
    const ITParkRoomData(
      id: 'room_itp_205',
      roomCode: '205',
      displayLabel: '205',
      name: 'Room 205 - Embedded IoT Lab',
      floor: 2,
      bounds: Rect.fromLTWH(520, 80, 80, 95),
      doorPoint: Offset(560, northCorridorY),
      type: 'lab',
      description: 'Microcontroller design and smart sensor integration.',
      tags: ['205', 'ITP205', 'IoT', 'Embedded'],
    ),
    const ITParkRoomData(
      id: 'room_itp_206',
      roomCode: '206',
      displayLabel: '206 FC',
      name: 'Room 206 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(600, 80, 80, 95),
      doorPoint: Offset(640, northCorridorY),
      type: 'office',
      description: 'Faculty cabin for research consultations.',
      tags: ['206', 'ITP206', 'Faculty Cabin', 'FC'],
    ),
    const ITParkRoomData(
      id: 'room_itp_207',
      roomCode: '207',
      displayLabel: '207 FC',
      name: 'Room 207 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(680, 80, 110, 95),
      doorPoint: Offset(710, northCorridorY),
      type: 'office',
      description: 'Faculty cabin for academic mentoring.',
      tags: ['207', 'ITP207', 'Faculty Cabin', 'FC'],
    ),

    // Outer East Wing
    const ITParkRoomData(
      id: 'room_itp_208',
      roomCode: '208',
      displayLabel: '208 FC',
      name: 'Room 208 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(675, 175, 115, 120),
      doorPoint: Offset(eastCorridorX, 235),
      type: 'office',
      description: 'Senior Professor research cabin.',
      tags: ['208', 'ITP208', 'Faculty Cabin', 'FC'],
    ),
    const ITParkRoomData(
      id: 'room_itp_209',
      roomCode: '209',
      displayLabel: '209',
      name: 'Room 209 - Smart Classroom',
      floor: 2,
      bounds: Rect.fromLTWH(675, 295, 115, 125),
      doorPoint: Offset(eastCorridorX, 360),
      type: 'classroom',
      description: 'Multimedia classroom for postgraduate instruction.',
      tags: ['209', 'ITP209', 'Classroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_210',
      roomCode: '210',
      displayLabel: '210',
      name: 'Room 210 - Discussion Suite',
      floor: 2,
      bounds: Rect.fromLTWH(675, 420, 115, 125),
      doorPoint: Offset(eastCorridorX, 480),
      type: 'classroom',
      description: 'Graduate student collaborative research space.',
      tags: ['210', 'ITP210', 'Discussion'],
    ),

    // Outer South Wing
    const ITParkRoomData(
      id: 'room_itp_211_gr',
      roomCode: '211',
      displayLabel: 'GR 211',
      name: 'Room 211 - Girls Restroom',
      floor: 2,
      bounds: Rect.fromLTWH(675, 545, 115, 95),
      doorPoint: Offset(710, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Floor 2 female restroom facilities.',
      tags: ['211', 'GR', 'Girls Restroom', 'Washroom'],
    ),
    const ITParkRoomData(
      id: 'room_itp_212',
      roomCode: '212',
      displayLabel: '212',
      name: 'Room 212 - Lecture Hall',
      floor: 2,
      bounds: Rect.fromLTWH(585, 545, 90, 95),
      doorPoint: Offset(630, southCorridorY),
      type: 'classroom',
      description: 'Tiered classroom for theory lectures.',
      tags: ['212', 'ITP212', 'Lecture Hall'],
    ),
    const ITParkRoomData(
      id: 'room_itp_213',
      roomCode: '213',
      displayLabel: '213',
      name: 'Room 213 - Machine Learning Studio',
      floor: 2,
      bounds: Rect.fromLTWH(490, 545, 95, 95),
      doorPoint: Offset(540, southCorridorY),
      type: 'lab',
      description: 'Collaborative ML project workbench station.',
      tags: ['213', 'ITP213', 'ML Studio', 'Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_214',
      roomCode: '214',
      displayLabel: '214',
      name: 'Room 214 - Natural Language Lab',
      floor: 2,
      bounds: Rect.fromLTWH(385, 545, 105, 95),
      doorPoint: Offset(440, southCorridorY),
      type: 'lab',
      description: 'Computational linguistics and generative AI studio.',
      tags: ['214', 'ITP214', 'NLP', 'AI Lab'],
    ),
    const ITParkRoomData(
      id: 'room_itp_215',
      roomCode: '215',
      displayLabel: '215',
      name: 'Room 215 - Computer Vision Lab',
      floor: 2,
      bounds: Rect.fromLTWH(280, 545, 105, 95),
      doorPoint: Offset(335, southCorridorY),
      type: 'lab',
      description: 'Image processing and video analytics research benches.',
      tags: ['215', 'ITP215', 'Vision Lab', 'AI'],
    ),
    const ITParkRoomData(
      id: 'room_itp_216',
      roomCode: '216',
      displayLabel: '216 FC',
      name: 'Room 216 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(180, 545, 100, 95),
      doorPoint: Offset(230, southCorridorY),
      type: 'office',
      description: 'AI & Data Science faculty chambers.',
      tags: ['216', 'ITP216', 'Faculty Cabin', 'FC'],
    ),
    const ITParkRoomData(
      id: 'room_itp_217_br',
      roomCode: '217',
      displayLabel: 'B.R 217',
      name: 'Room 217 - Boys Restroom',
      floor: 2,
      bounds: Rect.fromLTWH(50, 545, 130, 95),
      doorPoint: Offset(115, southCorridorY),
      type: 'restroom',
      category: LocationCategory.amenities,
      description: 'Floor 2 male restroom facilities.',
      tags: ['217', 'BR', 'Boys Restroom', 'Washroom'],
    ),

    // Outer West Wing
    const ITParkRoomData(
      id: 'room_itp_218',
      roomCode: '218',
      displayLabel: '218',
      name: 'Room 218 - Project Incubation',
      floor: 2,
      bounds: Rect.fromLTWH(50, 440, 115, 105),
      doorPoint: Offset(westCorridorX, 490),
      type: 'lab',
      description: 'Pre-incubation space for commercial student ventures.',
      tags: ['218', 'ITP218', 'Incubation'],
    ),
    const ITParkRoomData(
      id: 'room_itp_dining',
      roomCode: 'Dining',
      displayLabel: 'Dining Hall',
      name: 'Faculty & Student Dining Hall',
      floor: 2,
      bounds: Rect.fromLTWH(50, 260, 115, 180),
      doorPoint: Offset(westCorridorX, 350),
      type: 'dining',
      category: LocationCategory.amenities,
      description: 'Pantry, dining tables, coffee dispenser, and water station.',
      tags: ['Dining', 'Dining hall', 'Cafeteria', 'Food'],
    ),
    const ITParkRoomData(
      id: 'room_itp_219',
      roomCode: '219',
      displayLabel: '219',
      name: 'Room 219 - Innovation Studio',
      floor: 2,
      bounds: Rect.fromLTWH(50, 175, 115, 85),
      doorPoint: Offset(westCorridorX, 215),
      type: 'lab',
      description: 'Collaborative brainstorming and whiteboard studio.',
      tags: ['219', 'ITP219', 'Studio'],
    ),

    // Inner Island North & Steps
    const ITParkRoomData(
      id: 'room_itp_220',
      roomCode: '220',
      displayLabel: '220',
      name: 'Room 220 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(230, 235, 70, 70),
      doorPoint: Offset(265, northCorridorY),
      type: 'office',
      description: 'Consultation cabin for IT department professors.',
      tags: ['220', 'ITP220', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_221',
      roomCode: '221',
      displayLabel: '221',
      name: 'Room 221 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(300, 235, 75, 70),
      doorPoint: Offset(335, northCorridorY),
      type: 'office',
      description: 'Faculty cabin for software engineering professors.',
      tags: ['221', 'ITP221', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_steps_2',
      roomCode: 'Steps',
      displayLabel: 'Staircase',
      name: 'Central Staircase (Floor 2)',
      floor: 2,
      bounds: stairsRect,
      doorPoint: stairsDoorPoint,
      type: 'stairs',
      category: LocationCategory.amenities,
      description: 'Main central stairwell connecting Ground, Floor 1, and Floor 2.',
      tags: ['Steps', 'Stairs', 'Staircase'],
    ),
    const ITParkRoomData(
      id: 'room_itp_222',
      roomCode: '222',
      displayLabel: '222',
      name: 'Room 222 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(465, 235, 70, 70),
      doorPoint: Offset(500, northCorridorY),
      type: 'office',
      description: 'Faculty cabin for algorithms professors.',
      tags: ['222', 'ITP222', 'Faculty'],
    ),
    const ITParkRoomData(
      id: 'room_itp_223',
      roomCode: '223',
      displayLabel: '223',
      name: 'Room 223 - Faculty Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(535, 235, 75, 70),
      doorPoint: Offset(570, northCorridorY),
      type: 'office',
      description: 'Faculty cabin for cloud computing professors.',
      tags: ['223', 'ITP223', 'Faculty'],
    ),

    // Inner Island South (224 - 228)
    const ITParkRoomData(
      id: 'room_itp_228',
      roomCode: '228',
      displayLabel: '228',
      name: 'Room 228 - Research Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(230, 415, 65, 70),
      doorPoint: Offset(260, southCorridorY),
      type: 'office',
      description: 'Doctoral researcher desk and workspace.',
      tags: ['228', 'ITP228', 'Research'],
    ),
    const ITParkRoomData(
      id: 'room_itp_227',
      roomCode: '227',
      displayLabel: '227',
      name: 'Room 227 - Research Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(295, 415, 65, 70),
      doorPoint: Offset(325, southCorridorY),
      type: 'office',
      description: 'Postgraduate research cubicle.',
      tags: ['227', 'ITP227', 'Research'],
    ),
    const ITParkRoomData(
      id: 'room_itp_226',
      roomCode: '226',
      displayLabel: '226',
      name: 'Room 226 - AI Project Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(360, 415, 80, 70),
      doorPoint: Offset(400, southCorridorY),
      type: 'lab',
      description: 'AI hardware kit and drone programming workshop.',
      tags: ['226', 'ITP226', 'Project'],
    ),
    const ITParkRoomData(
      id: 'room_itp_225',
      roomCode: '225',
      displayLabel: '225',
      name: 'Room 225 - Scholar Cabin',
      floor: 2,
      bounds: Rect.fromLTWH(440, 415, 80, 70),
      doorPoint: Offset(480, southCorridorY),
      type: 'office',
      description: 'Visiting scholar and research associate office.',
      tags: ['225', 'ITP225', 'Scholar'],
    ),
    const ITParkRoomData(
      id: 'room_itp_224',
      roomCode: '224',
      displayLabel: '224',
      name: 'Room 224 - Staff Discussion Room',
      floor: 2,
      bounds: Rect.fromLTWH(520, 415, 90, 70),
      doorPoint: Offset(565, southCorridorY),
      type: 'office',
      description: 'Faculty briefing and curriculum planning room.',
      tags: ['224', 'ITP224', 'Discussion'],
    ),
  ];

  /// Get rooms for a given floor number (0, 1, or 2).
  static List<ITParkRoomData> getRoomsForFloor(int floorNumber) {
    switch (floorNumber) {
      case 0:
        return groundFloorRooms;
      case 1:
        return firstFloorRooms;
      case 2:
        return secondFloorRooms;
      default:
        return groundFloorRooms;
    }
  }

  /// Returns all rooms converted to [CampusRoom] model objects across Ground, 1st and 2nd floors.
  static List<CampusRoom> get allCampusRooms => [
    ...groundFloorRooms.map((r) => r.toCampusRoom()),
    ...firstFloorRooms.map((r) => r.toCampusRoom()),
    ...secondFloorRooms.map((r) => r.toCampusRoom()),
  ];

  /// Searches all floors for matching rooms by code, label, or name.
  static List<ITParkRoomData> searchRooms(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];
    final cleanNumeric = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');

    final all = [...groundFloorRooms, ...firstFloorRooms, ...secondFloorRooms];
    return all.where((room) {
      final codeLower = room.roomCode.toLowerCase();
      final labelLower = room.displayLabel.toLowerCase();
      final nameLower = room.name.toLowerCase();

      final matchesQuery = codeLower.contains(cleanQuery) ||
          labelLower.contains(cleanQuery) ||
          nameLower.contains(cleanQuery) ||
          room.tags.any((tag) => tag.toLowerCase().contains(cleanQuery));

      final matchesNumeric = cleanNumeric.isNotEmpty &&
          (codeLower.contains(cleanNumeric) || labelLower.contains(cleanNumeric));

      return matchesQuery || matchesNumeric;
    }).toList();
  }

  /// Finds a room by its code (e.g. "001", "103", "128", "203", "227", "ITP201", "CC16").
  static ITParkRoomData? findRoomByCode(String code) {
    final clean = code.trim().toLowerCase();
    final cleanNumeric = clean.replaceAll(RegExp(r'[^0-9]'), '');
    final all = [...groundFloorRooms, ...firstFloorRooms, ...secondFloorRooms];

    for (final room in all) {
      final codeLower = room.roomCode.toLowerCase();
      final labelLower = room.displayLabel.toLowerCase();

      if (codeLower == clean ||
          labelLower == clean ||
          room.id.toLowerCase() == clean ||
          codeLower.replaceAll('itp', '') == clean ||
          (cleanNumeric.isNotEmpty &&
              (codeLower.replaceAll('itp', '') == cleanNumeric ||
                  labelLower == cleanNumeric)) ||
          room.tags.any((t) => t.toLowerCase() == clean)) {
        return room;
      }
    }
    return null;
  }

  // -------------------------------------------------------------
  // CORRIDOR PATHFINDING (Orthogonal Corridor Routing)
  // -------------------------------------------------------------
  /// Computes a clean orthogonal route from [startPoint] to [endPoint]
  /// strictly through the hallway corridors.
  static List<Offset> calculateCorridorRoute({
    required Offset startPoint,
    required Offset endPoint,
    bool startAtEntrance = false,
  }) {
    // Standard Corridor Points:
    // NW: (195, 205), NE: (645, 205)
    // SW: (195, 515), SE: (645, 515)
    final List<Offset> route = [];
    route.add(startPoint);

    // If start is Ground entrance, step down into north corridor
    Offset current = startPoint;
    if (startAtEntrance || (startPoint.dy < northCorridorY && (startPoint.dx - 420).abs() < 50)) {
      current = const Offset(420, northCorridorY);
      route.add(current);
    } else if (startPoint.dy != northCorridorY &&
        startPoint.dy != southCorridorY &&
        startPoint.dx != westCorridorX &&
        startPoint.dx != eastCorridorX) {
      // Connect start point to nearest corridor
      current = _snapToCorridor(startPoint);
      route.add(current);
    }

    final target = _snapToCorridor(endPoint);

    // If already on the same corridor axis
    if ((current.dy - target.dy).abs() < 2.0 &&
        (current.dy == northCorridorY || current.dy == southCorridorY)) {
      // Direct horizontal hallway path
      route.add(target);
    } else if ((current.dx - target.dx).abs() < 2.0 &&
        (current.dx == westCorridorX || current.dx == eastCorridorX)) {
      // Direct vertical hallway path
      route.add(target);
    } else {
      // Need corner transit: Decide whether to go West or East corridor
      // Check which corner yields the shortest Manhattan path
      final double distViaWest =
          (current.dx - westCorridorX).abs() +
          (current.dy - target.dy).abs() +
          (westCorridorX - target.dx).abs();

      final double distViaEast =
          (current.dx - eastCorridorX).abs() +
          (current.dy - target.dy).abs() +
          (eastCorridorX - target.dx).abs();

      final double cornerX = distViaWest <= distViaEast ? westCorridorX : eastCorridorX;

      // 1. Move horizontally on current corridor to corner
      route.add(Offset(cornerX, current.dy));
      // 2. Move vertically along corner corridor to target's corridor height
      route.add(Offset(cornerX, target.dy));
      // 3. Move horizontally on target corridor to target
      if (cornerX != target.dx) {
        route.add(target);
      }
    }

    // Finally enter into room door and center
    if (endPoint != target) {
      route.add(endPoint);
    }

    // Clean duplicate consecutive points
    final List<Offset> cleaned = [];
    for (final pt in route) {
      if (cleaned.isEmpty || (cleaned.last - pt).distance > 1.0) {
        cleaned.add(pt);
      }
    }
    return cleaned;
  }

  static Offset _snapToCorridor(Offset pt) {
    // Find closest corridor segment
    final distToNorth = (pt.dy - northCorridorY).abs();
    final distToSouth = (pt.dy - southCorridorY).abs();
    final distToWest = (pt.dx - westCorridorX).abs();
    final distToEast = (pt.dx - eastCorridorX).abs();

    final minDist = math.min(
      math.min(distToNorth, distToSouth),
      math.min(distToWest, distToEast),
    );

    if (minDist == distToNorth) {
      return Offset(pt.dx.clamp(westCorridorX, eastCorridorX), northCorridorY);
    } else if (minDist == distToSouth) {
      return Offset(pt.dx.clamp(westCorridorX, eastCorridorX), southCorridorY);
    } else if (minDist == distToWest) {
      return Offset(westCorridorX, pt.dy.clamp(northCorridorY, southCorridorY));
    } else {
      return Offset(eastCorridorX, pt.dy.clamp(northCorridorY, southCorridorY));
    }
  }
}
