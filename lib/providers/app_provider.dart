// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/backhaul_load.dart';
import '../models/scheduled_job.dart';
import 'package:flutter/material.dart';

// ─── Firestore-backed models ──────────────────────────────────────────────────

/// A tractor rental / plowing request submitted by a Farmer
class TractorJob {
  final String id;
  final String farmerUid;
  final String farmerName;
  final String location;
  final String serviceType; // e.g. 'ភ្ជួរស្រែ', 'ច្រូតស្រូវ'
  final String scheduledDate;
  final String scheduledTime;
  final double areaHectares;
  final String status; // 'pending' | 'confirmed' | 'completed' | 'cancelled'
  final DateTime createdAt;
  final String? notes;

  const TractorJob({
    required this.id,
    required this.farmerUid,
    required this.farmerName,
    required this.location,
    required this.serviceType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.areaHectares,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory TractorJob.fromMap(Map<String, dynamic> map, String id) {
    return TractorJob(
      id: id,
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? 'កសិករ',
      location: map['location'] ?? '',
      serviceType: map['serviceType'] ?? 'ភ្ជួរស្រែ',
      scheduledDate: map['scheduledDate'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      areaHectares: (map['areaHectares'] as num?)?.toDouble() ?? 1.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerUid': farmerUid,
        'farmerName': farmerName,
        'location': location,
        'serviceType': serviceType,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'areaHectares': areaHectares,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'notes': notes,
      };

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'បញ្ជាក់';
      case 'completed':
        return 'បានបញ្ចប់';
      case 'cancelled':
        return 'បានបោះបង់';
      default:
        return 'រង់ចាំ';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF2E7D32);
      case 'completed':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFF9A825);
    }
  }
}

/// A drone spraying request submitted by a Farmer
class DroneJob {
  final String id;
  final String farmerUid;
  final String farmerName;
  final String location;
  final String cropType; // e.g. 'ស្រូវ', 'ពោត'
  final String pesticide; // pesticide name
  final String scheduledDate;
  final String scheduledTime;
  final double areaHectares;
  final String status; // 'pending' | 'confirmed' | 'completed' | 'cancelled'
  final DateTime createdAt;
  final String? notes;

  const DroneJob({
    required this.id,
    required this.farmerUid,
    required this.farmerName,
    required this.location,
    required this.cropType,
    required this.pesticide,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.areaHectares,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory DroneJob.fromMap(Map<String, dynamic> map, String id) {
    return DroneJob(
      id: id,
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? 'កសិករ',
      location: map['location'] ?? '',
      cropType: map['cropType'] ?? 'ស្រូវ',
      pesticide: map['pesticide'] ?? '',
      scheduledDate: map['scheduledDate'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      areaHectares: (map['areaHectares'] as num?)?.toDouble() ?? 1.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerUid': farmerUid,
        'farmerName': farmerName,
        'location': location,
        'cropType': cropType,
        'pesticide': pesticide,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'areaHectares': areaHectares,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'notes': notes,
      };

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'បញ្ជាក់';
      case 'completed':
        return 'បានបញ្ចប់';
      case 'cancelled':
        return 'បានបោះបង់';
      default:
        return 'រង់ចាំ';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF2E7D32);
      case 'completed':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFF9A825);
    }
  }
}

