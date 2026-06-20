
// lib/screens/provider/provider_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import 'provider_job_detail_screen.dart';

/// Lists all incoming job requests with filters by status and type.
class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});
  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _filter = 'all'; // all | pending | confirmed | completed

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('ការងារទាំងអស់',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(children: [
            // Type tabs
            TabBar(
              controller: _tabs,
              labelColor: AppTheme.providerOrange,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppTheme.providerOrange,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [Tab(text: '🚜 ត្រាក់ទ័រ'), Tab(text: '🛸 ដ្រូន')],
            ),
            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(children: [
                for (final f in _kFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _filter == f.key,
                      onSelected: (_) => setState(() => _filter = f.key),
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.providerOrange.withOpacity(0.15),
                      checkmarkColor: AppTheme.providerOrange,
                      side: BorderSide(
                          color: _filter == f.key ? AppTheme.providerOrange : const Color(0xFFDDDDDD)),
                      labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _filter == f.key ? AppTheme.providerOrange : AppColors.textMuted),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      body: Consumer<AppProvider>(builder: (_, app, __) {
        return TabBarView(
          controller: _tabs,
          children: [
            _buildJobList(
              jobs: app.tractorJobs.where(_applyFilter).map((j) => _JobItem(
                id: j.id,
                farmerName: j.farmerName,
                serviceType: j.serviceType,
                location: j.location,
                date: j.scheduledDate,
                time: j.scheduledTime,
                areaHa: j.areaHectares,
                status: j.status,
                statusLabel: j.statusLabel,
                statusColor: j.statusColor,
                priceUsd: j.areaHectares * 45,
                priceKhr: (j.areaHectares * 45 * 4100).toInt(),
                icon: '🚜',
                notes: j.notes,
                isTractor: true,
              )).toList(),
            ),
            _buildJobList(
              jobs: app.droneJobs.where(_applyDroneFilter).map((j) => _JobItem(
                id: j.id,
                farmerName: j.farmerName,
                serviceType: 'ដ្រូន ${j.cropType}',
                location: j.location,
                date: j.scheduledDate,
                time: j.scheduledTime,
                areaHa: j.areaHectares,
                status: j.status,
                statusLabel: j.statusLabel,
                statusColor: j.statusColor,
                priceUsd: j.areaHectares * 30,
                priceKhr: (j.areaHectares * 30 * 4100).toInt(),
                icon: '🛸',
                notes: j.notes,
                isTractor: false,
              )).toList(),
            ),
          ],
        );
      }),
    );
  }

  bool _applyFilter(TractorJob j) =>
      _filter == 'all' || j.status == _filter;
  bool _applyDroneFilter(DroneJob j) =>
      _filter == 'all' || j.status == _filter;

  Widget _buildJobList({required List<_JobItem> jobs}) {
    if (jobs.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('📋', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(_filter == 'all' ? 'គ្មានការងារ' : 'គ្មានការងារ "${_kFilters.firstWhere((f) => f.key == _filter).label}"',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (_, i) => _JobCard(job: jobs[i]),
    );
  }
}

// ── Static filter definitions ─────────────────────────────────────────────────
class _FilterDef {
  final String key, label;
  const _FilterDef(this.key, this.label);
}
const List<_FilterDef> _kFilters = [
  _FilterDef('all', 'ទាំងអស់'),
  _FilterDef('pending', '⏳ រង់ចាំ'),
  _FilterDef('confirmed', '✅ បញ្ជាក់'),
  _FilterDef('completed', '🏁 បានបញ្ចប់'),
  _FilterDef('cancelled', '❌ បោះបង់'),
];

// ── Job Item model ────────────────────────────────────────────────────────────
class _JobItem {
  final String id, farmerName, serviceType, location, date, time, status, statusLabel, icon;
  final double areaHa, priceUsd;
  final int priceKhr;
  final Color statusColor;
  final String? notes;
  final bool isTractor;
  const _JobItem({required this.id, required this.farmerName, required this.serviceType,
      required this.location, required this.date, required this.time,
      required this.areaHa, required this.status, required this.statusLabel,
      required this.statusColor, required this.priceUsd, required this.priceKhr,
      required this.icon, this.notes, required this.isTractor});
}

// ── Job Card ──────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final _JobItem job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProviderJobDetailScreen(jobId: job.id, isTractor: job.isTractor))),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Text(job.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.serviceType,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
            Text('👤 ${job.farmerName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: job.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: job.statusColor.withOpacity(0.3)),
            ),
            child: Text(job.statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: job.statusColor)),
          ),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 12),

        // Info grid
        Row(children: [
          _MiniInfo(icon: Icons.location_on_outlined, text: job.location),
          const SizedBox(width: 16),
          _MiniInfo(icon: Icons.crop_square_rounded, text: '${job.areaHa.toStringAsFixed(1)} ha'),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _MiniInfo(icon: Icons.calendar_today_outlined, text: job.date),
          const SizedBox(width: 16),
          _MiniInfo(icon: Icons.schedule_rounded, text: job.time),
        ]),

        const SizedBox(height: 12),
        // Price footer
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${job.priceKhr.toStringAsFixed(0)} ៛',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            Text('≈ ${_fmtKhr(job.priceKhr)} ៛',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
        ]),
      ]),
    ),
  );

  String _fmtKhr(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfo({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
  ]);
}