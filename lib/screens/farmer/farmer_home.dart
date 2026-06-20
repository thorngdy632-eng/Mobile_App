// lib/screens/farmer/farmer_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../models/equipment_item.dart';
import '../../models/service_request.dart';
import '../../widgets/job_card.dart';
import '../chat/chat_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../provider/notifications/notifications_screen.dart';
import '../provider/jobs/job_detail_screen.dart';
import '../provider/jobs/all_jobs_screen.dart';
import '../provider/equipment/equipment_detail_screen.dart';
import 'farmer_map_screen.dart';
import 'my_service_requests_screen.dart';
import 'service_request_map_screen.dart';

// ─── Static data ─────────────────────────────────────────────────────────────

const List<_PromoItem> _promos = [
  _PromoItem(
    tag: 'ចំណេញ ១០០%',
    title: 'សហគមន៍ភូមិកំពង់ចំបក់\nតាមរយៈ Escrow',
    subtitle: 'ធ្វើការ · ABA · KHQR',
    accentColor: Color(0xFFFF7043),
    icon: Icons.verified_outlined,
  ),
  _PromoItem(
    tag: 'ថ្មី',
    title: 'ជួលត្រាក់ទ័រ Kubota\nតម្លៃពិសេសសម្រាប់ម្ចាស់ដំណាំ',
    subtitle: 'តុក្កតា · ABA',
    accentColor: Color(0xFF66BB6A),
    icon: Icons.agriculture_outlined,
  ),
];

final List<EquipmentItem> _equipment = [
  const EquipmentItem(
    name: 'គ្រឿង Kubota L3408',
    price: '45,000រៀល',
    location: 'ស្រុកបាទី',
    rating: 4.9,
    imageAsset: 'tractor',
    badge: EquipmentBadge.none,
  ),
  const EquipmentItem(
    name: 'យន្តហោះ Yanmar YT3',
    price: '120,000រៀល',
    location: 'ក្រុងសិរីស្វាយប៉ាវ',
    rating: 4.7,
    imageAsset: 'harvester',
    badge: EquipmentBadge.hot,
  ),
];

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png', Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'harvesting':  _ImgCfg('assets/images/2.png', Color(0xFFFFF8E1), Color(0xFFF9A825)),
  'drone_spray': _ImgCfg('assets/images/5.png', Color(0xFFFFEBEE), Color(0xFFEF5350)),
  'transport':   _ImgCfg('assets/images/3.png', Color(0xFFE8F5E9), Color(0xFF43A047)),
  'irrigation':  _ImgCfg('assets/images/4.png', Color(0xFFE3F2FD), Color(0xFF1E88E5)),
};

// ─── Design tokens ────────────────────────────────────────────────────────────

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF43A047);
const _kGreenDark = Color(0xFF1B5E20);
const _kSurface = Color(0xFFF7F9F7);
const _kCard = Colors.white;
const _kDivider = Color(0xFFF0F0F0);