// ─── AppProvider ──────────────────────────────────────────────────────────────

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Tractor jobs ──────────────────────────────────────────────────────────
  List<TractorJob> _tractorJobs = [];
  List<TractorJob> get tractorJobs => _tractorJobs;
  List<TractorJob> get pendingTractorJobs =>
      _tractorJobs.where((j) => j.status == 'pending').toList();

  // ── Drone jobs ────────────────────────────────────────────────────────────
  List<DroneJob> _droneJobs = [];
  List<DroneJob> get droneJobs => _droneJobs;
  List<DroneJob> get pendingDroneJobs =>
      _droneJobs.where((j) => j.status == 'pending').toList();

  // ── Legacy lists used by existing screens ─────────────────────────────────
  List<ScheduledJob> _scheduledJobs = [];
  List<ScheduledJob> get scheduledJobs => _scheduledJobs;

  List<BackhaulLoad> _backhaulLoads = [];
  List<BackhaulLoad> get backhaulLoads => _backhaulLoads;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  AppProvider() {
    _initStreams();
    _loadLegacyData();
  }

  // ── Real-time Firestore streams ───────────────────────────────────────────

  void _initStreams() {
    // Stream all tractor jobs, newest first
    _db
        .collection('tractorJobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _tractorJobs = snapshot.docs
          .map((doc) => TractorJob.fromMap(doc.data(), doc.id))
          .toList();
      _notificationCount = pendingTractorJobs.length + pendingDroneJobs.length;
      notifyListeners();
    });

    // Stream all drone jobs, newest first
    _db
        .collection('droneJobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _droneJobs = snapshot.docs
          .map((doc) => DroneJob.fromMap(doc.data(), doc.id))
          .toList();
      _notificationCount = pendingTractorJobs.length + pendingDroneJobs.length;
      notifyListeners();
    });
  }

  // ── Farmer: submit a tractor rental request ───────────────────────────────

  Future<String?> addTractorJob({
    required String farmerUid,
    required String farmerName,
    required String location,
    required String serviceType,
    required String scheduledDate,
    required String scheduledTime,
    required double areaHectares,
    String? notes,
  }) async {
    try {
      final job = TractorJob(
        id: '',
        farmerUid: farmerUid,
        farmerName: farmerName,
        location: location,
        serviceType: serviceType,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        areaHectares: areaHectares,
        status: 'pending',
        createdAt: DateTime.now(),
        notes: notes,
      );
      await _db.collection('tractorJobs').add(job.toMap());
      return null; // success
    } catch (e) {
      return 'មានបញ្ហាក្នុងការបន្ថែម: $e';
    }
  }

  // ── Farmer: submit a drone spraying request ───────────────────────────────

  Future<String?> addDroneJob({
    required String farmerUid,
    required String farmerName,
    required String location,
    required String cropType,
    required String pesticide,
    required String scheduledDate,
    required String scheduledTime,
    required double areaHectares,
    String? notes,
  }) async {
    try {
      final job = DroneJob(
        id: '',
        farmerUid: farmerUid,
        farmerName: farmerName,
        location: location,
        cropType: cropType,
        pesticide: pesticide,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        areaHectares: areaHectares,
        status: 'pending',
        createdAt: DateTime.now(),
        notes: notes,
      );
      await _db.collection('droneJobs').add(job.toMap());
      return null; // success
    } catch (e) {
      return 'មានបញ្ហាក្នុងការបន្ថែម: $e';
    }
  }

  // ── Admin: update job status ──────────────────────────────────────────────

  Future<void> updateTractorJobStatus(String jobId, String newStatus) async {
    await _db
        .collection('tractorJobs')
        .doc(jobId)
        .update({'status': newStatus});
  }

  Future<void> updateDroneJobStatus(String jobId, String newStatus) async {
    await _db
        .collection('droneJobs')
        .doc(jobId)
        .update({'status': newStatus});
  }

  // ── Farmer: get only their own jobs ──────────────────────────────────────

  List<TractorJob> tractorJobsForFarmer(String farmerUid) =>
      _tractorJobs.where((j) => j.farmerUid == farmerUid).toList();

  List<DroneJob> droneJobsForFarmer(String farmerUid) =>
      _droneJobs.where((j) => j.farmerUid == farmerUid).toList();

  // ── Notifications ─────────────────────────────────────────────────────────

  void clearNotifications() {
    _notificationCount = 0;
    notifyListeners();
  }

  // ── Legacy data for existing HomeScreen / BackhaulCard widgets ────────────
  // These match your existing ScheduledJob and BackhaulLoad static models.
  // Replace with Firestore streams when you migrate those screens.

  void _loadLegacyData() {
    _isLoading = true;
    notifyListeners();

    // Simulated scheduled jobs — replace with a Firestore stream when ready
    _scheduledJobs = [
      const ScheduledJob(
        id: 1,
        date: 'ថ្ងៃច័ន្ទ, ១ មិថុនា',
        time: 'ព្រឹក ៦:០០',
        service: 'ភ្ជួរស្រែ — ត្រាក់ទ័រ Kubota',
        location: 'ស្រុកបន្ទាយអំពិល',
        distance: '៣.២ គម',
        status: JobStatus.confirmed,
      ),
      const ScheduledJob(
        id: 2,
        date: 'ថ្ងៃអង្គារ, ២ មិថុនា',
        time: 'ព្រឹក ៧:៣០',
        service: 'បាញ់ថ្នាំ — ដ្រូន DJI Agras',
        location: 'ភូមិប្រាំដំបូង',
        distance: '5.1 គម',
        status: JobStatus.pending,
      ),
    ];

    // Simulated backhaul loads
    _backhaulLoads = [
      BackhaulLoad(
        id: 1,
        cargo: 'ជី (Fertilizer)',
        icon: Icons.grass,
        from: 'ក្រុងសិរីស្វាយប៉ាវ',
        to: 'ស្រុកមង្គលបូរី',
        weight: '500 គក',
        price: '\$80',
        color: const Color(0xFF43A047),
      ),
      BackhaulLoad(
        id: 2,
        cargo: 'ស្រូវ (Paddy)',
        icon: Icons.agriculture,
        from: 'ស្រុកបន្ទាយអំពិល',
        to: 'ក្រុងសិរីស្វាយប៉ាវ',
        weight: '2 តោន',
        price: '\$120',
        color: const Color(0xFFF9A825),
      ),
      BackhaulLoad(
        id: 3,
        cargo: 'ពោត (Corn)',
        icon: Icons.eco,
        from: 'ស្រុកសសរ',
        to: 'ស្រុកអូរជ្រៅ',
        weight: '800 គក',
        price: '\$60',
        color: const Color(0xFFEF5350),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}