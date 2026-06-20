// lib/screens/provider/tabs/provider_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/service_request.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import '../provider_map_screen.dart';

/// Lists every [ServiceRequest] relevant to this Service Provider, filtered
/// by status. Always scoped to the signed-in provider's own `serviceType`
/// (for pending requests) and to requests they personally accepted (for
/// confirmed/completed/cancelled), so two providers never see each other's
/// queues. Tapping any card opens the same accept/decline/chat sheet used
/// on the map tab — no separate, view-only detail screen.
class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});
  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen> {
  String _filter = 'pending'; // pending | accepted | completed | cancelled
  Position? _myPosition;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {
      // Distance simply won't be shown if location is unavailable.
    }
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
          preferredSize: const Size.fromHeight(58),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
        ),
      ),
      body: Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
        final myUid = auth.currentUser?.uid ?? '';
        final myServiceType = auth.currentUser?.serviceType ?? ServiceTypes.plowing;

        List<ServiceRequest> jobs;
        if (_filter == 'pending') {
          // Every pending request matching my service type that I haven't
          // already declined — exactly what the map tab shows.
          jobs = app.pendingServiceRequestsForProvider(myServiceType, excludeDeclinedBy: myUid);
        } else {
          // Everything I personally accepted, then narrowed by status.
          jobs = app.serviceRequests
              .where((r) => r.providerUid == myUid && r.status == _filter)
              .toList();
        }

        if (jobs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('គ្មានការងារ "${_kFilters.firstWhere((f) => f.key == _filter).label}"',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (_, i) => _JobCard(
            request: jobs[i],
            myUid: myUid,
            myPosition: _myPosition,
          ),
        );
      }),
    );
  }
}

// ── Static filter definitions ─────────────────────────────────────────────────
class _FilterDef {
  final String key, label;
  const _FilterDef(this.key, this.label);
}
const List<_FilterDef> _kFilters = [
  _FilterDef('pending', '⏳ ថ្មី / រង់ចាំ'),
  _FilterDef('accepted', '✅ បានទទួល'),
  _FilterDef('completed', '🏁 បានបញ្ចប់'),
  _FilterDef('cancelled', '❌ បានបោះបង់'),
];

// ── Job Card ──────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final ServiceRequest request;
  final String myUid;
  final Position? myPosition;
  const _JobCard({required this.request, required this.myUid, this.myPosition});

  @override
  Widget build(BuildContext context) {
    final info = ServiceTypes.infoOf(request.serviceType);
    final Color color = info['color'] as Color;
    final IconData icon = info['icon'] as IconData;
    final app = context.read<AppProvider>();

    double? distanceKm;
    if (myPosition != null) {
      distanceKm = app.distanceToRequestKm(
        providerLat: myPosition!.latitude,
        providerLng: myPosition!.longitude,
        request: request,
      );
    }

    return GestureDetector(
      onTap: () => showRequestDetailSheet(
        context: context,
        request: request,
        myUid: myUid,
        myPosition: myPosition,
      ),
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
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Icon(icon, color: color, size: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(info['label'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
              Text('👤 ${request.farmerName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: request.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: request.statusColor.withOpacity(0.3)),
                ),
                child: Text(request.statusLabel,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: request.statusColor)),
              ),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Info grid
          Row(children: [
            _MiniInfo(icon: Icons.location_on_outlined, text: request.currentAddress),
            const SizedBox(width: 16),
            _MiniInfo(icon: Icons.crop_square_rounded, text: request.landLabel),
          ]),
          if (distanceKm != null) ...[
            const SizedBox(height: 6),
            _MiniInfo(icon: Icons.social_distance_rounded, text: '${distanceKm.toStringAsFixed(1)} គម ពីអ្នក'),
          ],

          const SizedBox(height: 12),
          // Price footer
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${request.offerPrice.toStringAsFixed(0)} ៛',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
              Text('≈ \$${(request.offerPrice / 4100).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ]),
        ]),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfo({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(children: [
      Icon(icon, size: 13, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
    ]),
  );
}