// ─── FarmerHome ───────────────────────────────────────────────────────────────

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _tab = 0;
  int _promoPage = 0;
  final PageController _promoCtrl = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.watch<AuthProvider>().currentUser?.uid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _FarmerDrawer(
          onNavigate: (i) {
            Navigator.pop(context);
            setState(() => _tab = i);
          },
        ),
        backgroundColor: _kSurface,
        body: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(
              promoCtrl: _promoCtrl,
              promoPage: _promoPage,
              onPromoPage: (i) => setState(() => _promoPage = i),
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onTabChange: (i) => setState(() => _tab = i),
            ),
            const FarmerMapScreen(),
            _ChatTab(myUid: myUid),
            const _ProfileTab(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          current: _tab,
          myUid: myUid,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

// ─── Sidebar Drawer ──────────────────────────────────────────────────────────

class _FarmerDrawer extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;
  const _FarmerDrawer({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final app = context.watch<AppProvider>();
    final myUid = user?.uid ?? '';
    final pendingCount = app.serviceRequestsForFarmer(myUid)
        .where((r) => r.status == 'pending')
        .length;

    ImageProvider? avatar;
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.profileImageUrl!));
      } catch (_) {}
    }

    return Drawer(
      backgroundColor: _kCard,
      child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreenDark, _kGreen, _kGreenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Text(
                          user?.fullName != null && user!.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '👨‍🌾',
                          style: const TextStyle(
                              fontSize: 28, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'កសិករ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🌾 កសិករ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                if (user?.address != null && user!.address!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.address!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Nav items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'ទំព័រដើម',
                  onTap: () => onNavigate(0),
                ),
                _DrawerItem(
                  icon: Icons.map_rounded,
                  label: 'ផែនទីសេវាកម្ម',
                  onTap: () => onNavigate(1),
                ),
                _DrawerItem(
                  icon: Icons.list_alt_rounded,
                  label: 'សំណើរបស់ខ្ញុំ',
                  badge: pendingCount > 0 ? '$pendingCount' : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyServiceRequestsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'ការសន្ទនា',
                  onTap: () => onNavigate(2),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'ការជូនដំណឹង',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'ទំនិញទាំងអស់',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllJobsScreen()),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: _kDivider),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'គណនី',
                  onTap: () => onNavigate(3),
                ),
                _DrawerItem(
                  icon: Icons.edit_rounded,
                  label: 'កែប្រែព័ត៌មាន',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ).then((_) =>
                        context.read<AuthProvider>().refreshProfile());
                  },
                ),
              ],
            ),
          ),

          // ── Logout ──
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFFD32F2F), size: 18),
                label: const Text('ចេញពីគណនី',
                    style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  backgroundColor: const Color(0xFFFFF5F5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kGreen, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121)),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            )
          : null,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final String myUid;
  final void Function(int) onTap;

  const _BottomNav(
      {required this.current, required this.myUid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context.read<ChatProvider>().totalUnreadStream(myUid),
      builder: (context, snap) {
        final unread = snap.data ?? 0;
        return Container(
          decoration: const BoxDecoration(
            color: _kCard,
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'ដើម',
                      active: current == 0,
                      onTap: () => onTap(0)),
                  _NavItem(
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      label: 'ផែនទី',
                      active: current == 1,
                      onTap: () => onTap(1)),
                  _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'ការសន្ទនា',
                      active: current == 2,
                      badge: unread > 0 ? (unread > 9 ? '9+' : '$unread') : null,
                      onTap: () => onTap(2)),
                  _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'គណនី',
                      active: current == 3,
                      onTap: () => onTap(3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kGreen.withOpacity(0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon,
                    size: 24,
                    color: active ? _kGreen : const Color(0xFF9E9E9E)),
                if (badge != null)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F), shape: BoxShape.circle),
                      child: Text(badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _kGreen : const Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final PageController promoCtrl;
  final int promoPage;
  final void Function(int) onPromoPage;
  final VoidCallback onOpenDrawer;
  final void Function(int) onTabChange;

  const _HomeTab({
    required this.promoCtrl,
    required this.promoPage,
    required this.onPromoPage,
    required this.onOpenDrawer,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return CustomScrollView(
      slivers: [
        // ── Sticky hero header ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeroHeaderDelegate(
            user: user,
            onMenuTap: onOpenDrawer,
            onNotificationTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            onAvatarTap: () => onTabChange(3),
          ),
        ),

        // ── Search bar ──
        SliverToBoxAdapter(child: _SearchBar()),

        // ── Quick service tiles ──
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'ស្នើសេវាកម្ម',
            action: '',
            onAction: null,
          ),
        ),
        SliverToBoxAdapter(child: _ServiceTilesGrid()),

        // ── Promo banner ──
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'ការផ្សព្វផ្សាយ',
            action: 'ទាំងអស់',
            onAction: () {},
          ),
        ),
        SliverToBoxAdapter(
          child: _PromoBanner(
            ctrl: promoCtrl,
            page: promoPage,
            onPage: onPromoPage,
          ),
        ),

        // ── My pending requests strip ──
        SliverToBoxAdapter(
          child: _MyRequestsStrip(user: user),
        ),

        // ── Scheduled jobs ──
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'ការងារបច្ចុប្បន្ន',
            action: '',
            onAction: null,
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<AppProvider>(
            builder: (_, prov, __) => prov.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()))
                : Column(
                    children: prov.scheduledJobs
                        .map((job) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: JobCard(
                                job: job,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          JobDetailScreen(job: job)),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),

        // ── Equipment ──
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'ទំនិញពេញនិយម',
            action: 'ទាំងអស់',
            onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AllJobsScreen())),
          ),
        ),
        SliverToBoxAdapter(child: _EquipmentRow()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

// ─── Hero header (SliverPersistentHeader) ─────────────────────────────────────

class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final dynamic user;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;

  _HeroHeaderDelegate({
    required this.user,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.onAvatarTap,
  });

  @override
  double get minExtent => kToolbarHeight + 40;
  @override
  double get maxExtent => 168;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final top = MediaQuery.of(context).padding.top;

    ImageProvider? avatar;
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user!.profileImageUrl!));
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.6), width: 2),
                    color: Colors.white.withOpacity(0.15),
                    image: avatar != null
                        ? DecorationImage(image: avatar, fit: BoxFit.cover)
                        : null,
                  ),
                  child: avatar == null
                      ? const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'កសិករ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.white.withOpacity(0.7), size: 13),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            user?.address ?? 'ប្រទេសកម្ពុជា',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF5350),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress < 0.7) ...[
            const SizedBox(height: 28),
            Opacity(
              opacity: (1 - progress * 1.5).clamp(0.0, 1.0),
              child: const Text(
                'សហគមន៍កសិករខ្មែរ  តោះជួល!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeroHeaderDelegate oldDelegate) =>
      oldDelegate.user != user;
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _showResults = false;

  void _onChanged(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    final matched = ServiceTypes.all.where((s) {
      final label = (s['label'] as String).toLowerCase();
      final subtitle = (s['subtitle'] as String).toLowerCase();
      final id = (s['id'] as String).toLowerCase();
      return label.contains(query) ||
          subtitle.contains(query) ||
          id.contains(query);
    }).toList();
    setState(() {
      _results = matched;
      _showResults = true;
    });
  }

  void _navigateToService(String serviceId) {
    setState(() {
      _showResults = false;
      _ctrl.clear();
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceRequestMapScreen(serviceType: serviceId),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded,
                    color: Color(0xFFBDBDBD), size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: _onChanged,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF212121)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ស្វែងរកគ្រឿងចក្រ ឬ សេវាកម្ម...',
                      hintStyle: TextStyle(
                          color: Color(0xFFBDBDBD), fontSize: 13),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(7),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          if (_showResults && _results.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 44),
                itemBuilder: (_, i) {
                  final svc = _results[i];
                  final Color color = svc['color'] as Color;
                  final cfg = _serviceImgCfgs[svc['id'] as String];
                  return InkWell(
                    onTap: () =>
                        _navigateToService(svc['id'] as String),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  cfg?.bg ?? color.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: cfg != null
                                  ? Image.asset(cfg.imagePath,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain)
                                  : Icon(
                                      svc['icon'] as IconData,
                                      color: color,
                                      size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(svc['label'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: Color(
                                            0xFF212121))),
                                const SizedBox(height: 2),
                                Text(
                                    svc['subtitle'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(
                                            0xFF9E9E9E))),
                              ],
                            ),
                          ),
                          Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                              size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_showResults && _results.isEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      color: Color(0xFFBDBDBD), size: 20),
                  SizedBox(width: 8),
                  Text('រកមិនឃើញសេវាកម្ម',
                      style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onAction;

  const _SectionHeader(
      {required this.title, required this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121))),
          ),
          if (action.isNotEmpty && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(action,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 5-Service tiles grid ────────────────────────────────────────────────────

class _ServiceTilesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ServiceTypes.all.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, i) {
          final svc = ServiceTypes.all[i];
          final Color color = svc['color'] as Color;
          final cfg = _serviceImgCfgs[svc['id'] as String];
          return _ServiceTile(svc: svc, color: color, cfg: cfg);
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> svc;
  final Color color;
  final _ImgCfg? cfg;
  const _ServiceTile({required this.svc, required this.color, this.cfg});

  @override
  Widget build(BuildContext context) {
    final bg = cfg?.bg ?? color.withOpacity(0.12);
    final fg = cfg?.fg ?? color;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceRequestMapScreen(
            serviceType: svc['id'] as String,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: cfg != null
                  ? Image.asset(
                      cfg!.imagePath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(svc['icon'] as IconData, color: fg, size: 32),
                    )
                  : Icon(svc['icon'] as IconData, color: fg, size: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            svc['label'] as String,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121)),
          ),
        ],
      ),
    );
  }
}

