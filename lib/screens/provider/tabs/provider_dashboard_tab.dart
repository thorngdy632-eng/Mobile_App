// lib/screens/provider/tabs/provider_dashboard_tab.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/service_request.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import '../../profile/edit_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../provider_map_screen.dart';

class _ImgCfg {
  final String imagePath;
  const _ImgCfg(this.imagePath);
}

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png'),
  'harvesting':  _ImgCfg('assets/images/2.png'),
  'drone_spray': _ImgCfg('assets/images/5.png'),
  'transport':   _ImgCfg('assets/images/3.png'),
  'irrigation':  _ImgCfg('assets/images/4.png'),
};

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
  Position? _myPosition;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > 60;
      if (c != _headerCollapsed) setState(() => _headerCollapsed = c);
    });
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
      // Silently ignore — distance simply won't be shown.
    }
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
    return Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
      final myUid = auth.currentUser?.uid ?? '';
      final myServiceType = auth.currentUser?.serviceType ?? ServiceTypes.plowing;

      final pending = app
          .pendingServiceRequestsForProvider(myServiceType, excludeDeclinedBy: myUid)
          .length;
      final mine = app.serviceRequests.where((r) => r.providerUid == myUid).toList();
      final total = mine.length;
      final done = mine.where((r) => r.status == 'completed').length;

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
    return Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
      final myUid = auth.currentUser?.uid ?? '';
      final myServiceType = auth.currentUser?.serviceType ?? ServiceTypes.plowing;

      final pending = app.pendingServiceRequestsForProvider(
        myServiceType,
        excludeDeclinedBy: myUid,
      );

      if (pending.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: _SectionHeader(title: 'ការជូនដំណឹងថ្មី', sub: 'គ្មានការងារថ្មី'),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _SectionHeader(title: 'ការជូនដំណឹងថ្មី', sub: '${pending.length} ការងាររង់ចាំ'),
        ),
        ...pending.take(5).map((r) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _JobAlertCard(
            request: r,
            myUid: myUid,
            myPosition: _myPosition,
          ),
        )),
      ]);
    });
  }

  // ── Today Schedule ──────────────────────────────────────────────────────────
  Widget _buildTodaySchedule() {
    return Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
      final myUid = auth.currentUser?.uid ?? '';
      final accepted = app.acceptedServiceRequestsForProvider(myUid).take(3).toList();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _SectionHeader(title: 'ការងារដែលបានទទួល', sub: '${accepted.length} ការងារ'),
        ),
        if (accepted.isEmpty)
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
                Text('គ្មានការងារដែលបានទទួលនៅឡើយ', style: TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          )
        else
          ...accepted.map((r) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              onTap: () => showRequestDetailSheet(
                context: context,
                request: r,
                myUid: myUid,
                myPosition: _myPosition,
              ),
              child: _ScheduleCard(
                service: ServiceTypes.labelOf(r.serviceType),
                farmerName: r.farmerName,
                location: r.currentAddress,
                landLabel: r.landLabel,
                offerPrice: r.offerPrice,
              ),
            ),
          )),
      ]);
    });
  }

  // ── Earnings Card ───────────────────────────────────────────────────────────
  Widget _buildEarningsCard() {
    return Consumer2<AppProvider, AuthProvider>(builder: (_, app, auth, __) {
      final myUid = auth.currentUser?.uid ?? '';
      final completed = app.serviceRequests
          .where((r) => r.providerUid == myUid && r.status == 'completed')
          .toList();

      // offerPrice is stored in Riel (KHR) — see _RequestFormSheet's default
      // currency. ~4,100 KHR per USD is used app-wide as the display rate.
      final totalKhr = completed.fold(0.0, (sum, r) => sum + r.offerPrice);
      final totalUsd = totalKhr / 4100;
      final totalHectares = completed.fold(0.0, (sum, r) {
        final unit = LandUnitX.fromString(r.landUnit);
        // Normalize rai → hectare for the summary (1 rai ≈ 0.16 ha) so the
        // total is meaningful even when farmers mix units.
        final ha = unit == LandUnit.rai ? r.landArea * 0.16 : r.landArea;
        return sum + ha;
      });

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
          Text('≈ \$${totalUsd.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _EarningsSub(label: 'ការងារបញ្ចប់', value: '${completed.length} ការងារ')),
            const SizedBox(width: 16),
            Expanded(child: _EarningsSub(label: 'ផ្ទៃដីសរុប', value: '${totalHectares.toStringAsFixed(1)} ha')),
          ]),
        ]),
      );
    });
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
    final myUid = user?.uid ?? '';
    final myServiceType = user?.serviceType ?? ServiceTypes.plowing;
    final pending = app
        .pendingServiceRequestsForProvider(myServiceType, excludeDeclinedBy: myUid)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2A1E), Color(0xFF2D4A30), Color(0xFFE65100)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/background_home_screen.jfif'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
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
                backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                    ? (() {
                        try { return MemoryImage(base64Decode(user.profileImageUrl!)); } catch (_) { return null; }
                      })()
                    : null,
                child: (user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person_rounded, color: Colors.white, size: 26)
                    : null,
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

        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: collapsed ? 0 : null,
              child: Opacity(
                opacity: collapsed ? 0.0 : 1.0,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            _serviceImgCfgs[user!.serviceType]?.imagePath ?? 'assets/images/app_icon.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                ServiceTypes.infoOf(user.serviceType!)['icon'] as IconData,
                                size: 14, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(ServiceTypes.labelOf(user.serviceType!),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  const Text('ផ្ទាំងគ្រប់គ្រងសេវា',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
                  const Text('ទទួលការងារ · ផ្ញើការងារ · ចំណូល',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
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
//
// Built directly off a live ServiceRequest (the same model the map screen
// uses) so the farmer's name, location, land size, and offer price are
// always the real data for *this* request — never placeholder/static values.
class _JobAlertCard extends StatelessWidget {
  final ServiceRequest request;
  final String myUid;
  final Position? myPosition;
  const _JobAlertCard({required this.request, required this.myUid, this.myPosition});

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

    void open() => showRequestDetailSheet(
          context: context,
          request: request,
          myUid: myUid,
          myPosition: myPosition,
        );

    return GestureDetector(
      onTap: open,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _serviceImgCfgs[request.serviceType]?.imagePath ?? 'assets/images/app_icon.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(info['label'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ថ្មី', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
                ),
              ]),
              const SizedBox(height: 3),
              Text(request.farmerName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Details grid
          Row(children: [
            Expanded(child: _InfoCell(icon: Icons.location_on_rounded, label: 'ទីតាំង', value: request.currentAddress, color: color)),
            const SizedBox(width: 8),
            Expanded(child: _InfoCell(icon: Icons.crop_square_rounded, label: 'ផ្ទៃដី', value: request.landLabel, color: color)),
          ]),
          if (distanceKm != null) ...[
            const SizedBox(height: 8),
            _InfoCell(icon: Icons.social_distance_rounded, label: 'ចម្ងាយពីអ្នក', value: '${distanceKm.toStringAsFixed(1)} គម', color: color),
          ],

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
              const Icon(Icons.payments_rounded, color: Color(0xFF43A047), size: 20),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${request.offerPrice.toStringAsFixed(0)} ៛',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                Text('≈ \$${(request.offerPrice / 4100).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              ]),
              const Spacer(),
              ElevatedButton(
                onPressed: open,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
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
  final String service, farmerName, location, landLabel;
  final double offerPrice;
  const _ScheduleCard({required this.service, required this.farmerName,
      required this.location, required this.landLabel, required this.offerPrice});

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
        const SizedBox(height: 2),
        Text(farmerName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        ]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${offerPrice.toStringAsFixed(0)} ៛',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
        const SizedBox(height: 2),
        Text(landLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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