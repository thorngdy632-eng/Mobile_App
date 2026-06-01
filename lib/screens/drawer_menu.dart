// lib/screens/drawer_menu.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// No import of android_nav_bar or android_status_bar — both deleted.

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          // MediaQuery.of(context).padding.top gives the REAL device status-bar
          // height (e.g. 44 px on iPhone 14, 24 px on Pixel) so the header
          // content is never hidden behind the status bar on any device.
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
              // top inset = real status-bar height + 16 px visual breathing room
              padding: EdgeInsets.fromLTRB(16, statusBarHeight + 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'បង សុខា',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+855 12 345 678',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 14),
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
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ចេញពីប្រព័ន្ធ?'),
                        content:
                            const Text('តើអ្នកប្រាកដចង់ចេញពីប្រព័ន្ធ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ទេ'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context),
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
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
