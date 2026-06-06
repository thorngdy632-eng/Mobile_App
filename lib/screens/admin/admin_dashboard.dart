import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('អ្នកគ្រប់គ្រង'),
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
      body: SafeArea(
        child: _currentIndex == 0 ? _buildDashboard(user) : _buildSettings(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.adminBlue,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'ផ្ទាំងគ្រប់គ្រង',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'ការកំណត់',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(dynamic user) {
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
                  child: const Icon(Icons.person, size: 32, color: Colors.white),
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
            'ស្ថិតិប្រចាំថ្ងៃ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('👥', 'អ្នកប្រើប្រាស់', '១២៨', AppTheme.adminBlue),
              const SizedBox(width: 12),
              _buildStatCard('🚜', 'សេវាកម្ម', '៣៥', AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('📋', 'ការជួលថ្ងៃនេះ', '១២', AppTheme.accentGold),
              const SizedBox(width: 12),
              _buildStatCard('💰', 'ចំណូល', '\$២,៤៥០', AppTheme.providerOrange),
            ],
          ),
          const SizedBox(height: 24),

          // Recent activity
          const Text(
            'សកម្មភាពថ្មីៗ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityTile(
            Icons.person_add_outlined,
            'កសិករថ្មីចុះឈ្មោះ',
            'បាទី — ២ នាទីមុន',
            AppTheme.primaryGreen,
          ),
          _buildActivityTile(
            Icons.agriculture_outlined,
            'សេវាថ្មីបានបន្ថែម',
            'ត្រាក់ទ័រ — ១៥ នាទីមុន',
            AppTheme.adminBlue,
          ),
          _buildActivityTile(
            Icons.warning_amber_outlined,
            'របាយការណ៍បញ្ហា',
            'គោយន្តខូច — ៣០ នាទីមុន',
            AppTheme.errorRed,
          ),
          _buildActivityTile(
            Icons.star_outline,
            'ការវាយតម្លៃថ្មី',
            '⭐⭐⭐⭐⭐ — ១ ម៉ោងមុន',
            AppTheme.accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
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
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsTile(Icons.person_outline, 'ព័ត៌មានគណនី', 'មើល និងកែប្រែព័ត៌មាន'),
        _buildSettingsTile(Icons.notifications_outlined, 'ការជូនដំណឹង', 'គ្រប់គ្រងការជូនដំណឹង'),
        _buildSettingsTile(Icons.language_outlined, 'ភាសា', 'ខ្មែរ'),
        _buildSettingsTile(Icons.help_outline, 'ជំនួយ', 'មើលសំណួរញឹកញាប់'),
        _buildSettingsTile(Icons.info_outline, 'អំពីកម្មវិធី', 'កំណែ ១.០.០'),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.adminBlue),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
    );
  }
}
