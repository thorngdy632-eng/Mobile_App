// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../models/scheduled_job.dart';
import '../models/backhaul_load.dart';

class AppProvider extends ChangeNotifier {
  // ─── Scheduled Jobs (Banteay Meanchey only) ───────────────────────────────
  final List<ScheduledJob> _scheduledJobs = const [
    ScheduledJob(
      id: 1,
      date: '២ មិថុនា',
      time: 'ព្រឹក ៨:០០',
      service: 'គោយន្តដឹកស្រូវ',
      location: 'ស្រុកបាទី',
      distance: '៣ គម',
      status: JobStatus.confirmed,
    ),
    ScheduledJob(
      id: 2,
      date: '៣ មិថុនា',
      time: 'រសៀល ២:០០',
      service: 'ត្រាក់ទ័រភ្ជួរស្រែ',
      location: 'ស្រុកមង្គលបូរី',
      distance: '៥ គម',
      status: JobStatus.confirmed,
    ),
    ScheduledJob(
      id: 3,
      date: '៤ មិថុនា',
      time: 'ព្រឹក ៦:៣០',
      service: 'គោយន្តដឹកស្រូវ',
      location: 'ក្រុងសិរីសោភ័ណ',
      distance: '៧ គម',
      status: JobStatus.pending,
    ),
  ];

  List<ScheduledJob> get scheduledJobs => List.unmodifiable(_scheduledJobs);

  // ─── Backhaul Loads (Banteay Meanchey only) ───────────────────────────────
  final List<BackhaulLoad> _backhaulLoads = [
    BackhaulLoad(
      id: 1,
      cargo: 'ជី',
      icon: Icons.inventory_2_outlined,
      from: 'ក្រុងសិរីសោភ័ណ',
      to: 'ស្រុកម៉ាឡៃ',
      weight: '២ តោន',
      price: '\$៨០',
      color: const Color(0xFFF57C00), // amber
    ),
    BackhaulLoad(
      id: 2,
      cargo: 'កូនឈើ',
      icon: Icons.eco_outlined,
      from: 'ស្រុកមង្គលបូរី',
      to: 'ស្រុកអូរជ្រៅ',
      weight: '៥០០ គីឡូ',
      price: '\$៤៥',
      color: const Color(0xFF43A047), // green
    ),
    BackhaulLoad(
      id: 3,
      cargo: 'គ្រឿងសំណង់',
      icon: Icons.construction_outlined,
      from: 'ក្រុងសិរីសោភ័ណ',
      to: 'ស្រុកព្រះនេត្រព្រៃ',
      weight: '៣ តោន',
      price: '\$១២០',
      color: const Color(0xFFE64A19), // orange
    ),
    BackhaulLoad(
      id: 4,
      cargo: 'ជី',
      icon: Icons.inventory_2_outlined,
      from: 'ស្រុកស្វាយចេក',
      to: 'ស្រុកសមង្គលបូរី',
      weight: '១.៥ តោន',
      price: '\$៦៥',
      color: const Color(0xFFF57C00), // amber
    ),
  ];

  List<BackhaulLoad> get backhaulLoads => List.unmodifiable(_backhaulLoads);

  // ─── Notification badge ───────────────────────────────────────────────────
  int _notificationCount = 3;
  int get notificationCount => _notificationCount;

  void clearNotifications() {
    _notificationCount = 0;
    notifyListeners();
  }

  // ─── Loading state ────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
  }
}