// ─── Promo banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final PageController ctrl;
  final int page;
  final void Function(int) onPage;

  const _PromoBanner(
      {required this.ctrl, required this.page, required this.onPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: ctrl,
            itemCount: _promos.length,
            onPageChanged: onPage,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: i == _promos.length - 1 ? 16 : 8),
              child: _PromoBannerCard(item: _promos[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == page ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == page ? _kGreen : const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  final _PromoItem item;
  const _PromoBannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreenDark, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000),
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.tag,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 7),
                Text(item.title,
                    maxLines: 2,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35)),
                const SizedBox(height: 5),
                Text(item.subtitle,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.white70, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── My Requests Strip ────────────────────────────────────────────────────────

class _MyRequestsStrip extends StatelessWidget {
  final dynamic user;
  const _MyRequestsStrip({required this.user});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final myUid = user?.uid ?? '';
    final reqs = app.serviceRequestsForFarmer(myUid)
        .where((r) => r.status == 'pending' || r.status == 'accepted')
        .take(3)
        .toList();

    if (reqs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _SectionHeader(
          title: 'សំណើកំពុងដំណើរ',
          action: 'ទាំងអស់',
          onAction: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen())),
        ),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reqs.length,
            itemBuilder: (context, i) {
              final r = reqs[i];
              final info = ServiceTypes.infoOf(r.serviceType);
              final color = info['color'] as Color;
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(info['icon'] as IconData, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(info['label'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: r.statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(r.statusLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: r.statusColor)),
                      ),
                    ]),
                    Row(children: [
                      const Icon(Icons.location_on,
                          size: 11, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 3),
                      Flexible(
                          child: Text(r.currentAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF757575)))),
                    ]),
                    Text('${r.offerPrice.toStringAsFixed(0)} រៀល · ${r.landLabel}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Equipment row ────────────────────────────────────────────────────────────

class _EquipmentRow extends StatelessWidget {
  static const Map<String, _ImgCfg> _cfgs = {
    'tractor': _ImgCfg('assets/images/3.png', Color(0xFFE8F5E9), Color(0xFF43A047)),
    'harvester': _ImgCfg('assets/images/2.png', Color(0xFFFFF8E1), Color(0xFFF9A825)),
    'pump': _ImgCfg('assets/images/4.png', Color(0xFFE3F2FD), Color(0xFF1E88E5)),
    'koyon': _ImgCfg('assets/images/1.png', Color(0xFFFFF3E0), Color(0xFFFF9800)),
    'spray': _ImgCfg('assets/images/5.png', Color(0xFFFFEBEE), Color(0xFFEF5350)),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: _equipment.length,
        itemBuilder: (_, i) {
          final item = _equipment[i];
          final cfg = _cfgs[item.imageAsset] ??
              const _ImgCfg('assets/images/app_icon.png',
                  Color(0xFFF5F5F5), Color(0xFF9E9E9E));
          return Padding(
            padding: EdgeInsets.only(right: i < _equipment.length - 1 ? 12 : 0),
            child: _EquipmentCard(
              item: item,
              cfg: cfg,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EquipmentDetailScreen(item: item)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final _ImgCfg cfg;
  final VoidCallback onTap;
  const _EquipmentCard(
      {required this.item, required this.cfg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 10,
                offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 108,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Image.asset(cfg.imagePath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported,
                            color: cfg.fg,
                            size: 40)),
                  ),
                ),
                if (item.badge != EquipmentBadge.none)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.badge == EquipmentBadge.hot
                            ? const Color(0xFFEF5350)
                            : _kGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge == EquipmentBadge.hot ? 'HOT' : 'ថ្មី',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 11, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Expanded(
                          child: Text(item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9E9E9E)))),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.price,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _kGreen)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: Color(0xFFFFC107)),
                          const SizedBox(width: 2),
                          Text(item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Tab ─────────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  final String myUid;
  const _ChatTab({required this.myUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('ការសន្ទនា',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: _kCard,
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kDivider),
        ),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: context.read<ChatProvider>().getChatRooms(myUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kGreen));
          }

          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.forum_outlined,
                        size: 38, color: _kGreen.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 16),
                  const Text('មិនទាន់មានការសន្ទនា',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161))),
                  const SizedBox(height: 6),
                  const Text(
                    'ការសន្ទនានឹងបង្ហាញនៅទីនេះ\nបន្ទាប់ពីអ្នកផ្តល់សេវាទំនាក់ទំនង',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E), height: 1.5),
                  ),
                ],
              ),
            );
          }

          final chatProv = context.read<ChatProvider>();
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8),
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 74, color: _kDivider),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              final otherUid = room.otherUid(myUid);
              return FutureBuilder<String>(
                future: chatProv.getUserName(otherUid),
                builder: (_, nameSnap) {
                  final otherName = nameSnap.data ?? '...';
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUid)
                        .get(),
                    builder: (_, userSnap) {
                      final peerData =
                          userSnap.data?.data() as Map<String, dynamic>?;
                      final peerImgStr =
                          peerData?['profileImageUrl'] as String?;
                      ImageProvider? peerAvatar;
                      if (peerImgStr != null && peerImgStr.isNotEmpty) {
                        try {
                          peerAvatar = MemoryImage(base64Decode(peerImgStr));
                        } catch (_) {}
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: _kGreen.withOpacity(0.12),
                          backgroundImage: peerAvatar,
                          child: peerAvatar == null
                              ? Text(
                                  otherName.isNotEmpty
                                      ? otherName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen))
                              : null,
                        ),
                        title: Text(otherName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121))),
                        subtitle: Text(
                          room.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9E9E9E)),
                        ),
                        trailing: Text(
                          _fmtDate(room.lastMessageTime),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E)),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatRoomId: room.id,
                              peerId: otherUid,
                              peerName: otherName,
                              peerImageBase64: peerImgStr,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    ImageProvider? avatar;
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.profileImageUrl!));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kGreenDark, _kGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 20, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 2.5),
                      image: avatar != null
                          ? DecorationImage(
                              image: avatar, fit: BoxFit.cover)
                          : null,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: avatar == null
                        ? Center(
                            child: Text(
                              user?.fullName != null && user!.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '👨‍🌾',
                              style: const TextStyle(
                                  fontSize: 34, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🌾 កសិករ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info card
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x09000000),
                            blurRadius: 12,
                            offset: Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      children: [
                        _ProfileRow(
                          icon: Icons.email_outlined,
                          label: 'អ៊ីមែល',
                          value: user?.email ?? '',
                        ),
                        const Divider(height: 1, indent: 52, color: _kDivider),
                        _ProfileRow(
                          icon: Icons.phone_outlined,
                          label: 'ទូរស័ព្ទ',
                          value: user?.phoneNumber ?? '',
                        ),
                        if (user?.address != null &&
                            user!.address!.isNotEmpty) ...[
                          const Divider(
                              height: 1, indent: 52, color: _kDivider),
                          _ProfileRow(
                            icon: Icons.location_on_outlined,
                            label: 'អាសយដ្ឋាន',
                            value: user.address!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  _ProfileActionTile(
                    icon: Icons.edit_rounded,
                    label: 'កែប្រែព័ត៌មានគណនី',
                    color: _kGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ).then((_) => auth.refreshProfile()),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    icon: Icons.list_alt_rounded,
                    label: 'សំណើសេវារបស់ខ្ញុំ',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyServiceRequestsScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    icon: Icons.notifications_outlined,
                    label: 'ការជូនដំណឹង',
                    color: const Color(0xFFF9A825),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded,
                          color: Color(0xFFD32F2F), size: 18),
                      label: const Text('ចេញពីគណនី',
                          style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                        backgroundColor: const Color(0xFFFFF5F5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async => auth.logout(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _kGreen),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121)))),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper classes ───────────────────────────────────────────────────────────

class _PromoItem {
  final String tag;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _PromoItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });
}

class _ImgCfg {
  final String imagePath;
  final Color bg;
  final Color fg;
  const _ImgCfg(this.imagePath, this.bg, this.fg);
}