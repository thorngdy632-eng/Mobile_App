// lib/screens/admin/admin_statistics_screen.dart
//
// Admin-only screen showing live user statistics:
//   • Total registered users
//   • Total farmers
//   • Total service providers
//   • Monthly growth chart (farmers vs. service providers, last 6 months)
//
// Every number on this screen is computed live from AppProvider.allUsers,
// which is itself a real-time Firestore stream (see app_provider.dart). As
// soon as a user registers, changes role, or is deleted, every number here
// updates automatically — nothing on this screen is static or hard-coded.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'user_list_screen.dart';

// ─── Design tokens (matches admin_dashboard.dart) ─────────────────────────────
const _kNavyDeep = Color(0xFF0A1628);
const _kNavyMid = Color(0xFF0F2040);
const _kAccentBlue = Color(0xFF3B82F6);
const _kAccentCyan = Color(0xFF06B6D4);
const _kAccentGreen = Color(0xFF10B981);
const _kAccentAmber = Color(0xFFF59E0B);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kSurface = Color(0xFF1E2D45);
const _kBorder = Color(0xFF2A3F5F);
const _kTextPrimary = Color(0xFFF1F5F9);
const _kTextSecondary = Color(0xFF94A3B8);
const _kTextMuted = Color(0xFF64748B);

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavyDeep,
      appBar: AppBar(
        backgroundColor: _kNavyMid,
        elevation: 0,
        foregroundColor: _kTextPrimary,
        title: const Text('ស្ថិតិអ្នកប្រើប្រាស់',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProv, _) {
          final monthly = appProv.monthlyUserGrowth(monthsBack: 6);
          final maxVal = monthly
              .map((m) => m.farmerCount > m.providerCount
                  ? m.farmerCount
                  : m.providerCount)
              .fold<int>(0, (a, b) => a > b ? a : b);

          return RefreshIndicator(
            color: _kAccentBlue,
            backgroundColor: _kSurface,
            onRefresh: () async {
              // The data is already a live stream, so a manual refresh has
              // nothing to fetch — this just gives the user the familiar
              // pull-to-refresh affordance and a brief confirmation.
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              children: [
                // ── Totals ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.groups_rounded,
                        value: '${appProv.totalUsersCount}',
                        label: 'អ្នកប្រើប្រាស់សរុប',
                        color: _kAccentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.agriculture_rounded,
                        value: '${appProv.totalFarmersCount}',
                        label: 'កសិករ',
                        color: _kAccentGreen,
                        onTap: () => _openUserList(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.engineering_rounded,
                        value: '${appProv.totalServiceProvidersCount}',
                        label: 'អ្នកផ្តល់សេវា',
                        color: _kAccentAmber,
                        onTap: () => _openUserList(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.admin_panel_settings_rounded,
                        value: '${appProv.totalAdminsCount}',
                        label: 'អ្នកគ្រប់គ្រង',
                        color: _kAccentPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.person_add_rounded,
                        value: '${monthly.isEmpty ? 0 : monthly.last.total}',
                        label: 'ចូលរួមខែនេះ',
                        color: _kAccentCyan,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                const Text('ការកើនឡើងប្រចាំខែ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                const SizedBox(height: 4),
                const Text('កសិករ និង អ្នកផ្តល់សេវា — ៦ខែចុងក្រោយ',
                    style: TextStyle(fontSize: 12, color: _kTextSecondary)),
                const SizedBox(height: 16),

                // ── Monthly growth chart ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: monthly
                              .map((m) => Expanded(
                                    child: _MonthBar(
                                      stat: m,
                                      maxVal: maxVal == 0 ? 1 : maxVal,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: _kAccentGreen, label: 'កសិករ'),
                          const SizedBox(width: 20),
                          _LegendDot(color: _kAccentAmber, label: 'អ្នកផ្តល់សេវា'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Monthly breakdown list ───────────────────────────────
                const Text('លម្អិតប្រចាំខែ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    children: monthly.reversed.toList().asMap().entries.map((e) {
                      final isLast = e.key == monthly.length - 1;
                      final m = e.value;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(m.label,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _kTextPrimary)),
                                const Spacer(),
                                _MiniPill(
                                    color: _kAccentGreen,
                                    text: '${m.farmerCount} កសិករ'),
                                const SizedBox(width: 8),
                                _MiniPill(
                                    color: _kAccentAmber,
                                    text: '${m.providerCount} សេវា'),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(height: 1, color: _kBorder, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openUserList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('អ្នកប្រើប្រាស់'),
            backgroundColor: _kNavyMid,
            foregroundColor: _kTextPrimary,
          ),
          body: const UserListScreen(),
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                          height: 1)),
                  const SizedBox(height: 3),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: _kTextMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Bar chart column for one month ──────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  final MonthlyUserStat stat;
  final int maxVal;

  const _MonthBar({required this.stat, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 120.0;
    final farmerH = maxVal == 0 ? 0.0 : (stat.farmerCount / maxVal) * maxBarHeight;
    final providerH = maxVal == 0 ? 0.0 : (stat.providerCount / maxVal) * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: farmerH.clamp(2.0, maxBarHeight),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: _kAccentGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            Container(
              width: 8,
              height: providerH.clamp(2.0, maxBarHeight),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: _kAccentAmber,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(stat.label,
            style: const TextStyle(fontSize: 10, color: _kTextMuted)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
        ],
      );
}

class _MiniPill extends StatelessWidget {
  final Color color;
  final String text;
  const _MiniPill({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}