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

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});
  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen> {
  String _filter = 'pending';
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
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ការងារទាំងអស់',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                  const SizedBox(height: 14),
                  // ── Filter tabs ──
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: _kFilters.map((f) {
                        final selected = _filter == f.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: selected
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(f.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected ? AppTheme.providerOrange : AppColors.textMuted,
                                    )),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Job list ──
            Expanded(
              child: Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
                final myUid = auth.currentUser?.uid ?? '';
                final myServiceType = auth.currentUser?.serviceType ?? ServiceTypes.plowing;

                List<ServiceRequest> jobs;
                if (_filter == 'pending') {
                  jobs = app.pendingServiceRequestsForProvider(myServiceType, excludeDeclinedBy: myUid);
                } else {
                  jobs = app.serviceRequests
                      .where((r) => r.providerUid == myUid && r.status == _filter)
                      .toList();
                }

                if (jobs.isEmpty) {
                  return _buildEmpty(_filter);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _JobCard(
                    request: jobs[i],
                    myUid: myUid,
                    myPosition: _myPosition,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String filter) {
    final label = _kFilters.firstWhere((f) => f.key == filter).label;
    final icons = {
      'pending': Icons.hourglass_empty_rounded,
      'accepted': Icons.check_circle_outline_rounded,
      'completed': Icons.task_alt_rounded,
      'cancelled': Icons.cancel_outlined,
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.providerOrange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icons[filter] ?? Icons.inbox_rounded,
                size: 48, color: AppTheme.providerOrange.withOpacity(0.35)),
          ),
          const SizedBox(height: 20),
          Text('គ្មានការងារ "$label"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2D3142))),
          const SizedBox(height: 6),
          const Text('ការងារនឹងបង្ហាញនៅទីនេះនៅពេលមានសំណើថ្មី',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Filter definitions ────────────────────────────────────────────────────────
class _FilterDef {
  final String key, label;
  const _FilterDef(this.key, this.label);
}
const List<_FilterDef> _kFilters = [
  _FilterDef('pending', 'ថ្មី'),
  _FilterDef('accepted', 'បានទទួល'),
  _FilterDef('completed', 'បានបញ្ចប់'),
  _FilterDef('cancelled', 'បោះបង់'),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: service icon + info + status ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Service image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        _getServiceImage(request.serviceType),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(info['icon'] as IconData, color: color, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info['label'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(request.farmerName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(request.statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: request.statusColor)),
                  ),
                ],
              ),
            ),

            // ── Details row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  _DetailChip(icon: Icons.location_on_outlined, text: request.currentAddress),
                  const SizedBox(width: 10),
                  _DetailChip(icon: Icons.landscape_rounded, text: request.landLabel),
                  if (distanceKm != null) ...[
                    const SizedBox(width: 10),
                    _DetailChip(icon: Icons.social_distance_rounded, text: '${distanceKm.toStringAsFixed(1)} គម'),
                  ],
                ],
              ),
            ),

            // ── Bottom: price + arrow ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${request.offerPrice.toStringAsFixed(0)} រៀល',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                      const SizedBox(height: 1),
                      Text('≈ \$${(request.offerPrice / 4100).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.providerOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppTheme.providerOrange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getServiceImage(String serviceType) {
    const map = {
      'plowing': 'assets/images/1.png',
      'harvesting': 'assets/images/2.png',
      'transport': 'assets/images/3.png',
      'irrigation': 'assets/images/4.png',
      'drone_spray': 'assets/images/5.png',
    };
    return map[serviceType] ?? 'assets/images/app_icon.png';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    ),
  );
}
