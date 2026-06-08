// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../chat/admin_chat_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'user_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: AppTheme.adminBlue,
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'ព័ត៌មានគណនី',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditProfileScreen()),
            ).then((_) {
              context.read<AuthProvider>().refreshProfile();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboard(user),
            _buildJobsTab(),
            const UserListScreen(),
            const AdminChatListScreen(),
            _buildSettings(),
          ],
        ),
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: context.read<ChatProvider>().totalUnreadStream(myUid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: AppTheme.adminBlue,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'ផ្ទាំងគ្រប់គ្រង',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'ការស្នើសុំ',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'អ្នកប្រើប្រាស់',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.chat_bubble),
                label: 'ការសន្ទនា',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'ការកំណត់',
              ),
            ],
          );
        },
      ),
    );
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'អ្នកគ្រប់គ្រង';
      case 1:
        return 'ការស្នើសុំ';
      case 2:
        return 'អ្នកប្រើប្រាស់';
      case 3:
        return 'ការសន្ទនា';
      case 4:
        return 'ការកំណត់';
      default:
        return 'អ្នកគ្រប់គ្រង';
    }
  }

  // ── Dashboard tab ─────────────────────────────────────────────────────────

  Widget _buildDashboard(dynamic user) {
    return Consumer<AppProvider>(
      builder: (context, appProv, _) {
        final totalTractor = appProv.tractorJobs.length;
        final totalDrone = appProv.droneJobs.length;
        final pendingCount = appProv.pendingTractorJobs.length +
            appProv.pendingDroneJobs.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.adminBlue, Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.adminBlue.withOpacity(0.3),
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
                      child: user?.fullName.isNotEmpty == true
                          ? Text(
                              user!.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            )
                          : const Icon(Icons.person,
                              size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ស្វាគមន៍, ${user?.fullName ?? 'អ្នកគ្រប់គ្រង'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'អ្នកគ្រប់គ្រងប្រព័ន្ធ',
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

              // Stats
              const Text(
                'ស្ថិតិជាក់ស្ដែង',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('🚜', 'ការស្នើសុំត្រាក់ទ័រ',
                      '$totalTractor', AppTheme.farmerGreen),
                  const SizedBox(width: 12),
                  _buildStatCard('🛸', 'ការស្នើសុំដ្រូន',
                      '$totalDrone', AppTheme.adminBlue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                      '⏳', 'កំពុងរង់ចាំ', '$pendingCount', AppTheme.accentGold),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    '✅',
                    'បានបញ្ជាក់',
                    '${appProv.tractorJobs.where((j) => j.status == 'confirmed').length + appProv.droneJobs.where((j) => j.status == 'confirmed').length}',
                    AppTheme.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
              const Text(
                'ដំណើរការរហ័ស',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.people_outline,
                    label: 'អ្នកប្រើប្រាស់',
                    color: AppTheme.adminBlue,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'ការសន្ទនា',
                    color: AppTheme.providerOrange,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.assignment_outlined,
                    label: 'ការស្នើសុំ',
                    color: AppTheme.farmerGreen,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pending jobs
              if (appProv.pendingTractorJobs.isNotEmpty) ...[
                _buildSectionHeader('🚜 ការស្នើសុំត្រាក់ទ័រ — រង់ចាំ'),
                const SizedBox(height: 8),
                ...appProv.pendingTractorJobs.take(3).map(
                      (job) => _buildTractorJobCard(context, appProv, job),
                    ),
                if (appProv.pendingTractorJobs.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(
                      onPressed: () => setState(() => _currentIndex = 1),
                      child: Text(
                          'មើលទាំងអស់ (${appProv.pendingTractorJobs.length})',
                          style: const TextStyle(color: AppTheme.adminBlue)),
                    ),
                  ),
                const SizedBox(height: 8),
              ],

              if (appProv.pendingDroneJobs.isNotEmpty) ...[
                _buildSectionHeader('🛸 ការស្នើសុំដ្រូន — រង់ចាំ'),
                const SizedBox(height: 8),
                ...appProv.pendingDroneJobs.take(3).map(
                      (job) => _buildDroneJobCard(context, appProv, job),
                    ),
                if (appProv.pendingDroneJobs.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(
                      onPressed: () => setState(() => _currentIndex = 1),
                      child: Text(
                          'មើលទាំងអស់ (${appProv.pendingDroneJobs.length})',
                          style: const TextStyle(color: AppTheme.adminBlue)),
                    ),
                  ),
              ],

              if (appProv.pendingTractorJobs.isEmpty &&
                  appProv.pendingDroneJobs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Text('✅', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text(
                          'គ្មានការស្នើសុំរង់ចាំ',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Jobs tab ──────────────────────────────────────────────────────────────

  Widget _buildJobsTab() {
    return Consumer<AppProvider>(
      builder: (context, appProv, _) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppTheme.adminBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.adminBlue,
                tabs: [
                  Tab(text: '🚜 ត្រាក់ទ័រ'),
                  Tab(text: '🛸 ដ្រូន'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    appProv.tractorJobs.isEmpty
                        ? const Center(child: Text('មិនទាន់មានការស្នើសុំ'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: appProv.tractorJobs.length,
                            itemBuilder: (ctx, i) => _buildTractorJobCard(
                                ctx, appProv, appProv.tractorJobs[i]),
                          ),
                    appProv.droneJobs.isEmpty
                        ? const Center(child: Text('មិនទាន់មានការស្នើសុំ'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: appProv.droneJobs.length,
                            itemBuilder: (ctx, i) => _buildDroneJobCard(
                                ctx, appProv, appProv.droneJobs[i]),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTractorJobCard(
      BuildContext context, AppProvider appProv, TractorJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚜', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.serviceType,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(job.farmerName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              _statusBadge(job.statusLabel, job.statusColor),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, job.location),
          _infoRow(Icons.calendar_today_outlined,
              '${job.scheduledDate} • ${job.scheduledTime}'),
          _infoRow(Icons.crop_square_outlined, '${job.areaHectares} ហិចតា'),
          if (job.notes?.isNotEmpty == true)
            _infoRow(Icons.notes_outlined, job.notes!),
          if (job.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    onPressed: () =>
                        appProv.updateTractorJobStatus(job.id, 'cancelled'),
                    child: const Text('បោះបង់'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen),
                    onPressed: () =>
                        appProv.updateTractorJobStatus(job.id, 'confirmed'),
                    child: const Text('បញ្ជាក់',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDroneJobCard(
      BuildContext context, AppProvider appProv, DroneJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛸', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${job.cropType} — ${job.pesticide}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(job.farmerName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              _statusBadge(job.statusLabel, job.statusColor),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, job.location),
          _infoRow(Icons.calendar_today_outlined,
              '${job.scheduledDate} • ${job.scheduledTime}'),
          _infoRow(Icons.crop_square_outlined, '${job.areaHectares} ហិចតា'),
          if (job.notes?.isNotEmpty == true)
            _infoRow(Icons.notes_outlined, job.notes!),
          if (job.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    onPressed: () =>
                        appProv.updateDroneJobStatus(job.id, 'cancelled'),
                    child: const Text('បោះបង់'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminBlue),
                    onPressed: () =>
                        appProv.updateDroneJobStatus(job.id, 'confirmed'),
                    child: const Text('បញ្ជាក់',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Settings tab ──────────────────────────────────────────────────────────

  Widget _buildSettings() {
    final auth = context.read<AuthProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsTile(
          Icons.person_outline,
          'ព័ត៌មានគណនី',
          'មើល និងកែប្រែព័ត៌មាន',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) {
            context.read<AuthProvider>().refreshProfile();
          }),
        ),
        _buildSettingsTile(
            Icons.notifications_outlined,
            'ការជូនដំណឹង',
            'គ្រប់គ្រងការជូនដំណឹង'),
        _buildSettingsTile(Icons.language_outlined, 'ភាសា', 'ខ្មែរ'),
        _buildSettingsTile(Icons.help_outline, 'ជំនួយ', 'មើលសំណួរញឹកញាប់'),
        _buildSettingsTile(Icons.info_outline, 'អំពីកម្មវិធី', 'Dorne v1.0.0'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout, color: AppTheme.errorRed),
          label: const Text('ចេញពីគណនី',
              style: TextStyle(color: AppTheme.errorRed)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.errorRed),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
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
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.adminBlue),
        title: Text(title),
        subtitle:
            Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        onTap: onTap,
      ),
    );
  }
}