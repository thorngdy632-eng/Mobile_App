// lib/screens/provider/provider_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import '../../profile/edit_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import 'provider_job_detail_screen.dart';

/// The main dashboard tab for Service Providers.
/// Shows:
///   • Hero header with greeting + stats
///   • 5 service category cards (with provider's active category highlighted)
///   • Urgent / new incoming job alerts
///   • Today's schedule
///   • Earnings overview
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});
  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  final ScrollController _scroll = ScrollController();
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > 60;
      if (c != _headerCollapsed) setState(() => _headerCollapsed = c);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _HeroHeader(collapsed: _headerCollapsed)),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildNewJobAlerts()),
          SliverToBoxAdapter(child: _buildTodaySchedule()),
          SliverToBoxAdapter(child: _buildEarningsCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Quick Stats ─────────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    return Consumer<AppProvider>(builder: (_, app, __) {
      final pending = app.pendingTractorJobs.length + app.pendingDroneJobs.length;
      final total = app.tractorJobs.length + app.droneJobs.length;
      final done = app.tractorJobs.where((j) => j.status == 'completed').length +
          app.droneJobs.where((j) => j.status == 'completed').length;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Expanded(child: _StatCard(value: '$pending', label: 'ការងារថ្មី', icon: Icons.notification_important_rounded, color: const Color(0xFFE53935))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(value: '$total', label: 'ការងារសរុប', icon: Icons.work_rounded, color: AppTheme.providerOrange)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(value: '$done', label: 'បានបញ្ចប់', icon: Icons.check_circle_rounded, color: const Color(0xFF43A047))),
        ]),
      );
    });
  }

  // ── New Job Alerts ──────────────────────────────────────────────────────────
  Widget _buildNewJobAlerts() {
    return Consumer<AppProvider>(builder: (_, app, __) {
      final newJobs = <_IncomingJob>[];
      for (final j in app.pendingTractorJobs.take(5)) {
        newJobs.add(_IncomingJob(
          id: j.id,
          farmerName: j.farmerName,
          serviceType: j.serviceType,
          location: j.location,
          areaHa: j.areaHectares,
          date: j.scheduledDate,
          time: j.scheduledTime,
          priceSuggest: (j.areaHectares * 45).toStringAsFixed(0),
          priceSuggestKhr: (j.areaHectares * 45 * 4100).toStringAsFixed(0),
          icon: '🚜',
          color: const Color(0xFF1565C0),
          isTractor: true,
        ));
      }
      for (final j in app.pendingDroneJobs.take(5)) {
        newJobs.add(_IncomingJob(
          id: j.id,
          farmerName: j.farmerName,
          serviceType: 'ដ្រូនបាញ់ ${j.cropType}',
          location: j.location,
          areaHa: j.areaHectares,
          date: j.scheduledDate,
          time: j.scheduledTime,
          priceSuggest: (j.areaHectares * 30).toStringAsFixed(0),
          priceSuggestKhr: (j.areaHectares * 30 * 4100).toStringAsFixed(0),
          icon: '🛸',
          color: const Color(0xFF00838F),
          isTractor: false,
        ));
      }

      if (newJobs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: _SectionHeader(title: 'ការជូនដំណឹងថ្មី', sub: 'គ្មានការងារថ្មី'),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _SectionHeader(title: 'ការជូនដំណឹងថ្មី 🔔', sub: '${newJobs.length} ការងាររង់ចាំ'),
        ),
        ...newJobs.map((job) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _JobAlertCard(job: job),
        )),
      ]);
    });
  }

  // ── Today Schedule ──────────────────────────────────────────────────────────
  Widget _buildTodaySchedule() {
    return Consumer<AppProvider>(builder: (_, app, __) {
      final confirmed = [
        ...app.tractorJobs.where((j) => j.status == 'confirmed').take(3),
      ];
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _SectionHeader(title: 'កាលវិភាគថ្ងៃនេះ', sub: '${confirmed.length} ការងារ'),
        ),
        if (confirmed.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Row(children: [
                Icon(Icons.event_available_rounded, color: Color(0xFF9E9E9E)),
                SizedBox(width: 12),
                Text('គ្មានការងារបញ្ជាក់ថ្ងៃនេះ', style: TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          )
        else
          ...confirmed.map((j) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _ScheduleCard(
              service: j.serviceType,
              location: j.location,
              date: j.scheduledDate,
              time: j.scheduledTime,
              areaHa: j.areaHectares,
            ),
          )),
      ]);
    });
  }

  // ── Earnings Card ───────────────────────────────────────────────────────────
  Widget _buildEarningsCard() {
    return Consumer<AppProvider>(builder: (_, app, __) {
      final completed = app.tractorJobs.where((j) => j.status == 'completed').toList();
      final totalUsd = completed.fold(0.0, (sum, j) => sum + (j.areaHectares * 45));
      final totalKhr = (totalUsd * 4100).toInt();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('ប្រាក់ចំណូលសរុប', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text('${totalKhr.toStringAsFixed(0)} ៛',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${_fmtKhr(totalKhr)} ៛',
              style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _EarningsSub(label: 'ការងារបញ្ចប់', value: '${completed.length} ការងារ')),
            const SizedBox(width: 16),
            Expanded(child: _EarningsSub(label: 'ហិចតា​សរុប',
                value: '${completed.fold(0.0, (s, j) => s + j.areaHectares).toStringAsFixed(1)} ha')),
          ]),
        ]),
      );
    });
  }

  String _fmtKhr(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return '$amount';
  }
}

