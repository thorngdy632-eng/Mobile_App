// lib/screens/farmer/farmer_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _currentIndex = 0;

  final List<_ServiceCategory> _categories = const [
    _ServiceCategory(icon: '🚜', label: 'ត្រាក់ទ័រ'),
    _ServiceCategory(icon: '🌾', label: 'ច្រូតស្រូវ'),
    _ServiceCategory(icon: '🛸', label: 'ដ្រូន'),
    _ServiceCategory(icon: '🛠', label: 'គោយន្ត'),
    _ServiceCategory(icon: '💨', label: 'បាញ់ថ្នាំ'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('កសិករ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ចេញ',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // FAB to submit a new job request
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestJobDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ស្នើសុំសេវា',
            style: TextStyle(color: Colors.white, fontFamily: 'KhmerOSBattambang')),
      ),
      body: SafeArea(
        child: _currentIndex == 0 ? _buildHome(user) : _buildMyJobs(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.farmerGreen,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ទំព័រដើម',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'ការងាររបស់ខ្ញុំ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'ប្រវត្តិរូប',
          ),
        ],
      ),
    );
  }

  // ── Home tab ──────────────────────────────────────────────────────────────

  Widget _buildHome(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card with real user name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.farmerGreen, Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.farmerGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Text('👨‍🌾', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic name from AuthProvider / Firestore
                      Text(
                        'ស្វាគមន៍, ${user?.fullName ?? 'កសិករ'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ស្វែងរកសេវាកសិកម្មជិតអ្នក',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppTheme.textSecondary),
                SizedBox(width: 12),
                Text(
                  'ស្វែងរកសេវាកម្ម...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Service categories
          const Text(
            'ប្រភេទសេវាកម្ម',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => _showRequestJobDialog(context, preselect: cat.label),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          cat.label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // My recent jobs summary — live from Firestore via Consumer
          const Text(
            'ការងាររបស់ខ្ញុំ (ថ្មីៗ)',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Consumer2<AuthProvider, AppProvider>(
            builder: (context, auth, appProv, _) {
              final uid = auth.currentUser?.uid ?? '';
              final myTractor = appProv.tractorJobsForFarmer(uid).take(2).toList();
              final myDrone = appProv.droneJobsForFarmer(uid).take(2).toList();

              if (myTractor.isEmpty && myDrone.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Text('📋', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text(
                          'មិនទាន់មានការស្នើសុំ\nចុចប៊ូតុង "ស្នើសុំសេវា" ខាងក្រោម',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...myTractor.map((j) => _buildJobTile(
                        emoji: '🚜',
                        title: j.serviceType,
                        subtitle: j.location,
                        date: j.scheduledDate,
                        statusLabel: j.statusLabel,
                        statusColor: j.statusColor,
                      )),
                  ...myDrone.map((j) => _buildJobTile(
                        emoji: '🛸',
                        title: 'ដ្រូនបាញ់ — ${j.cropType}',
                        subtitle: j.location,
                        date: j.scheduledDate,
                        statusLabel: j.statusLabel,
                        statusColor: j.statusColor,
                      )),
                ],
              );
            },
          ),
          const SizedBox(height: 80), // space for FAB
        ],
      ),
    );
  }

  Widget _buildJobTile({
    required String emoji,
    required String title,
    required String subtitle,
    required String date,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── My Jobs tab — full list from Firestore ────────────────────────────────

  Widget _buildMyJobs() {
    return Consumer2<AuthProvider, AppProvider>(
      builder: (context, auth, appProv, _) {
        final uid = auth.currentUser?.uid ?? '';
        final myTractor = appProv.tractorJobsForFarmer(uid);
        final myDrone = appProv.droneJobsForFarmer(uid);

        if (myTractor.isEmpty && myDrone.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text(
                  'អ្នកមិនទាន់មានការស្នើសុំ',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myTractor.isNotEmpty) ...[
              const Text('ការស្នើសុំត្រាក់ទ័រ',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...myTractor.map((j) => _buildJobTile(
                    emoji: '🚜',
                    title: j.serviceType,
                    subtitle: '${j.location} • ${j.areaHectares} ហិចតា',
                    date: '${j.scheduledDate} • ${j.scheduledTime}',
                    statusLabel: j.statusLabel,
                    statusColor: j.statusColor,
                  )),
              const SizedBox(height: 16),
            ],
            if (myDrone.isNotEmpty) ...[
              const Text('ការស្នើសុំដ្រូន',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...myDrone.map((j) => _buildJobTile(
                    emoji: '🛸',
                    title: '${j.cropType} — ${j.pesticide}',
                    subtitle: '${j.location} • ${j.areaHectares} ហិចតា',
                    date: '${j.scheduledDate} • ${j.scheduledTime}',
                    statusLabel: j.statusLabel,
                    statusColor: j.statusColor,
                  )),
            ],
            const SizedBox(height: 80), // FAB clearance
          ],
        );
      },
    );
  }

  // ── Submit job dialog ─────────────────────────────────────────────────────

  void _showRequestJobDialog(BuildContext context, {String? preselect}) {
    final auth = context.read<AuthProvider>();
    final appProv = context.read<AppProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    String selectedType = (preselect == 'ដ្រូន' || preselect == 'បាញ់ថ្នាំ')
        ? 'drone'
        : 'tractor';
    final locationCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    // Drone extras
    final cropCtrl = TextEditingController(text: 'ស្រូវ');
    final pesticideCtrl = TextEditingController();
    // Tractor extras
    String tractorService = preselect ?? 'ភ្ជួរស្រែ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ស្នើសុំសេវា',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),

                // Service type toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = 'tractor'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'tractor'
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primaryGreen),
                          ),
                          child: const Center(
                            child: Text('🚜 ត្រាក់ទ័រ',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = 'drone'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'drone'
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primaryGreen),
                          ),
                          child: const Center(
                            child: Text('🛸 ដ្រូន',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (selectedType == 'tractor') ...[
                  DropdownButtonFormField<String>(
                    value: tractorService,
                    decoration: const InputDecoration(labelText: 'ប្រភេទការងារ'),
                    items: ['ភ្ជួរស្រែ', 'ច្រូតស្រូវ', 'ដាំស្រូវ', 'ជីកបង្ហូរ']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => tractorService = v!),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: cropCtrl,
                    decoration: const InputDecoration(labelText: 'ប្រភេទដំណាំ'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pesticideCtrl,
                    decoration: const InputDecoration(labelText: 'ប្រភេទថ្នាំ'),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'ទីតាំង (ភូមិ/ឃុំ/ស្រុក)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        decoration:
                            const InputDecoration(labelText: 'ថ្ងៃខែ (DD/MM/YYYY)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(labelText: 'ម៉ោង'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'ផ្ទៃដីជាហិចតា', suffixText: 'ហិចតា'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'កំណត់ចំណាំ (ជាជម្រើស)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      String? err;
                      if (selectedType == 'tractor') {
                        err = await appProv.addTractorJob(
                          farmerUid: user.uid,
                          farmerName: user.fullName,
                          location: locationCtrl.text.trim(),
                          serviceType: tractorService,
                          scheduledDate: dateCtrl.text.trim(),
                          scheduledTime: timeCtrl.text.trim(),
                          areaHectares:
                              double.tryParse(areaCtrl.text) ?? 1.0,
                          notes: notesCtrl.text.trim(),
                        );
                      } else {
                        err = await appProv.addDroneJob(
                          farmerUid: user.uid,
                          farmerName: user.fullName,
                          location: locationCtrl.text.trim(),
                          cropType: cropCtrl.text.trim(),
                          pesticide: pesticideCtrl.text.trim(),
                          scheduledDate: dateCtrl.text.trim(),
                          scheduledTime: timeCtrl.text.trim(),
                          areaHectares:
                              double.tryParse(areaCtrl.text) ?? 1.0,
                          notes: notesCtrl.text.trim(),
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ?? 'បានផ្ញើការស្នើសុំដោយជោគជ័យ! 🎉'),
                            backgroundColor:
                                err == null ? AppTheme.primaryGreen : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('ផ្ញើការស្នើសុំ',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'KhmerOSBattambang',
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCategory {
  final String icon;
  final String label;
  const _ServiceCategory({required this.icon, required this.label});
}