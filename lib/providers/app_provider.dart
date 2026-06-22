// lib/providers/app_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/backhaul_load.dart';
import '../models/scheduled_job.dart';
import '../models/service_request.dart';
import '../models/user_model.dart';
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

/// One month's worth of new-signup counts, used by the Admin statistics
/// screen to chart farmer / service-provider growth over time.
class MonthlyUserStat {
  final DateTime month; // always the 1st of the month
  final int farmerCount;
  final int providerCount;

  const MonthlyUserStat({
    required this.month,
    required this.farmerCount,
    required this.providerCount,
  });

  int get total => farmerCount + providerCount;

  static const List<String> _khmerMonthsShort = [
    'មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
    'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ',
  ];

  /// Short Khmer label, e.g. "មិថុនា" — used as a chart axis label.
  String get label => _khmerMonthsShort[month.month - 1];
}

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream subscriptions (for cancellation on refresh/dispose) ────────────
  final List<StreamSubscription<QuerySnapshot>> _streamSubs = [];

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

  // ── Farmer map-drop service requests (5 services on home screen) ──────────
  List<ServiceRequest> _serviceRequests = [];
  List<ServiceRequest> get serviceRequests => _serviceRequests;

  // ── All app users (live, for Admin stats: totals, role counts, growth) ────
  List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

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
    // 1. Stream all Tractor Jobs
    _streamSubs.add(_db
        .collection('tractorJobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _tractorJobs = snapshot.docs
          .map((doc) => TractorJob.fromMap(doc.data(), doc.id))
          .toList();
      _notificationCount = pendingTractorJobs.length + pendingDroneJobs.length;
      notifyListeners();
    }));

    // 2. Stream all Drone Jobs
    _streamSubs.add(_db
        .collection('droneJobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _droneJobs = snapshot.docs
          .map((doc) => DroneJob.fromMap(doc.data(), doc.id))
          .toList();
      _notificationCount = pendingTractorJobs.length + pendingDroneJobs.length;
      notifyListeners();
    }));

    // 3. Stream all Users with permission error handling (avoids crash for non-admins)
    _streamSubs.add(_db.collection('users').snapshots().listen(
      (snapshot) {
        _allUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('⚠️ Users stream error (Expected for non-admins): $error');
        _allUsers = [];
        notifyListeners();
      },
    ));

    // 4. Stream all Service Requests
    _streamSubs.add(_db
        .collection('serviceRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _serviceRequests = snapshot.docs
          .map((doc) => ServiceRequest.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    }));
  }

  // ── Force-refresh all Firestore streams ──────────────────────────────────
  // Called on app resume (WidgetsBindingObserver) to re-subscribe to every
  // stream, ensuring fresh data after backgrounding or token expiry.
  void refreshAllStreams() {
    // Cancel existing subscriptions
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    _streamSubs.clear();
    // Re-create all streams
    _initStreams();
    debugPrint('🔄 AppProvider: all Firestore streams re-subscribed');
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

  // ── Farmer: drop a pin on the map and submit a service request ────────────
  //
  // Called from the FlutterMap/OpenStreetMap panel after the Farmer drops a
  // location pin and fills in the request form (name, place of birth,
  // current location, service type, land area, offer price).

  Future<String?> addServiceRequest({
    required String farmerUid,
    required String farmerName,
    required String placeOfBirth,
    required double latitude,
    required double longitude,
    required String currentAddress,
    required String serviceType,
    required double landArea,
    required String landUnit,
    required double offerPrice,
    String? notes,
  }) async {
    try {
      final request = ServiceRequest(
        id: '',
        farmerUid: farmerUid,
        farmerName: farmerName,
        placeOfBirth: placeOfBirth,
        latitude: latitude,
        longitude: longitude,
        currentAddress: currentAddress,
        serviceType: serviceType,
        landArea: landArea,
        landUnit: landUnit,
        offerPrice: offerPrice,
        status: 'pending',
        createdAt: DateTime.now(),
        notes: notes,
      );
      await _db.collection('serviceRequests').add(request.toMap());
      return null; // success
    } catch (e) {
      return 'មានបញ្ហាក្នុងការផ្ញើសំណើ: $e';
    }
  }

  /// Service Provider: accept or decline a farmer's location-drop request.
  ///
  /// Accepting attaches `providerUid` / `providerName` so the farmer knows
  /// who is coming, flips the global status to `accepted`, and removes the
  /// job from every other matching provider's queue.
  ///
  /// Declining is per-provider: it only adds this provider's uid to
  /// `declinedBy` so the request disappears from *their* queue, while every
  /// other Service Provider whose `serviceType` matches can still see it and
  /// accept it.
  Future<void> respondToServiceRequest({
    required String requestId,
    required bool accept,
    required String providerUid,
    required String providerName,
  }) async {
    final docRef = _db.collection('serviceRequests').doc(requestId);
    if (accept) {
      await docRef.update({
        'status': 'accepted',
        'providerUid': providerUid,
        'providerName': providerName,
      });
    } else {
      await docRef.update({
        'declinedBy': FieldValue.arrayUnion([providerUid]),
      });
    }
  }

  Future<void> updateServiceRequestStatus(
      String requestId, String newStatus) async {
    await _db
        .collection('serviceRequests')
        .doc(requestId)
        .update({'status': newStatus});
  }

  Future<void> cancelServiceRequest(String requestId) async {
    await updateServiceRequestStatus(requestId, 'cancelled');
  }

  /// Provider gives up / abandons an accepted request — sets status back to
  /// 'pending' so it becomes visible to other matching providers again.
  Future<void> abandonServiceRequest(String requestId) async {
    await _db.collection('serviceRequests').doc(requestId).update({
      'status': 'pending',
      'providerUid': FieldValue.delete(),
      'providerName': FieldValue.delete(),
    });
  }

  /// All requests submitted by a particular Farmer (used on their "My
  /// Requests" tab), newest first.
  List<ServiceRequest> serviceRequestsForFarmer(String farmerUid) =>
      _serviceRequests.where((r) => r.farmerUid == farmerUid).toList();

  /// Pending requests that match a Service Provider's service type — these
  /// are the "incoming job" notifications the provider sees and can
  /// accept / decline. Pass [excludeDeclinedBy] (the provider's own uid) to
  /// hide requests this specific provider has already declined — they stay
  /// visible to every other matching provider.
  List<ServiceRequest> pendingServiceRequestsForProvider(
    String serviceType, {
    String? excludeDeclinedBy,
  }) =>
      _serviceRequests
          .where((r) =>
              r.serviceType == serviceType &&
              r.status == 'pending' &&
              (excludeDeclinedBy == null ||
                  !r.declinedBy.contains(excludeDeclinedBy)))
          .toList();

  /// Requests this provider has already accepted (their active jobs).
  List<ServiceRequest> acceptedServiceRequestsForProvider(String providerUid) =>
      _serviceRequests
          .where((r) => r.providerUid == providerUid && r.status == 'accepted')
          .toList();

  /// Straight-line distance in km between a provider's current position and
  /// the farmer's dropped pin — shown on the incoming-request card so the
  /// provider can judge how far the job is.
  double distanceToRequestKm({
    required double providerLat,
    required double providerLng,
    required ServiceRequest request,
  }) {
    final meters = Geolocator.distanceBetween(
      providerLat,
      providerLng,
      request.latitude,
      request.longitude,
    );
    return meters / 1000.0;
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

  // ── Admin: live user statistics (fully dynamic — derived from _allUsers) ──
  //
  // Every getter below recomputes from the live `_allUsers` snapshot, so the
  // Admin dashboard numbers change in real time the moment a user registers,
  // changes role, or is deleted. Nothing here is hard-coded or static.

  /// Total number of registered users, across every role.
  int get totalUsersCount => _allUsers.length;

  /// Total number of farmers.
  int get totalFarmersCount =>
      _allUsers.where((u) => u.role == UserRole.farmer).length;

  /// Total number of service providers.
  int get totalServiceProvidersCount =>
      _allUsers.where((u) => u.role == UserRole.serviceProvider).length;

  /// Total number of admins (normally exactly 1 — the reserved account).
  int get totalAdminsCount =>
      _allUsers.where((u) => u.role == UserRole.admin).length;

  /// Monthly growth of farmers and service providers, based on each user's
  /// `createdAt`. Returns the last [monthsBack] months (oldest → newest),
  /// so it can be plotted directly on a bar/line chart. Months with zero
  /// signups are included as zero, not skipped, so the timeline stays
  /// continuous.
  List<MonthlyUserStat> monthlyUserGrowth({int monthsBack = 6}) {
    final now = DateTime.now();
    // Build the list of the last `monthsBack` calendar months, oldest first.
    final months = List<DateTime>.generate(monthsBack, (i) {
      final monthsAgo = monthsBack - 1 - i;
      return DateTime(now.year, now.month - monthsAgo, 1);
    });

    return months.map((monthStart) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      final usersInMonth = _allUsers.where((u) =>
          !u.createdAt.isBefore(monthStart) && u.createdAt.isBefore(monthEnd));
      final farmers = usersInMonth
          .where((u) => u.role == UserRole.farmer)
          .length;
      final providers = usersInMonth
          .where((u) => u.role == UserRole.serviceProvider)
          .length;
      return MonthlyUserStat(
        month: monthStart,
        farmerCount: farmers,
        providerCount: providers,
      );
    }).toList();
  }

  /// Admin: permanently delete a user's profile from Firestore.
  ///
  /// This removes the user's document from the `users` collection — they
  /// will disappear from every list, every stat, and (since AuthWrapper /
  /// the rest of the app reads the Firestore profile, not just the Auth
  /// token) they will no longer be able to use the app even if their
  /// Firebase Auth login still technically exists.
  ///
  /// NOTE: deleting the underlying Firebase Authentication account itself
  /// (so the email/password can never sign in again) requires either the
  /// user's own credentials or an admin backend (e.g. a Cloud Function with
  /// the Firebase Admin SDK) — it cannot be done securely from a Flutter
  /// client for *other* users' accounts. This deletes the app profile,
  /// which is what controls access to every screen in this app.
  Future<String?> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      return null; // success
    } catch (e) {
      return 'មានបញ្ហាក្នុងការលុបអ្នកប្រើប្រាស់: $e';
    }
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
        price: '320,000រៀល',
        color: const Color(0xFF43A047),
      ),
      BackhaulLoad(
        id: 2,
        cargo: 'ស្រូវ (Paddy)',
        icon: Icons.agriculture,
        from: 'ស្រុកបន្ទាយអំពិល',
        to: 'ក្រុងសិរីស្វាយប៉ាវ',
        weight: '2 តោន',
        price: '480,000រៀល',
        color: const Color(0xFFF9A825),
      ),
      BackhaulLoad(
        id: 3,
        cargo: 'ពោត (Corn)',
        icon: Icons.eco,
        from: 'ស្រុកសសរ',
        to: 'ស្រុកអូរជ្រៅ',
        weight: '800 គក',
        price: '240,000រៀល',
        color: const Color(0xFFEF5350),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    _streamSubs.clear();
    super.dispose();
  }
}