// ── Hero Header Widget ────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool collapsed;
  const _HeroHeader({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final app = context.watch<AppProvider>();
    final topPad = MediaQuery.of(context).padding.top;
    final pending = app.pendingTractorJobs.length + app.pendingDroneJobs.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B2A1E), Color(0xFF2D4A30), Color(0xFFE65100)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                .then((_) => context.read<AuthProvider>().refreshProfile()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.providerOrange, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.providerOrange.withOpacity(0.3),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ស្វាគមន៍មក', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text(user?.fullName ?? 'អ្នកផ្តល់សេវា',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Notification bell
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
              ),
              if (pending > 0)
                Positioned(
                  top: -2, right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ]),
          ),
        ]),

        if (!collapsed) ...[
          const SizedBox(height: 20),
          // Service badge
          if (user?.serviceType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⚙️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(user!.serviceType!,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 10),
          const Text('ផ្ទាំងគ្រប់គ្រងសេវា',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
          const Text('ទទួលការងារ · ផ្ញើការងារ · ចំណូល',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ]),
    );
  }
}

// ── Sub widgets ───────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, sub;
  const _SectionHeader({required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)))),
    Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Incoming Job Alert Card ────────────────────────────────────────────────────
class _IncomingJob {
  final String id, farmerName, serviceType, location, date, time;
  final double areaHa;
  final String priceSuggest, priceSuggestKhr, icon;
  final Color color;
  final bool isTractor;
  const _IncomingJob({required this.id, required this.farmerName, required this.serviceType,
      required this.location, required this.areaHa, required this.date, required this.time,
      required this.priceSuggest, required this.priceSuggestKhr, required this.icon,
      required this.color, required this.isTractor});
}

class _JobAlertCard extends StatelessWidget {
  final _IncomingJob job;
  const _JobAlertCard({required this.job});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProviderJobDetailScreen(jobId: job.id, isTractor: job.isTractor))),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: job.color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: job.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(job.icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(job.serviceType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('ថ្មី🔔', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
              ),
            ]),
            const SizedBox(height: 3),
            Text('👤 ${job.farmerName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(height: 1, color: const Color(0xFFF0F0F0)),
        const SizedBox(height: 12),

        // Details grid
        Row(children: [
          Expanded(child: _InfoCell(icon: Icons.location_on_rounded, label: 'ទីតាំង', value: job.location, color: job.color)),
          const SizedBox(width: 8),
          Expanded(child: _InfoCell(icon: Icons.crop_square_rounded, label: 'ស្រែ (ហិចតា)', value: '${job.areaHa.toStringAsFixed(1)} ha', color: job.color)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _InfoCell(icon: Icons.calendar_today_rounded, label: 'កាលបរិច្ឆេទ', value: job.date, color: job.color)),
          const SizedBox(width: 8),
          Expanded(child: _InfoCell(icon: Icons.access_time_rounded, label: 'ម៉ោង', value: job.time, color: job.color)),
        ]),

        const SizedBox(height: 12),
        // Price row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Row(children: [
            const Icon(Icons.attach_money_rounded, color: Color(0xFF43A047), size: 20),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${job.priceSuggestKhr} ៛',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
              Text('≈ ${job.priceSuggestKhr} ៛',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            ]),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProviderJobDetailScreen(jobId: job.id, isTractor: job.isTractor))),
              style: ElevatedButton.styleFrom(
                backgroundColor: job.color,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('មើល', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    ),
  );
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoCell({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2D3142)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _ScheduleCard extends StatelessWidget {
  final String service, location, date, time;
  final double areaHa;
  const _ScheduleCard({required this.service, required this.location,
      required this.date, required this.time, required this.areaHa});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        width: 4, height: 50,
        decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2D3142))),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        ]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
        const SizedBox(height: 2),
        Text('${areaHa.toStringAsFixed(1)} ha', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    ]),
  );
}

class _EarningsSub extends StatelessWidget {
  final String label, value;
  const _EarningsSub({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}