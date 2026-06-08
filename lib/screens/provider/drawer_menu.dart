// lib/screens/drawer_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // ── Header — reads real user data from AuthProvider ────────────────
          Builder(builder: (context) {
            final statusBarHeight = MediaQuery.of(context).padding.top;
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, statusBarHeight + 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    // Show first letter of name if available
                    child: user?.fullName.isNotEmpty == true
                        ? Text(
                            user!.fullName[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),
                  // Real full name from Firestore
                  Text(
                    user?.fullName ?? 'កសិករ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  // Real phone number from Firestore
                  Text(
                    user?.phoneNumber ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  // Role badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.roleDisplayName ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Menu items ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'ផ្ទាំងគ្រប់គ្រង',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'កាលវិភាគ',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('មុខងារកំពុងអភិវឌ្ឍ')),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'ការដឹកជញ្ជូន',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('មុខងារកំពុងអភិវឌ្ឍ')),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'របាយការណ៍',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('មុខងារកំពុងអភិវឌ្ឍ')),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'ការកំណត់',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('មុខងារកំពុងអភិវឌ្ឍ')),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'ចេញ',
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    final mainNavigator = Navigator.of(context);
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        title: const Text('ចេញពីប្រព័ន្ធ?',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('តើអ្នកប្រាកដចញ្ចង់ចេញពីប្រព័ន្ធ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('ទេ',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await auth.logout();
                            },
                            child: const Text('បាទ ចេញ'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Version footer ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'កំណែ 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}